"""CLI configuration."""

from dataclasses import dataclass


@dataclass(frozen=True)
class CliConfig:
    port: str | None = None
    baud: int = 115200
    timeout_s: float = 1.5
    dmem_words: int = 4
    verbose: bool = False
    max_words: int = 1024

