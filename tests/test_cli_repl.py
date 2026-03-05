from __future__ import annotations

from pathlib import Path

from cli.cli import CliApp
from cli.config import CliConfig
from cli.snapshot import Snapshot, StageLatches


class FakeProtocol:
    def __init__(self, snapshot: Snapshot):
        self.snapshot = snapshot
        self.load_calls: list[list[int]] = []
        self.step_calls = 0
        self.run_calls = 0
        self.dump_calls = 0

    def load_program(self, words: list[int]) -> None:
        self.load_calls.append(words)

    def step(self) -> Snapshot:
        self.step_calls += 1
        return self.snapshot

    def run(self) -> Snapshot:
        self.run_calls += 1
        return self.snapshot

    def dump(self) -> Snapshot:
        self.dump_calls += 1
        return self.snapshot


def _sample_snapshot() -> Snapshot:
    return Snapshot(
        pipe=StageLatches(
            if_next_pc=1,
            if_pc=2,
            id_inst=3,
            id_next_pc=4,
            id_pc=5,
            id_imm=6,
            id_rs1=7,
            id_rs2=8,
            id_rd=9,
            ex_result=10,
            ex_rs2=11,
            ex_rd=12,
            mem_result=13,
            mem_data=14,
            mem_rd=15,
            wb_data=16,
            wb_rd=17,
        ),
        regs=[0] * 32,
        dmem=[],
    )


def test_unknown_command_prints_exactly_wrong_command(capsys) -> None:
    proto = FakeProtocol(_sample_snapshot())
    app = CliApp(protocol=proto, config=CliConfig(), assembler_fn=lambda _: [0xFFFFFFFF])

    app.execute_line("not-a-command")
    out = capsys.readouterr().out.strip()
    assert out == "wrong command"


def test_dump_without_cache_queries_fpga_and_updates_cache(capsys) -> None:
    proto = FakeProtocol(_sample_snapshot())
    app = CliApp(protocol=proto, config=CliConfig(), assembler_fn=lambda _: [0xFFFFFFFF])
    assert app.last_snapshot is None

    app.execute_line("dump")

    out = capsys.readouterr().out
    assert proto.dump_calls == 1
    assert app.last_snapshot is not None
    assert "SNAPSHOT" in out


def test_load_rejects_empty_assembled_program(capsys, tmp_path: Path, monkeypatch) -> None:
    proto = FakeProtocol(_sample_snapshot())
    app = CliApp(protocol=proto, config=CliConfig(), assembler_fn=lambda _: [])
    monkeypatch.chdir(tmp_path)

    app.execute_line("load prog.asm")
    out = capsys.readouterr().out.strip()

    assert out == "incorrect length"
    assert proto.load_calls == []

