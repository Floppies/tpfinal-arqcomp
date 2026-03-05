"""Assembler skeleton for RTL-aligned CLI."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

from .errors import AssemblerError

HALT_WORD = 0xFFFFFFFF
NOP_WORD = 0x00000000


@dataclass(frozen=True)
class Instruction:
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
    if not raw:
        raise AssemblerError(line_no, line_text, "empty instruction")
    if " " in raw:
        mnemonic, operand_blob = raw.split(None, 1)
        operands = tuple(x.strip() for x in operand_blob.split(",") if x.strip())
    else:
        mnemonic = raw
        operands = ()
    return Instruction(
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

        inst = _parse_instruction(clean, line_no, src_line)
        instructions.append(inst)

    return ParsedProgram(labels=labels, instructions=instructions)


def expand_pseudos(program: ParsedProgram) -> ParsedProgram:
    expanded: list[Instruction] = []
    for inst in program.instructions:
        mnem = inst.mnemonic
        ops = inst.operands

        if mnem == "nop":
            expanded.append(
                Instruction(
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
                    mnemonic="jalr",
                    operands=("x0", ops[0], "0"),
                    line_no=inst.line_no,
                    line_text=inst.line_text,
                )
            )
            continue

        expanded.append(inst)

    return ParsedProgram(labels=program.labels, instructions=expanded)


def _parse_int(token: str, line_no: int, line_text: str) -> int:
    try:
        return int(token, 0)
    except ValueError as exc:
        raise AssemblerError(line_no, line_text, f"invalid integer literal '{token}'") from exc


def encode_instruction(inst: Instruction, labels: dict[str, int]) -> int:
    del labels  # Kept for future encoder implementation.

    if inst.mnemonic == ".word":
        if len(inst.operands) != 1:
            raise AssemblerError(inst.line_no, inst.line_text, ".word expects exactly one operand")
        return _parse_int(inst.operands[0], inst.line_no, inst.line_text) & 0xFFFFFFFF

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
    words = [encode_instruction(inst, expanded.labels) for inst in expanded.instructions]
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

