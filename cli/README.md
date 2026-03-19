# FPGA Debug CLI (RTL-Aligned)

This folder contains a primary Python skeleton for a UART CLI that talks to the FPGA `debug_unit` protocol in `sources/debug_unit.v`.

## Modules

- `cli.py`: REPL and command routing
- `config.py`: CLI config dataclass
- `constants.py`: protocol constants
- `errors.py`: typed errors
- `serial_link.py`: pyserial wrapper
- `protocol.py`: command FSM / UART transaction logic
- `assembler.py`: parser + pseudo expansion + instruction encoder
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

## Hardware validation

The repo includes short programs that were validated on the Basys 3 build and are useful as smoke tests after generating a new bitstream.

### 1. Dependency / forwarding test

Run:

```text
load dependency_program.asm
run
```

Expected final architectural state:

- `x1 = 0x00000005`
- `x2 = 0x00000007`
- `x3 = 0x0000000C`
- `x4 = 0x00000011`
- `x5 = 0x00000011`
- `x6 = 0x00000018`
- `mem[0] = 0x00000011`

Notes:

- This checks ALU forwarding and a `lw` -> use dependency.
- The program also stores `x6` at word address `4`, so it will not appear in the default `dmem-words = 4` snapshot window.

### 2. Branch / flush test

Run:

```text
load branch_program.asm
run
```

Expected final architectural state:

- `x1 = 0x00000003`
- `x2 = 0x00000003`
- `x3 = 0x00000001`
- `x4 = 0x00000002`
- `x5 = 0x00000000`
- `x6 = 0x00000003`
- `mem[0] = 0x00000003`

Notes:

- This checks `beq`, `bne`, and wrong-path flush behavior.
- `x5` must stay `0`; if it becomes non-zero, a wrong-path instruction executed.

### 3. JAL / JR / JALR return test

Run:

```text
load jalr_program.asm
run
```

Expected final architectural state:

- `x1 = 0x00000002`
- `x2 = 0x00000005`
- `x3 = 0x00000007`
- `x4 = 0x00000003`
- `mem[0] = 0x00000007`

Notes:

- This checks `jal`, register return via `jr`/`jalr`, and control-flow recovery after returning from a subroutine.
- The internal PC in this design is word-addressed, so link/register jump values are expressed in instruction indices rather than byte addresses.

## Assembler support (current)

- Pseudos: `nop`, `halt`, `j`, `jr`
- R-type: `add`, `sub`, `and`, `or`, `xor`, `sll`, `srl`, `sra`, `slt`, `sltu`
- Aliases: `sllv`, `srlv`, `srav`, `addiu`, `lwu`
- Loads/Stores: `lb`, `lh`, `lw`, `lbu`, `lhu`, `sb`, `sh`, `sw`
- Branch/Jump: `beq`, `bne`, `jal`, `jalr`, `lui`
- Directive: `.word`

`nor` is supported as a 2-instruction pseudo expansion:
`or rd, rs1, rs2` + `xori rd, rd, -1`
