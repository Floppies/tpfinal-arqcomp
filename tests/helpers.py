from __future__ import annotations

from collections import deque

from cli.errors import TimeoutErrorPhase


class FakeLink:
    def __init__(self, rx_bytes: list[int] | bytes):
        if isinstance(rx_bytes, bytes):
            rx_list = list(rx_bytes)
        else:
            rx_list = list(rx_bytes)
        self._rx = deque(rx_list)
        self.writes: list[bytes] = []
        self.reset_input_calls = 0
        self.reset_output_calls = 0

    def write(self, data: bytes) -> None:
        self.writes.append(bytes(data))

    def write_u8(self, value: int) -> None:
        self.write(bytes((value & 0xFF,)))

    def read_u8(self, deadline: float) -> int:
        del deadline
        if not self._rx:
            raise TimeoutErrorPhase("serial byte")
        return self._rx.popleft()

    def reset_input_buffer(self) -> None:
        self.reset_input_calls += 1

    def reset_output_buffer(self) -> None:
        self.reset_output_calls += 1

    def close(self) -> None:
        return None

