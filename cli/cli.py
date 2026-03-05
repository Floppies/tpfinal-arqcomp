"""REPL CLI entrypoint for FPGA debug protocol."""

from __future__ import annotations

import argparse
import shlex
import sys
from pathlib import Path
from typing import Callable

from .assembler import assemble_file, write_coe
from .config import CliConfig
from .errors import AssemblerError, CliError
from .protocol import DebugProtocol
from .serial_link import SerialLink
from .snapshot import Snapshot, format_snapshot


class CliApp:
    def __init__(
        self,
        protocol: DebugProtocol,
        config: CliConfig,
        assembler_fn: Callable[[Path], list[int]] = assemble_file,
    ):
        self.protocol = protocol
        self.config = config
        self.assembler_fn = assembler_fn
        self.last_snapshot: Snapshot | None = None

    def handle_load(self, path: str) -> None:
        words = self.assembler_fn(Path(path))
        if len(words) < 1 or len(words) > self.config.max_words:
            print("incorrect length")
            return

        write_coe(words, Path.cwd() / "program.coe")
        self.protocol.load_program(words)
        print(f"loaded {len(words)} words")

    def handle_step(self) -> None:
        snap = self.protocol.step()
        self.last_snapshot = snap
        print(format_snapshot(snap))

    def handle_run(self) -> None:
        snap = self.protocol.run()
        self.last_snapshot = snap
        print(format_snapshot(snap))

    def handle_dump(self) -> None:
        snap = self.protocol.dump()
        self.last_snapshot = snap
        print(format_snapshot(snap))

    def execute_line(self, line: str) -> bool:
        try:
            tokens = shlex.split(line)
        except ValueError:
            print("wrong command")
            return True

        if not tokens:
            return True

        cmd = tokens[0].lower()
        try:
            if cmd == "load" and len(tokens) == 2:
                self.handle_load(tokens[1])
            elif cmd == "step" and len(tokens) == 1:
                self.handle_step()
            elif cmd == "run" and len(tokens) == 1:
                self.handle_run()
            elif cmd == "dump" and len(tokens) == 1:
                self.handle_dump()
            elif cmd in {"exit", "quit"} and len(tokens) == 1:
                return False
            else:
                print("wrong command")
        except (CliError, AssemblerError) as exc:
            print(str(exc))
        return True


def _resolve_default_port() -> str:
    try:
        import serial.tools.list_ports  # type: ignore
    except Exception as exc:  # pragma: no cover
        raise CliError("serial port is required; pass -port <device>") from exc

    ports = list(serial.tools.list_ports.comports())
    if not ports:
        raise CliError("no serial ports detected; pass -port <device>")
    return ports[0].device


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="RISC-V FPGA UART debug CLI")
    parser.add_argument("-port", dest="port", default=None, help="serial port device (e.g. COM5)")
    parser.add_argument("-baud", dest="baud", type=int, default=115200, help="UART baud rate")
    parser.add_argument(
        "-timeout",
        dest="timeout_s",
        type=float,
        default=1.5,
        help="per-phase timeout in seconds",
    )
    parser.add_argument(
        "-dmem-words",
        dest="dmem_words",
        type=int,
        default=4,
        help="DMEM words expected in snapshot payload",
    )
    parser.add_argument(
        "-max-words",
        dest="max_words",
        type=int,
        default=1024,
        help="max assembled words accepted by CLI",
    )
    parser.add_argument("-verbose", dest="verbose", action="store_true", help="verbose logs")
    return parser


def _make_config(args: argparse.Namespace) -> CliConfig:
    return CliConfig(
        port=args.port,
        baud=args.baud,
        timeout_s=args.timeout_s,
        dmem_words=args.dmem_words,
        verbose=args.verbose,
        max_words=args.max_words,
    )


def _make_protocol(config: CliConfig) -> DebugProtocol:
    port = config.port if config.port else _resolve_default_port()
    link = SerialLink(
        port=port,
        baud=config.baud,
        timeout_s=config.timeout_s,
        verbose=config.verbose,
        byte_logger=lambda direction, value: print(f"{direction}: 0x{value:02X}"),
    )
    link.open()
    return DebugProtocol(link, timeout_s=config.timeout_s, dmem_words=config.dmem_words, verbose=config.verbose)


def repl_loop(app: CliApp) -> None:
    while True:
        try:
            line = input("debug> ")
        except EOFError:
            break
        if not app.execute_line(line):
            break


def main(argv: list[str] | None = None) -> int:
    parser = _build_parser()
    args = parser.parse_args(argv)
    config = _make_config(args)

    try:
        protocol = _make_protocol(config)
    except CliError as exc:
        print(str(exc))
        return 1

    app = CliApp(protocol=protocol, config=config)
    try:
        repl_loop(app)
    finally:
        protocol.link.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))

