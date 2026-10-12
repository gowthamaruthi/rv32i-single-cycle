# RV32I Single-Cycle CPU Core

I’m building a small RV32I processor with a reproducible verification flow. This milestone includes working SystemVerilog RTL, an independently structured Python reference model, directed and seeded instruction tests, lint, and generic Yosys synthesis. My next milestone is a constrained physical implementation; **this revision does not have GDSII, timing closure, or measured PPA**.

## Architecture

```mermaid
flowchart LR
  PC[Program counter] --> IM[External combinational instruction memory]
  IM --> DE[Decode and immediate generation]
  DE --> RF[32-register file, x0 fixed to zero]
  RF --> ALU[ALU and branch comparison]
  DE --> ALU
  ALU --> DM[External combinational-read data memory]
  DM --> WB[Load alignment and writeback]
  ALU --> WB
  WB --> RF
  ALU --> PC
```

The core executes one instruction per clock while running. Instruction and data memories are external and must provide combinational reads. This is an architectural property, not a measured clock-frequency claim. Decode, register file, ALU, immediate generation and control are contained in `rtl/rv32i_core.sv`. See [the specification](SPEC.md) for ports, supported instructions, reset and trap behavior.

## Run

Dependencies: Python 3 (standard library only), Icarus Verilog, Verilator and Yosys. Tested versions are recorded in [results](docs/results/versions.txt).

```sh
# macOS with an existing Homebrew installation
brew install icarus-verilog verilator yosys
bash scripts/check.sh
# Individual steps
verilator --lint-only -Wall rtl/rv32i_core.sv
python3 scripts/regress.py
python3 scripts/mutations.py
```

`check.sh` runs lint, regression, generic synthesis with structural checks, and isolated mutation tests. Commands exit nonzero on failure. Generated programs, traces, memory/register dumps and logs are in `build/`; comparison failures are rerun to save a VCD. A hung simulator fails after a 30-second host timeout (a zero-time scheduling hang may not produce a useful waveform).

## Verification evidence

| Check | Observed result |
|---|---|
| Verilator lint | PASS with `-Wall` |
| Directed, random and trap programs | 30 PASS; 13,007 retirements compared |
| Random reproducibility | Seeds 0 through 9; generator checked into source |
| Instruction/outcome bins | Every supported non-trapping operation and both outcomes of all six branches observed |
| Architectural comparison | Every retirement, memory request, final register and memory contents |
| Trap behavior | Illegal instructions, ECALL/EBREAK, instruction/load/store alignment; sticky halt and reset recovery |
| Negative tests | Arithmetic shift, subtraction and store-byte-lane mutations detected |
| Yosys | Generic synthesis and `check -assert` PASS |

The checked-in [result summary](docs/results/summary.json), [logs](docs/results/regression.log), [synthesis log](docs/results/synthesis.log), and [source hashes](docs/results/source-sha256.txt) identify this local run. These bins are finite test-plan observations, not code coverage or architectural certification. The Python model is project verification code, not Spike or an official RISC-V test suite. Shared misunderstandings between the model and RTL remain possible. No formal proof, FPGA measurement, or gate-level timing simulation is claimed.

### A bug the tests found

The first directed run caught SRA returning `0x40000000` instead of `0xc0000000` when shifting a negative operand. A mixed signed/unsigned ternary expression caused the arithmetic shift to use unsigned expression context. I replaced it with explicit branches. A mutation that restores logical shifting fails the same retirement comparison. I also separated effective-address calculation from load-result decoding to remove a combinational scheduling loop seen in Icarus.

## Scope and next milestone

This core has no interrupts, privileged execution, CSRs, caches, wait-state interface or ISA extensions. ECALL/EBREAK halt into a documented test execution environment. Reset is synchronous and clears registers. The core cannot directly connect to synchronous-read block RAM without architectural changes.

I have not run Synopsys Design Compiler, Cadence Innovus, OpenROAD or OpenSTA on this project. Generic synthesis reports are not standard-cell area, power, timing closure or a final layout. A physical milestone needs a distributable platform/library, explicit memory and I/O delay constraints, mapped synthesis, placement/CTS/routing, extracted STA and physical checks before publishing those claims. External memories and the combinational memory round trip must be accounted for in the integration timing budget.

## Attribution

This is a newly developed educational implementation with AI-assisted development and review; it does not reuse a third-party CPU RTL implementation. Instruction behavior follows the [RISC-V unprivileged RV32I specification](https://docs.riscv.org/reference/isa/unpriv/rv32.html). The execution-environment choices and limitations are specified here rather than presented as privileged-architecture support.
