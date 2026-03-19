"""Assembler for RTL-aligned CLI (RV32I subset + project pseudos)."""

from __future__ import annotations

from dataclasses import dataclass
import re
from pathlib import Path
from typing import Iterable

from .errors import AssemblerError

HALT_WORD = 0xFFFFFFFF
NOP_WORD = 0x00000000

OP_RTYPE = 0x33
OP_ITYPE = 0x13
OP_LOAD = 0x03
OP_STORE = 0x23
OP_BRANCH = 0x63
OP_JAL = 0x6F
OP_JALR = 0x67
OP_LUI = 0x37

REGISTER_ALIASES = {
    "zero": 0,
    "ra": 1,
    "sp": 2,
    "gp": 3,
    "tp": 4,
    "t0": 5,
    "t1": 6,
    "t2": 7,
    "s0": 8,
    "fp": 8,
    "s1": 9,
    "a0": 10,
    "a1": 11,
    "a2": 12,
    "a3": 13,
    "a4": 14,
    "a5": 15,
    "a6": 16,
    "a7": 17,
    "s2": 18,
    "s3": 19,
    "s4": 20,
    "s5": 21,
    "s6": 22,
    "s7": 23,
    "s8": 24,
    "s9": 25,
    "s10": 26,
    "s11": 27,
    "t3": 28,
    "t4": 29,
    "t5": 30,
    "t6": 31,
}


@dataclass(frozen=True)
class Instruction:
    source_index: int
    mnemonic: str
    operands: tuple[str, ...]
    line_no: int
    line_text: str


@dataclass(frozen=True)
class ParsedProgram:
    labels: dict[str, int]
    instructions: list[Instruction]


def _strip_comment(line: str) -> str:
    for token in ("#", "//", ";"):
        idx = line.find(token)
        if idx >= 0:
            line = line[:idx]
    return line.strip()


def _parse_instruction(raw: str, line_no: int, line_text: str) -> Instruction:
    return _make_instruction(-1, raw, line_no, line_text)


def _make_instruction(source_index: int, raw: str, line_no: int, line_text: str) -> Instruction:
    if not raw:
        raise AssemblerError(line_no, line_text, "empty instruction")
    if " " in raw:
        mnemonic, operand_blob = raw.split(None, 1)
        operands = tuple(x.strip() for x in operand_blob.split(",") if x.strip())
    else:
        mnemonic = raw
        operands = ()
    return Instruction(
        source_index=source_index,
        mnemonic=mnemonic.lower(),
        operands=operands,
        line_no=line_no,
        line_text=line_text.rstrip("\n"),
    )


def parse_source(text: str) -> ParsedProgram:
    labels: dict[str, int] = {}
    instructions: list[Instruction] = []

    for line_no, src_line in enumerate(text.splitlines(), start=1):
        clean = _strip_comment(src_line)
        if not clean:
            continue

        while ":" in clean:
            left, right = clean.split(":", 1)
            label = left.strip()
            if not label:
                raise AssemblerError(line_no, src_line, "invalid empty label")
            if label in labels:
                raise AssemblerError(line_no, src_line, f"duplicate label '{label}'")
            labels[label] = len(instructions)
            clean = right.strip()
            if not clean:
                break

        if not clean:
            continue

        inst = _make_instruction(len(instructions), clean, line_no, src_line)
        instructions.append(inst)

    return ParsedProgram(labels=labels, instructions=instructions)


def expand_pseudos(program: ParsedProgram) -> ParsedProgram:
    labels_by_source_idx: dict[int, list[str]] = {}
    for name, idx in program.labels.items():
        labels_by_source_idx.setdefault(idx, []).append(name)

    expanded_labels: dict[str, int] = {}
    expanded: list[Instruction] = []
    for inst in program.instructions:
        for lbl in labels_by_source_idx.get(inst.source_index, []):
            expanded_labels[lbl] = len(expanded)

        mnem = inst.mnemonic
        ops = inst.operands

        if mnem == "nop":
            expanded.append(
                Instruction(
                    source_index=inst.source_index,
                    mnemonic=".word",
                    operands=(f"0x{NOP_WORD:08X}",),
                    line_no=inst.line_no,
                    line_text=inst.line_text,
                )
            )
            continue

        if mnem == "halt":
            expanded.append(
                Instruction(
                    source_index=inst.source_index,
                    mnemonic=".word",
                    operands=(f"0x{HALT_WORD:08X}",),
                    line_no=inst.line_no,
                    line_text=inst.line_text,
                )
            )
            continue

        if mnem == "j":
            if len(ops) != 1:
                raise AssemblerError(inst.line_no, inst.line_text, "j expects exactly one label")
            expanded.append(
                Instruction(
                    source_index=inst.source_index,
                    mnemonic="jal",
                    operands=("x0", ops[0]),
                    line_no=inst.line_no,
                    line_text=inst.line_text,
                )
            )
            continue

        if mnem == "jr":
            if len(ops) != 1:
                raise AssemblerError(inst.line_no, inst.line_text, "jr expects exactly one register")
            expanded.append(
                Instruction(
                    source_index=inst.source_index,
                    mnemonic="jalr",
                    operands=("x0", ops[0], "0"),
                    line_no=inst.line_no,
                    line_text=inst.line_text,
                )
            )
            continue

        if mnem == "nor":
            if len(ops) != 3:
                raise AssemblerError(inst.line_no, inst.line_text, "nor expects rd, rs1, rs2")
            expanded.append(
                Instruction(
                    source_index=inst.source_index,
                    mnemonic="or",
                    operands=ops,
                    line_no=inst.line_no,
                    line_text=inst.line_text,
                )
            )
            expanded.append(
                Instruction(
                    source_index=inst.source_index,
                    mnemonic="xori",
                    operands=(ops[0], ops[0], "-1"),
                    line_no=inst.line_no,
                    line_text=inst.line_text,
                )
            )
            continue

        if mnem == "sllv":
            expanded.append(
                Instruction(
                    source_index=inst.source_index,
                    mnemonic="sll",
                    operands=ops,
                    line_no=inst.line_no,
                    line_text=inst.line_text,
                )
            )
            continue

        if mnem == "srlv":
            expanded.append(
                Instruction(
                    source_index=inst.source_index,
                    mnemonic="srl",
                    operands=ops,
                    line_no=inst.line_no,
                    line_text=inst.line_text,
                )
            )
            continue

        if mnem == "srav":
            expanded.append(
                Instruction(
                    source_index=inst.source_index,
                    mnemonic="sra",
                    operands=ops,
                    line_no=inst.line_no,
                    line_text=inst.line_text,
                )
            )
            continue

        if mnem == "addiu":
            expanded.append(
                Instruction(
                    source_index=inst.source_index,
                    mnemonic="addi",
                    operands=ops,
                    line_no=inst.line_no,
                    line_text=inst.line_text,
                )
            )
            continue

        if mnem == "lwu":
            expanded.append(
                Instruction(
                    source_index=inst.source_index,
                    mnemonic="lw",
                    operands=ops,
                    line_no=inst.line_no,
                    line_text=inst.line_text,
                )
            )
            continue

        expanded.append(inst)

    for lbl in labels_by_source_idx.get(len(program.instructions), []):
        expanded_labels[lbl] = len(expanded)

    return ParsedProgram(labels=expanded_labels, instructions=expanded)


def _parse_int(token: str, line_no: int, line_text: str) -> int:
    try:
        return int(token, 0)
    except ValueError as exc:
        raise AssemblerError(line_no, line_text, f"invalid integer literal '{token}'") from exc


def _parse_reg(token: str, line_no: int, line_text: str) -> int:
    text = token.strip().lower()
    if text in REGISTER_ALIASES:
        return REGISTER_ALIASES[text]
    if re.fullmatch(r"x([0-9]|[12][0-9]|3[01])", text):
        return int(text[1:])
    raise AssemblerError(line_no, line_text, f"invalid register '{token}'")


def _expect_operand_count(inst: Instruction, count: int) -> None:
    if len(inst.operands) != count:
        raise AssemblerError(
            inst.line_no,
            inst.line_text,
            f"{inst.mnemonic} expects {count} operands, got {len(inst.operands)}",
        )


def _check_signed(value: int, bits: int, inst: Instruction, what: str) -> None:
    lo = -(1 << (bits - 1))
    hi = (1 << (bits - 1)) - 1
    if value < lo or value > hi:
        raise AssemblerError(inst.line_no, inst.line_text, f"{what} out of range for {bits}-bit signed")


def _check_unsigned(value: int, bits: int, inst: Instruction, what: str) -> None:
    lo = 0
    hi = (1 << bits) - 1
    if value < lo or value > hi:
        raise AssemblerError(inst.line_no, inst.line_text, f"{what} out of range for {bits}-bit unsigned")


def _parse_mem_operand(token: str, inst: Instruction) -> tuple[int, int]:
    # form: imm(rs1)
    m = re.fullmatch(r"\s*([^\(\)]+)\(([^)]+)\)\s*", token)
    if not m:
        raise AssemblerError(inst.line_no, inst.line_text, f"invalid memory operand '{token}'")
    imm = _parse_int(m.group(1).strip(), inst.line_no, inst.line_text)
    rs1 = _parse_reg(m.group(2).strip(), inst.line_no, inst.line_text)
    return imm, rs1


def _resolve_label_or_imm(token: str, labels: dict[str, int], pc_index: int, inst: Instruction) -> int:
    if token in labels:
        # Labels are assembled as standard byte offsets between 32-bit instructions.
        # The RTL converts branch/jump offsets to its internal word-addressed PC domain.
        return (labels[token] - pc_index) * 4
    return _parse_int(token, inst.line_no, inst.line_text)


def _encode_r(rd: int, rs1: int, rs2: int, funct3: int, funct7: int) -> int:
    return (
        ((funct7 & 0x7F) << 25)
        | ((rs2 & 0x1F) << 20)
        | ((rs1 & 0x1F) << 15)
        | ((funct3 & 0x7) << 12)
        | ((rd & 0x1F) << 7)
        | OP_RTYPE
    )


def _encode_i(rd: int, rs1: int, imm: int, funct3: int, opcode: int) -> int:
    return (
        ((imm & 0xFFF) << 20)
        | ((rs1 & 0x1F) << 15)
        | ((funct3 & 0x7) << 12)
        | ((rd & 0x1F) << 7)
        | (opcode & 0x7F)
    )


def _encode_s(rs1: int, rs2: int, imm: int, funct3: int) -> int:
    imm12 = imm & 0xFFF
    return (
        (((imm12 >> 5) & 0x7F) << 25)
        | ((rs2 & 0x1F) << 20)
        | ((rs1 & 0x1F) << 15)
        | ((funct3 & 0x7) << 12)
        | ((imm12 & 0x1F) << 7)
        | OP_STORE
    )


def _encode_b(rs1: int, rs2: int, imm: int, funct3: int) -> int:
    imm13 = imm & 0x1FFF
    bit12 = (imm13 >> 12) & 0x1
    bits10_5 = (imm13 >> 5) & 0x3F
    bits4_1 = (imm13 >> 1) & 0xF
    bit11 = (imm13 >> 11) & 0x1
    return (
        (bit12 << 31)
        | (bits10_5 << 25)
        | ((rs2 & 0x1F) << 20)
        | ((rs1 & 0x1F) << 15)
        | ((funct3 & 0x7) << 12)
        | (bits4_1 << 8)
        | (bit11 << 7)
        | OP_BRANCH
    )


def _encode_u(rd: int, imm20: int) -> int:
    return ((imm20 & 0xFFFFF) << 12) | ((rd & 0x1F) << 7) | OP_LUI


def _encode_j(rd: int, imm: int) -> int:
    imm21 = imm & 0x1FFFFF
    bit20 = (imm21 >> 20) & 0x1
    bits10_1 = (imm21 >> 1) & 0x3FF
    bit11 = (imm21 >> 11) & 0x1
    bits19_12 = (imm21 >> 12) & 0xFF
    return (
        (bit20 << 31)
        | (bits10_1 << 21)
        | (bit11 << 20)
        | (bits19_12 << 12)
        | ((rd & 0x1F) << 7)
        | OP_JAL
    )


def _encode_rtype(inst: Instruction, funct3: int, funct7: int) -> int:
    _expect_operand_count(inst, 3)
    rd = _parse_reg(inst.operands[0], inst.line_no, inst.line_text)
    rs1 = _parse_reg(inst.operands[1], inst.line_no, inst.line_text)
    rs2 = _parse_reg(inst.operands[2], inst.line_no, inst.line_text)
    return _encode_r(rd, rs1, rs2, funct3, funct7)


def _encode_load(inst: Instruction, funct3: int) -> int:
    _expect_operand_count(inst, 2)
    rd = _parse_reg(inst.operands[0], inst.line_no, inst.line_text)
    imm, rs1 = _parse_mem_operand(inst.operands[1], inst)
    _check_signed(imm, 12, inst, "load offset")
    return _encode_i(rd, rs1, imm, funct3, OP_LOAD)


def _encode_store(inst: Instruction, funct3: int) -> int:
    _expect_operand_count(inst, 2)
    rs2 = _parse_reg(inst.operands[0], inst.line_no, inst.line_text)
    imm, rs1 = _parse_mem_operand(inst.operands[1], inst)
    _check_signed(imm, 12, inst, "store offset")
    return _encode_s(rs1, rs2, imm, funct3)


def _encode_itype(inst: Instruction, funct3: int) -> int:
    _expect_operand_count(inst, 3)
    rd = _parse_reg(inst.operands[0], inst.line_no, inst.line_text)
    rs1 = _parse_reg(inst.operands[1], inst.line_no, inst.line_text)
    imm = _parse_int(inst.operands[2], inst.line_no, inst.line_text)
    _check_signed(imm, 12, inst, "immediate")
    return _encode_i(rd, rs1, imm, funct3, OP_ITYPE)


def _encode_shift_imm(inst: Instruction, funct3: int, funct7: int) -> int:
    _expect_operand_count(inst, 3)
    rd = _parse_reg(inst.operands[0], inst.line_no, inst.line_text)
    rs1 = _parse_reg(inst.operands[1], inst.line_no, inst.line_text)
    shamt = _parse_int(inst.operands[2], inst.line_no, inst.line_text)
    _check_unsigned(shamt, 5, inst, "shift amount")
    imm12 = ((funct7 & 0x7F) << 5) | (shamt & 0x1F)
    return _encode_i(rd, rs1, imm12, funct3, OP_ITYPE)


def encode_instruction(inst: Instruction, labels: dict[str, int]) -> int:
    if inst.mnemonic == ".word":
        if len(inst.operands) != 1:
            raise AssemblerError(inst.line_no, inst.line_text, ".word expects exactly one operand")
        return _parse_int(inst.operands[0], inst.line_no, inst.line_text) & 0xFFFFFFFF

    r_map = {
        "add": (0b000, 0b0000000),
        "sub": (0b000, 0b0100000),
        "and": (0b111, 0b0000000),
        "or": (0b110, 0b0000000),
        "xor": (0b100, 0b0000000),
        "sll": (0b001, 0b0000000),
        "srl": (0b101, 0b0000000),
        "sra": (0b101, 0b0100000),
        "slt": (0b010, 0b0000000),
        "sltu": (0b011, 0b0000000),
    }
    if inst.mnemonic in r_map:
        funct3, funct7 = r_map[inst.mnemonic]
        return _encode_rtype(inst, funct3, funct7)

    i_map = {
        "addi": 0b000,
        "andi": 0b111,
        "ori": 0b110,
        "xori": 0b100,
        "slti": 0b010,
        "sltiu": 0b011,
    }
    if inst.mnemonic in i_map:
        return _encode_itype(inst, i_map[inst.mnemonic])

    if inst.mnemonic == "slli":
        return _encode_shift_imm(inst, funct3=0b001, funct7=0b0000000)
    if inst.mnemonic == "srli":
        return _encode_shift_imm(inst, funct3=0b101, funct7=0b0000000)
    if inst.mnemonic == "srai":
        return _encode_shift_imm(inst, funct3=0b101, funct7=0b0100000)

    load_map = {
        "lb": 0b000,
        "lh": 0b001,
        "lw": 0b010,
        "lbu": 0b100,
        "lhu": 0b101,
    }
    if inst.mnemonic in load_map:
        return _encode_load(inst, load_map[inst.mnemonic])

    store_map = {
        "sb": 0b000,
        "sh": 0b001,
        "sw": 0b010,
    }
    if inst.mnemonic in store_map:
        return _encode_store(inst, store_map[inst.mnemonic])

    if inst.mnemonic in {"beq", "bne"}:
        _expect_operand_count(inst, 3)
        rs1 = _parse_reg(inst.operands[0], inst.line_no, inst.line_text)
        rs2 = _parse_reg(inst.operands[1], inst.line_no, inst.line_text)
        imm = _resolve_label_or_imm(inst.operands[2], labels, inst.source_index, inst)
        if imm % 2 != 0:
            raise AssemblerError(inst.line_no, inst.line_text, "branch offset must be 2-byte aligned")
        _check_signed(imm, 13, inst, "branch offset")
        funct3 = 0b000 if inst.mnemonic == "beq" else 0b001
        return _encode_b(rs1, rs2, imm, funct3)

    if inst.mnemonic == "jal":
        if len(inst.operands) == 1:
            rd = 1
            target = inst.operands[0]
        elif len(inst.operands) == 2:
            rd = _parse_reg(inst.operands[0], inst.line_no, inst.line_text)
            target = inst.operands[1]
        else:
            raise AssemblerError(inst.line_no, inst.line_text, "jal expects 'label' or 'rd, label'")
        imm = _resolve_label_or_imm(target, labels, inst.source_index, inst)
        if imm % 2 != 0:
            raise AssemblerError(inst.line_no, inst.line_text, "jal offset must be 2-byte aligned")
        _check_signed(imm, 21, inst, "jal offset")
        return _encode_j(rd, imm)

    if inst.mnemonic == "jalr":
        if len(inst.operands) == 1:
            rd = 1
            rs1 = _parse_reg(inst.operands[0], inst.line_no, inst.line_text)
            imm = 0
        elif len(inst.operands) == 2 and "(" in inst.operands[1]:
            rd = _parse_reg(inst.operands[0], inst.line_no, inst.line_text)
            imm, rs1 = _parse_mem_operand(inst.operands[1], inst)
        elif len(inst.operands) == 3:
            rd = _parse_reg(inst.operands[0], inst.line_no, inst.line_text)
            rs1 = _parse_reg(inst.operands[1], inst.line_no, inst.line_text)
            imm = _parse_int(inst.operands[2], inst.line_no, inst.line_text)
        else:
            raise AssemblerError(
                inst.line_no,
                inst.line_text,
                "jalr expects 'rs1', 'rd, imm(rs1)', or 'rd, rs1, imm'",
            )
        _check_signed(imm, 12, inst, "jalr immediate")
        return _encode_i(rd, rs1, imm, 0b000, OP_JALR)

    if inst.mnemonic == "lui":
        _expect_operand_count(inst, 2)
        rd = _parse_reg(inst.operands[0], inst.line_no, inst.line_text)
        imm_raw = _parse_int(inst.operands[1], inst.line_no, inst.line_text)
        if -(1 << 19) <= imm_raw <= (1 << 19) - 1:
            imm20 = imm_raw & 0xFFFFF
        elif (imm_raw & 0xFFF) == 0:
            imm20 = (imm_raw >> 12) & 0xFFFFF
        else:
            raise AssemblerError(inst.line_no, inst.line_text, "lui immediate must fit 20 bits or be <<12")
        return _encode_u(rd, imm20)

    raise AssemblerError(
        inst.line_no,
        inst.line_text,
        f"unsupported instruction '{inst.mnemonic}' in skeleton encoder",
    )


def enforce_final_halt(words: list[int], append_halt_if_missing: bool = True) -> list[int]:
    out = list(words)
    if not out:
        return out
    if append_halt_if_missing and out[-1] != HALT_WORD:
        out.append(HALT_WORD)
        print("HALT appended automatically")
    return out


def assemble_text(text: str, *, append_halt_if_missing: bool = True) -> list[int]:
    parsed = parse_source(text)
    expanded = expand_pseudos(parsed)
    words: list[int] = []
    for idx, inst in enumerate(expanded.instructions):
        inst_with_pc = Instruction(
            source_index=idx,
            mnemonic=inst.mnemonic,
            operands=inst.operands,
            line_no=inst.line_no,
            line_text=inst.line_text,
        )
        words.append(encode_instruction(inst_with_pc, expanded.labels))
    return enforce_final_halt(words, append_halt_if_missing=append_halt_if_missing)


def assemble_file(path: Path, *, append_halt_if_missing: bool = True) -> list[int]:
    ext = path.suffix.lower()
    if ext not in {".asm", ".s", ".txt"}:
        raise AssemblerError(0, str(path), "unsupported file extension")
    text = path.read_text(encoding="utf-8")
    return assemble_text(text, append_halt_if_missing=append_halt_if_missing)


def write_coe(words: Iterable[int], out_path: Path) -> None:
    items = [f"{w & 0xFFFFFFFF:08X}" for w in words]
    lines = [
        "memory_initialization_radix=16;",
        "memory_initialization_vector=",
    ]
    if items:
        for idx, item in enumerate(items):
            suffix = "," if idx < len(items) - 1 else ";"
            lines.append(f"{item}{suffix}")
    else:
        lines.append(";")
    out_path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def words_to_bin_lines(words: Iterable[int]) -> list[str]:
    return [f"{word & 0xFFFFFFFF:032b}" for word in words]


def write_bin_txt(words: Iterable[int], out_path: Path) -> None:
    out_path.write_text("\n".join(words_to_bin_lines(words)) + "\n", encoding="utf-8")
