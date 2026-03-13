from __future__ import annotations

from pathlib import Path

import pytest

from cli.assembler import (
    HALT_WORD,
    assemble_file,
    assemble_text,
    expand_pseudos,
    parse_source,
    words_to_bin_lines,
)
from cli.errors import AssemblerError


def test_parse_and_expand_pseudos() -> None:
    source = """
start:
  nop
  j start
  jr x1
"""
    parsed = parse_source(source)
    assert parsed.labels["start"] == 0

    expanded = expand_pseudos(parsed)
    assert [inst.mnemonic for inst in expanded.instructions] == [".word", "jal", "jalr"]
    assert expanded.instructions[1].operands == ("x0", "start")
    assert expanded.instructions[2].operands == ("x0", "x1", "0")


def test_halt_is_appended_and_warned(capsys: pytest.CaptureFixture[str]) -> None:
    words = assemble_text(".word 0x1\n", append_halt_if_missing=True)
    assert words == [0x1, HALT_WORD]
    out = capsys.readouterr().out
    assert "HALT appended automatically" in out


def test_halt_not_appended_if_present(capsys: pytest.CaptureFixture[str]) -> None:
    words = assemble_text(".word 0xFFFFFFFF\n", append_halt_if_missing=True)
    assert words == [HALT_WORD]
    out = capsys.readouterr().out
    assert out == ""


def test_example_program_matches_expected_binary_lines() -> None:
    source = """addi x1, x0, 5
addi x2, x0, 7
add x3, x1, x2
sw x3, 0(x0)
halt
"""
    words = assemble_text(source)
    lines = words_to_bin_lines(words)

    assert lines == [
        "00000000010100000000000010010011",
        "00000000011100000000000100010011",
        "00000000001000001000000110110011",
        "00000000001100000010000000100011",
        "11111111111111111111111111111111",
    ]


def test_instruction_aliases_and_branches_encode() -> None:
    source = """start:
addiu x1, x0, 1
sllv x2, x1, x1
srlv x3, x2, x1
srav x4, x3, x1
beq x1, x1, start
lwu x5, 0(x0)
nor x6, x1, x2
jr x1
"""
    words = assemble_text(source)
    assert len(words) == 10  # includes 2-word NOR expansion + HALT append
    assert words[-1] == HALT_WORD


def test_unsupported_instruction_raises_line_aware_error(tmp_path: Path) -> None:
    src = tmp_path / "prog.asm"
    src.write_text("foobar x1, x2, x3\n", encoding="utf-8")

    with pytest.raises(AssemblerError) as excinfo:
        assemble_file(src)

    text = str(excinfo.value)
    assert "line 1:" in text
    assert "unsupported instruction 'foobar'" in text
