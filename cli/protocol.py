"""RTL-aligned protocol FSM for FPGA debug UART."""

from __future__ import annotations

import struct
import time

from .constants import (
    ACK_CMD_DUMP,
    ACK_CMD_LOAD,
    ACK_CMD_STEP,
    ACK_LOAD_DONE,
    ACK_RUN_DONE,
    ACK_RUN_START,
    ACK_SNAP_DONE,
    ACK_SNAP_START,
    ACK_STEP_DONE,
    CMD_DUMP,
    CMD_LOAD,
    CMD_RUN,
    CMD_STEP,
    ERR_CMD_UNKNOWN,
    ERR_LOAD_LEN,
    SNAP_HEADER,
)
from .errors import FpgaError, ProtocolError, TimeoutErrorPhase
from .snapshot import Snapshot, decode_snapshot, expected_payload_len


def map_fpga_error(code: int) -> str:
    if code == ERR_CMD_UNKNOWN:
        return "FPGA error: wrong/unknown command (0x80)"
    if code == ERR_LOAD_LEN:
        return "FPGA error: error with loaded program length"
    return f"FPGA error: unknown error code 0x{code:02X}"


def _is_info(byte: int) -> bool:
    return 0x40 <= byte <= 0x7F


def _is_err(byte: int) -> bool:
    return 0x80 <= byte <= 0xFF


class DebugProtocol:
    def __init__(self, link, timeout_s: float, dmem_words: int, verbose: bool = False):
        self.link = link
        self.timeout_s = timeout_s
        self.dmem_words = dmem_words
        self.verbose = verbose

    def load_program(self, words: list[int]) -> None:
        if not words:
            raise ProtocolError("program is empty")
        if len(words) > 0xFFFF:
            raise ProtocolError("program length exceeds protocol limit (65535 words)")

        self.link.reset_input_buffer()
        self._send_cmd_expect(CMD_LOAD, ACK_CMD_LOAD, "ACK_CMD_LOAD")

        self.link.write(struct.pack("<H", len(words)))
        payload = b"".join(struct.pack("<I", w & 0xFFFFFFFF) for w in words)
        self.link.write(payload)

        self._wait_status({ACK_LOAD_DONE}, "ACK_LOAD_DONE")

    def step(self) -> Snapshot:
        self._send_cmd_expect(CMD_STEP, ACK_CMD_STEP, "ACK_CMD_STEP")
        self._wait_status({ACK_STEP_DONE}, "ACK_STEP_DONE")
        return self._read_snapshot_transaction()

    def run(self) -> Snapshot:
        self._send_cmd_expect(CMD_RUN, ACK_RUN_START, "ACK_RUN_START")
        self._wait_status({ACK_RUN_DONE}, "ACK_RUN_DONE")
        return self._read_snapshot_transaction()

    def dump(self) -> Snapshot:
        self._send_cmd_expect(CMD_DUMP, ACK_CMD_DUMP, "ACK_CMD_DUMP")
        return self._read_snapshot_transaction()

    def _send_cmd_expect(self, cmd: int, ack: int, phase: str) -> None:
        self.link.write_u8(cmd)
        self._wait_status({ack}, phase)

    def _read_snapshot_transaction(self) -> Snapshot:
        self._wait_status({ACK_SNAP_START}, "ACK_SNAP_START")
        frame = self._wait_header_after_snap_start()
        payload = self._read_snapshot_payload(frame)
        self._wait_status({ACK_SNAP_DONE}, "ACK_SNAP_DONE")
        return decode_snapshot(payload, self.dmem_words)

    def _wait_status(self, expected: set[int], phase: str) -> int:
        deadline = time.monotonic() + self.timeout_s
        while True:
            byte = self._read_byte(deadline, phase)
            if byte in expected:
                return byte
            if _is_info(byte):
                if self.verbose:
                    print(f"INFO: 0x{byte:02X}")
                continue
            if _is_err(byte):
                raise FpgaError(byte, map_fpga_error(byte))
            if self.verbose:
                print(f"Ignoring unexpected status/data byte 0x{byte:02X} while waiting {phase}")

    def _read_snapshot_payload(self, header: bytes) -> bytes:
        if header != SNAP_HEADER:
            raise ProtocolError("invalid snapshot header")

        payload_len = expected_payload_len(self.dmem_words)
        deadline = time.monotonic() + self.timeout_s
        out = bytearray()
        while len(out) < payload_len:
            byte = self._read_byte(deadline, "snapshot payload")
            out.append(byte)
        return bytes(out)

    def _wait_header_after_snap_start(self) -> bytes:
        deadline = time.monotonic() + self.timeout_s
        window = bytearray()
        while True:
            byte = self._read_byte(deadline, "snapshot header A5 5A")
            window.append(byte)
            if len(window) > 2:
                del window[0]
            if len(window) == 2 and bytes(window) == SNAP_HEADER:
                return bytes(window)

    def _read_byte(self, deadline: float, phase: str) -> int:
        try:
            return self.link.read_u8(deadline)
        except TimeoutErrorPhase as exc:
            raise TimeoutErrorPhase(phase) from exc
