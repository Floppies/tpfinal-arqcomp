# FPGA Debug CLI Skeleton (RTL-Aligned)

This folder contains a primary Python skeleton for a UART CLI that talks to the FPGA `debug_unit` protocol in `sources/debug_unit.v`.

## Modules

- `cli.py`: REPL and command routing
- `config.py`: CLI config dataclass
- `constants.py`: protocol constants
- `errors.py`: typed errors
- `serial_link.py`: pyserial wrapper
- `protocol.py`: command FSM / UART transaction logic
- `assembler.py`: parser + pseudo expansion + encoder stubs
- `snapshot.py`: decode + pretty-print snapshots

## Command behavior

- `load <file>`: assemble, write `program.coe`, then load over UART
- `step`: execute one cycle and fetch snapshot
- `run`: execute until HALT and fetch snapshot
- `dump`: request fresh snapshot from FPGA
- Any unsupported REPL command prints exactly `wrong command`

## Protocol alignment notes

This skeleton follows current RTL behavior:

- `RUN`: expects `ACK_RUN_START (0x12)` then `ACK_RUN_DONE (0x13)` (no `0x03`)
- `LOAD`: sends 2-byte little-endian word count, then word payload bytes
- Snapshot transaction is bracketed by `ACK_SNAP_START (0x14)` and `ACK_SNAP_DONE (0x15)`

## Usage

```bash
python -m cli.cli -port COM5 -baud 115200 -timeout 1.5 -dmem-words 4
```

## Notes on assembler scope

Current assembler is intentionally skeleton-only:

- Implemented: parsing, label pass, pseudo expansion, HALT auto-append
- Not implemented yet: full instruction encoding (`AssemblerError` is raised)
- `.word` directives are encoded and can be used for immediate testing

