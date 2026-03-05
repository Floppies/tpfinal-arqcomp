from __future__ import annotations

import struct

import pytest

from cli.constants import (
    ACK_CMD_DUMP,
    ACK_CMD_STEP,
    ACK_RUN_DONE,
    ACK_RUN_START,
    ACK_SNAP_DONE,
    ACK_SNAP_START,
    ACK_STEP_DONE,
    CMD_DUMP,
    CMD_RUN,
    CMD_STEP,
    ERR_CMD_UNKNOWN,
    SNAP_HEADER,
)
from cli.errors import FpgaError, TimeoutErrorPhase
from cli.protocol import DebugProtocol
from tests.helpers import FakeLink


def _payload_bytes(dmem_words: int) -> bytes:
    total = 17 + 32 + dmem_words
    words = list(range(total))
    return struct.pack(f"<{total}I", *words)


def test_step_happy_path_with_stale_bytes() -> None:
    payload = _payload_bytes(0)
    rx = [
        0x55,  # INFO stale
        0x34,  # unrelated ACK-like byte
        ACK_CMD_STEP,
        ACK_STEP_DONE,
        ACK_SNAP_START,
        *SNAP_HEADER,
        *payload,
        ACK_SNAP_DONE,
    ]
    link = FakeLink(rx)
    proto = DebugProtocol(link, timeout_s=0.5, dmem_words=0)

    snap = proto.step()

    assert link.writes[0] == bytes((CMD_STEP,))
    assert snap.regs[0] == 17
    assert snap.regs[-1] == 48


def test_run_happy_path() -> None:
    payload = _payload_bytes(0)
    rx = [
        ACK_RUN_START,
        ACK_RUN_DONE,
        ACK_SNAP_START,
        *SNAP_HEADER,
        *payload,
        ACK_SNAP_DONE,
    ]
    link = FakeLink(rx)
    proto = DebugProtocol(link, timeout_s=0.5, dmem_words=0)
    snap = proto.run()

    assert link.writes[0] == bytes((CMD_RUN,))
    assert snap.pipe.if_next_pc == 0


def test_dump_happy_path() -> None:
    payload = _payload_bytes(0)
    rx = [ACK_CMD_DUMP, ACK_SNAP_START, *SNAP_HEADER, *payload, ACK_SNAP_DONE]
    link = FakeLink(rx)
    proto = DebugProtocol(link, timeout_s=0.5, dmem_words=0)
    snap = proto.dump()

    assert link.writes[0] == bytes((CMD_DUMP,))
    assert len(snap.regs) == 32


def test_error_byte_aborts_command() -> None:
    rx = [ERR_CMD_UNKNOWN]
    link = FakeLink(rx)
    proto = DebugProtocol(link, timeout_s=0.5, dmem_words=0)

    with pytest.raises(FpgaError) as excinfo:
        proto.step()

    assert "FPGA error" in str(excinfo.value)


def test_timeout_phase_is_specific() -> None:
    rx = [ACK_CMD_STEP]  # Missing ACK_STEP_DONE
    link = FakeLink(rx)
    proto = DebugProtocol(link, timeout_s=0.5, dmem_words=0)

    with pytest.raises(TimeoutErrorPhase) as excinfo:
        proto.step()

    assert str(excinfo.value) == "timeout waiting for ACK_STEP_DONE"
