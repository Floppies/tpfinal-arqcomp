"""UART serial transport wrapper."""

import time
from typing import Callable

from .errors import CliError, TimeoutErrorPhase

try:
    import serial  # type: ignore
except Exception:  # pragma: no cover
    serial = None


ByteLogger = Callable[[str, int], None]


class SerialLink:
    def __init__(
        self,
        port: str,
        baud: int,
        timeout_s: float,
        verbose: bool = False,
        byte_logger: ByteLogger | None = None,
    ):
        self.port = port
        self.baud = baud
        self.timeout_s = timeout_s
        self.verbose = verbose
        self.byte_logger = byte_logger
        self._ser = None

    def open(self) -> None:
        if serial is None:
            raise CliError("pyserial is not installed")
        try:
            self._ser = serial.Serial(
                port=self.port,
                baudrate=self.baud,
                timeout=0,
                write_timeout=self.timeout_s,
            )
        except Exception as exc:
            raise CliError(f"failed to open serial port {self.port}: {exc}") from exc

    def close(self) -> None:
        if self._ser is not None:
            self._ser.close()
            self._ser = None

    def write(self, data: bytes) -> None:
        if self._ser is None:
            raise CliError("serial link is not open")
        self._ser.write(data)
        self._ser.flush()
        if self.verbose and self.byte_logger is not None:
            for value in data:
                self.byte_logger("TX", value)

    def write_u8(self, value: int) -> None:
        self.write(bytes((value & 0xFF,)))

    def read_u8(self, deadline: float) -> int:
        if self._ser is None:
            raise CliError("serial link is not open")
        while True:
            if time.monotonic() > deadline:
                raise TimeoutErrorPhase("serial byte")
            data = self._ser.read(1)
            if data:
                value = data[0]
                if self.verbose and self.byte_logger is not None:
                    self.byte_logger("RX", value)
                return value
            time.sleep(0.001)

    def reset_input_buffer(self) -> None:
        if self._ser is None:
            raise CliError("serial link is not open")
        self._ser.reset_input_buffer()

    def reset_output_buffer(self) -> None:
        if self._ser is None:
            raise CliError("serial link is not open")
        self._ser.reset_output_buffer()

