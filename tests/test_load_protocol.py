from __future__ import annotations

import pytest

from cli.constants import ACK_CMD_LOAD, ACK_LOAD_DONE, CMD_LOAD, ERR_LOAD_LEN
from cli.errors import FpgaError, ProtocolError
from cli.protocol import DebugProtocol
from tests.helpers import FakeLink


def test_load_sends_word_count_le_and_payload_le() -> None:
    link = FakeLink([ACK_CMD_LOAD, ACK_LOAD_DONE])
    proto = DebugProtocol(link, timeout_s=0.5, dmem_words=0)

    words = [0x12345678, 0xAABBCCDD]
    proto.load_program(words)

    sent = b"".join(link.writes)
    assert sent == bytes(
        (
            CMD_LOAD,
            0x02,
            0x00,
            0x78,
            0x56,
            0x34,
            0x12,
            0xDD,
            0xCC,
            0xBB,
            0xAA,
        )
    )
    assert link.reset_input_calls == 1


def test_load_len_error_is_mapped() -> None:
    link = FakeLink([ACK_CMD_LOAD, ERR_LOAD_LEN])
    proto = DebugProtocol(link, timeout_s=0.5, dmem_words=0)

    with pytest.raises(FpgaError) as excinfo:
        proto.load_program([0xFFFFFFFF])

    assert str(excinfo.value) == "FPGA error: error with loaded program length"


def test_load_rejects_too_many_words() -> None:
    link = FakeLink([])
    proto = DebugProtocol(link, timeout_s=0.5, dmem_words=0)

    with pytest.raises(ProtocolError):
        proto.load_program([0] * 65536)
