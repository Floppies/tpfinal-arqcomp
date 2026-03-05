from __future__ import annotations

import struct

import pytest

from cli.errors import ProtocolError
from cli.snapshot import decode_snapshot, format_snapshot


def test_decode_snapshot_with_dmem_and_format() -> None:
    dmem_words = 2
    total = 17 + 32 + dmem_words
    words = list(range(total))
    payload = struct.pack(f"<{total}I", *words)

    snap = decode_snapshot(payload, dmem_words=dmem_words)
    text = format_snapshot(snap)

    assert snap.pipe.if_next_pc == 0
    assert snap.pipe.wb_rd == 16
    assert snap.regs[0] == 17
    assert snap.regs[-1] == 48
    assert snap.dmem == [49, 50]
    assert "Stage latches:" in text
    assert "Current reg bank:" in text
    assert "x00 = 0x00000011" in text
    assert "Snap words from memory:" in text
    assert "mem[00] @ 0x00000000 = 0x00000031" in text


def test_decode_snapshot_rejects_wrong_size() -> None:
    with pytest.raises(ProtocolError):
        decode_snapshot(b"\x00" * 10, dmem_words=0)

