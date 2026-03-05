# RISC-V FPGA UART Debug CLI — Specification v1.1

## A) CLI Functionality

### A.1 Purpose

The CLI must:

- Connect to the FPGA over a UART serial port (USB-Serial).
- Get a program in human-readeble form in assembler and turn it into a binary code.
- Load a binary program into the FPGA instruction memory.
- Control execution (`step`, `run`).
- Fetch and display snapshots (`dump`).
- Be robust to UART timing / partial reads / stale bytes.

### A.2 Interactive command interface

The CLI runs as a REPL-style shell:

Supported commands:

- `load <program.asm>`
- `step`
- `run`
- `dump`
- Any other input → print **exactly**: `wrong command`

### A.3 CLI options (command-line args)

Required/Supported flags:

- `-port <device>`: serial port path/name (e.g., `/dev/ttyUSB0`, `COM5`). Otherwise use default.
- `-baud <int>`: baud rate (default = your design’s baud)
- `-timeout <float>`: per-phase timeout in seconds (default recommended 1.0–2.0)
- `-dmem-words <N>`: number of DMEM snapshot words expected after regs (**default 0**)
- `-verbose`: prints INFO bytes and extra protocol/debug logs

### A.4 Output requirements

- For invalid CLI commands: `wrong command`
- For invalid program length input: `incorrect length`
- For FPGA `ERR_LOAD_LEN (0x81)`: print exactly: `loading error regarding program length`
- Other FPGA errors should print a clear message (see UART section).

### A.5 Snapshot caching

The CLI must store the most recent successfully decoded snapshot as `last_snapshot`.

- `dump` prints `last_snapshot` (see section E).
- If none exists: print `No snapshot available`

## B) Assembler / Translation

### B.1 Accepted input files

The translator accepts:

- `.asm`
- `.s`
    
    Optionally also accept `.txt` as plain assembly text.
    

### B.2 Program model

- Program is a list of **32-bit instructions**.
- Each instruction becomes one **uint32 word**.
- Program is loaded into FPGA instruction memory starting at word address 0.

### B.3 Supported instruction set

Must support the subset required by your TP and tests (at least):

- R-type: `add`, `sub`, etc. (whatever your CPU implements)
- I-type: `addi`, `lw`, etc.
- S-type: `sw`, etc.
- B/J types if needed by your labs/tests

> If an instruction is not supported by the CLI assembler, it must error with line number and abort load.
> 

### B.4 Pseudo-instructions (required)

The translator must expand:

- `nop` → `0x00000000`
- `halt` → `0xFFFFFFFF`
- `j label` → `jal x0, label`
- `jr rs1` → `jalr x0, rs1, 0`

### B.5 HALT enforcement (required)

After translation + pseudo-expansion:

- If the last emitted word is not `0xFFFFFFFF`, the translator **must append** `0xFFFFFFFF` (HALT)
- It must warn (console): `HALT appended automatically`
- If this causes overflow over the maximum allowed length, abort.

### B.6 Length / capacity rules

The load menu asks the user:

- “input program length in words (max 99)”

Validation:

- Must be integer
- Must be 1..99
- Otherwise print **exactly**: `incorrect length` and abort load.

Length policy (recommended to avoid ERR_LOAD_LEN):

- **Strict match**: if translated words count != user-declared word count → abort before sending.
    - Rationale: avoids FPGA receiving more than declared.
    - If HALT required, add +1 to the user-declared word count to be send.

### B.7 Output representation

Internally:

- Store output program as a .coe file in the same folder where the program is running.

When sending to FPGA:

- Each uint32 is sent as **4 bytes, little-endian**.

## C) UART Protocol Specifications

### C.1 Serial connection

- UART over serial port, blocking reads with timeout.
- CLI must allow port selection and baud configuration.

### C.2 Status byte format (1 byte)

FPGA transmits 1-byte status codes:

- `0x00..0x3F`: **ACK**
- `0x40..0x7F`: **INFO**
- `0x80..0xFF`: **ERR**

CLI behavior:

- ACK: advances the expected state machine (per command sequence)
- INFO: ignore by default, print if `-verbose`
- ERR: abort current command immediately and print mapped message

### C.3 Defined ACK codes

- `0x01` ACK_CMD_LOAD
- `0x02` ACK_CMD_STEP
- `0x03` ACK_CMD_RUN
- `0x04` ACK_CMD_DUMP
- `0x10` ACK_LOAD_DONE
- `0x11` ACK_STEP_DONE
- `0x12` ACK_RUN_START
- `0x13` ACK_RUN_DONE
- `0x14` ACK_SNAP_START
- `0x15` ACK_SNAP_DONE

### C.4 Defined ERR codes + required CLI messages

- `0x80` ERR_CMD_UNKNOWN
    - If triggered by user typing unsupported CLI command → CLI already prints `wrong command`
    - If FPGA returns it after a UART TX, print: `FPGA error: wrong/unknown command (0x80)` (optional extra)
- `0x81` ERR_LOAD_LEN
    - **Must print exactly**: `FPGA error: error with loaded program length`
- `0x82` ERR_LOAD_TIMEOUT
    - Print: `FPGA error: loading timeout`
- `0x83` ERR_INTERNAL_STATE
    - Print: `FPGA error: internal state error`

### C.5 RX dispatcher requirements (critical)

The CLI must parse a mixed stream of:

- status bytes (ACK/INFO/ERR)
- snapshot bytes (frame beginning `A5 5A`)

Dispatcher must support:

- scanning for ACK/ERR while waiting for phase transitions
- switching into “snapshot read mode” after `ACK_SNAP_START`
- resynchronization when header not found

### C.6 Timeouts and recovery

Per phase, CLI must enforce timeouts:

- Wait for command ACK (e.g. 0x01/0x02/0x03/0x04)
- Wait for RUN_START/RUN_DONE
- Wait for SNAP_START
- Wait for snapshot header `A5 5A`
- Wait for full payload
- Wait for SNAP_DONE

On timeout:

- Print: `timeout waiting for <expected code/frame>`
- Reset/flush buffers:
    - `reset_input_buffer()` recommended
    - If mid-load and error: also `reset_output_buffer()` recommended

## D) Command Handshakes (Exact “Expect/Do” Sequences)

### D.1 LOAD: `load <file>`

**CLI steps**

1. Flush stale RX bytes: `reset_input_buffer()`
2. Ask user for length words (1..99)
3. Translate file → words, expand pseudos, enforce HALT, verify length
4. Compute `length_bytes = words * 4`
5. UART handshake:

**UART sequence**

- TX `'L'`
- RX expect `0x01 ACK_CMD_LOAD`
- TX: `length_bytes` (1 byte)
- RX expect either:
    - `0x10 ACK_LOAD_DONE` → success
    - `0x81/0x82/0x83` → fail

**Immediate behavior on** `0x81 ERR_LOAD_LEN`

If received at any time during load:

- Stop sending further bytes immediately
- Flush output buffer
- Print: `FPGA error: error with loaded program length`
- Abort

### D.2 STEP: `step`

**UART sequence**

- TX `'S'`
- RX expect `0x02 ACK_CMD_STEP`
- RX expect `0x11 ACK_STEP_DONE`
- RX expect `0x14 ACK_SNAP_START`
- RX snapshot frame (Section E)
- RX expect `0x15 ACK_SNAP_DONE`
- Decode, print, cache `last_snapshot`

If any ERR appears: abort and don’t update cache.

### D.3 RUN: `run`

**UART sequence**

- TX `'R'`
- RX expect `0x03 ACK_CMD_RUN`
- RX expect `0x12 ACK_RUN_START`
- RX expect `0x13 ACK_RUN_DONE`
- RX expect `0x14 ACK_SNAP_START`
- RX snapshot frame
- RX expect `0x15 ACK_SNAP_DONE`
- Decode, print, cache

Timeout protection: the CLI must not block forever; apply timeouts.

### D.4 DUMP: `dump`

This prints the latest snapshot received by the CLI:

- TX `'D'`
- RX expect `0x04 ACK_CMD_DUMP`
- RX expect `0x14 ACK_SNAP_START`
- RX snapshot frame
- RX expect `0x15 ACK_SNAP_DONE`
- Decode, print, cache

Timeout protection: the CLI must not block forever; apply timeouts.

## E) Snapshot Reception, Decoding, and Presentation

### E.1 Snapshot lifecycle (with ACKs)

A snapshot is bracketed by:

- `0x14 ACK_SNAP_START`
- then a raw snapshot stream (A5 5A + payload)
- then `0x15 ACK_SNAP_DONE`

The CLI must *enforce this bracketing* and treat it as the snapshot transaction.

### E.2 Snapshot frame format

Header

- `0xA5 0x5A`

Payload size

`payload_bytes = (17 + 32 + DMEM_WORDS) * 4`

Where:

- DMEM_WORDS = `-dmem-words` (default 0)

**Endianness**

Each 32-bit word is little-endian.

### E.3 Word mapping (exact)

PIPE words (0..16):

0 IF_next_pc

1 IF_pc

2 ID_inst

3 ID_next_pc

4 ID_pc

5 ID_imm

6 ID_Rs1

7 ID_Rs2

8 ID_rd (zero-extended)

9 EX_result

10 EX_Rs2

11 EX_rd (zero-extended)

12 MEM_result

13 MEM_data

14 MEM_rd (zero-extended)

15 WB_data

16 WB_rd (zero-extended)

Regs (17..48):

- x0..x31

DMEM:

- starts at word index 49
- `snap_dmem[0..DMEM_WORDS-1]`

### E.4 Snapshot formatting (required)

Must print human-legible sections in this order:

1. **Stage latches** (PIPE words)
2. **Current reg bank** (x00..x31)
3. **DMEM snapshot** (if DMEM_WORDS > 0)

**Formatting rules:**

- Hex uppercase or lowercase allowed, but consistent
- Always `0x` + 8 hex digits
- Registers must be labeled `x00`..`x31`

**Example structure:**

```
SNAPSHOT
----------------------------
Stage latches:
IF_next_pc = 0x........
...

----------------------------
Current reg bank:
x00 = 0x........
...

----------------------------
Snap words from memory:
mem[00] @ 0x00000000 = 0x........
...
```

## F) Error Handling and Robustness

### F.1 UART desync prevention

- Always search for the snapshot header `A5 5A` only after receiving `ACK_SNAP_START`
- If header not found within timeout:
    - abort snapshot receive
    - flush RX buffer
    - report timeout

### F.2 Mid-stream ERR handling

If an ERR byte is received:

- Abort immediately
- Print mapped message
- Do not update snapshot cache

Special case:

- During load, if `0x81`: stop sending immediately and flush output.

## G)Modules:

`cli.py` — REPL + command routing

`serial_link.py` — UART open/close, write, low-level reads

`protocol.py` — dispatcher, wait_for_ack(), read_snapshot_transaction()

`assembler.py` — parse, pseudo expansion, encode

`snapshot.py` — data model + pretty printing

### Core concept:

Every command runs an explicit expected-state FSM based on the sequences in section D.

## H) RTL Alignment Overrides (current implementation)

This section resolves documented contradictions to match current FPGA RTL (`sources/debug_unit.v`):

- `RUN` command sequence uses `ACK_RUN_START (0x12)` directly after `TX 'R'`; there is no `ACK_CMD_RUN (0x03)` in current RTL.
- `LOAD` uses a 2-byte little-endian word count (`n_words[15:0]`) after `ACK_CMD_LOAD (0x01)`, then sends `n_words * 4` payload bytes (little-endian per word).
- `LOAD` sequence must explicitly include TX program payload bytes after the 2-byte length field.
- `ERR_LOAD_LEN (0x81)` user-facing message is normalized to: `FPGA error: error with loaded program length`.
- `dump` performs a UART transaction (`'D'` + snapshot handshake) and updates `last_snapshot`; it is not cache-only.
- Default `-dmem-words` should match the deployed bitstream configuration. Current `full_datapath.v` default is `DMEM_SNAP_WORDS = 4`.
