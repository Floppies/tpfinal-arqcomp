from __future__ import annotations

from pathlib import Path

import pytest

from cli.assembler import (
    HALT_WORD,
    assemble_file,
    assemble_text,
    expand_pseudos,
    parse_source,
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


def test_unsupported_instruction_raises_line_aware_error(tmp_path: Path) -> None:
    src = tmp_path / "prog.asm"
    src.write_text("add x1, x2, x3\n", encoding="utf-8")

    with pytest.raises(AssemblerError) as excinfo:
        assemble_file(src)

    text = str(excinfo.value)
    assert "line 1:" in text
    assert "unsupported instruction 'add'" in text

