"""Snapshot decoding and formatting."""

from __future__ import annotations

import struct
from dataclasses import dataclass

from .constants import PIPE_WORDS, REG_WORDS
from .errors import ProtocolError


@dataclass(frozen=True)
class StageLatches:
    if_next_pc: int
    if_pc: int
    id_inst: int
    id_next_pc: int
    id_pc: int
    id_imm: int
    id_rs1: int
    id_rs2: int
    id_rd: int
    ex_result: int
    ex_rs2: int
    ex_rd: int
    mem_result: int
    mem_data: int
    mem_rd: int
    wb_data: int
    wb_rd: int


@dataclass(frozen=True)
class Snapshot:
    pipe: StageLatches
    regs: list[int]
    dmem: list[int]


def expected_payload_len(dmem_words: int) -> int:
    return (PIPE_WORDS + REG_WORDS + dmem_words) * 4


def decode_snapshot(payload: bytes, dmem_words: int) -> Snapshot:
    exp = expected_payload_len(dmem_words)
    if len(payload) != exp:
        raise ProtocolError(
            f"invalid snapshot payload length: got {len(payload)} bytes, expected {exp}"
        )

    total_words = PIPE_WORDS + REG_WORDS + dmem_words
    words = list(struct.unpack(f"<{total_words}I", payload))
    pipe_words = words[0:PIPE_WORDS]
    regs = words[PIPE_WORDS : PIPE_WORDS + REG_WORDS]
    dmem = words[PIPE_WORDS + REG_WORDS :]
    #TODO less hardcode
    pipe = StageLatches(
        if_next_pc=pipe_words[0],
        if_pc=pipe_words[1],
        id_inst=pipe_words[2],
        id_next_pc=pipe_words[3],
        id_pc=pipe_words[4],
        id_imm=pipe_words[5],
        id_rs1=pipe_words[6],
        id_rs2=pipe_words[7],
        id_rd=pipe_words[8],
        ex_result=pipe_words[9],
        ex_rs2=pipe_words[10],
        ex_rd=pipe_words[11],
        mem_result=pipe_words[12],
        mem_data=pipe_words[13],
        mem_rd=pipe_words[14],
        wb_data=pipe_words[15],
        wb_rd=pipe_words[16],
    )

    return Snapshot(pipe=pipe, regs=regs, dmem=dmem)


def _hx(value: int) -> str:
    return f"0x{value & 0xFFFFFFFF:08X}"


def format_snapshot(snapshot: Snapshot) -> str:
    pipe = snapshot.pipe
    lines: list[str] = []
    lines.append("SNAPSHOT")
    lines.append("----------------------------")
    lines.append("Stage latches:")
    lines.append(f"IF_next_pc = {_hx(pipe.if_next_pc)}")
    lines.append(f"IF_pc = {_hx(pipe.if_pc)}")
    lines.append(f"ID_inst = {_hx(pipe.id_inst)}")
    lines.append(f"ID_next_pc = {_hx(pipe.id_next_pc)}")
    lines.append(f"ID_pc = {_hx(pipe.id_pc)}")
    lines.append(f"ID_imm = {_hx(pipe.id_imm)}")
    lines.append(f"ID_Rs1 = {_hx(pipe.id_rs1)}")
    lines.append(f"ID_Rs2 = {_hx(pipe.id_rs2)}")
    lines.append(f"ID_rd = {_hx(pipe.id_rd)}")
    lines.append(f"EX_result = {_hx(pipe.ex_result)}")
    lines.append(f"EX_Rs2 = {_hx(pipe.ex_rs2)}")
    lines.append(f"EX_rd = {_hx(pipe.ex_rd)}")
    lines.append(f"MEM_result = {_hx(pipe.mem_result)}")
    lines.append(f"MEM_data = {_hx(pipe.mem_data)}")
    lines.append(f"MEM_rd = {_hx(pipe.mem_rd)}")
    lines.append(f"WB_data = {_hx(pipe.wb_data)}")
    lines.append(f"WB_rd = {_hx(pipe.wb_rd)}")

    lines.append("")
    lines.append("----------------------------")
    lines.append("Current reg bank:")
    for i, reg in enumerate(snapshot.regs):
        lines.append(f"x{i:02d} = {_hx(reg)}")

    if snapshot.dmem:
        lines.append("")
        lines.append("----------------------------")
        lines.append("Snap words from memory:")
        for i, word in enumerate(snapshot.dmem):
            lines.append(f"mem[{i:02d}] @ 0x{i * 4:08X} = {_hx(word)}")

    return "\n".join(lines)

