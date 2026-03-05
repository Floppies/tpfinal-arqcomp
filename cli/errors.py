"""Typed errors for CLI subsystems."""


class CliError(Exception):
    """Base class for CLI errors."""


class ProtocolError(CliError):
    """Generic protocol/parsing/sequence error."""


class TimeoutErrorPhase(CliError):
    """Timeout while waiting for a specific phase."""

    def __init__(self, phase: str):
        self.phase = phase
        super().__init__(f"timeout waiting for {phase}")


class FpgaError(ProtocolError):
    """Error status reported by FPGA."""

    def __init__(self, code: int, message: str):
        self.code = code
        super().__init__(message)


class AssemblerError(CliError):
    """Assembler parsing/encoding error with line context."""

    def __init__(self, line_no: int, line_text: str, reason: str):
        self.line_no = line_no
        self.line_text = line_text
        self.reason = reason
        super().__init__(f"line {line_no}: {reason}: {line_text}")

