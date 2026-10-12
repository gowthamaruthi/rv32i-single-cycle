# RV32I single-cycle core specification

## Milestone and execution environment

A new 32-bit, single-cycle RV32I core, reset PC zero, little-endian memory, 32 integer registers with x0 fixed to zero. One instruction executes per rising edge when running; synchronous active-high reset clears the PC, register file and trap state. This implementation uses **combinational instruction and data reads** and edge-triggered byte-strobe writes. It cannot directly use synchronous-read SRAM without changing the microarchitecture. Memories are external, Harvard-style, and their timing belongs in the clock constraint.

RV32I operations: LUI, AUIPC, JAL, JALR; all six conditional branches; LB/LH/LW/LBU/LHU and SB/SH/SW; ADDI/SLTI/SLTIU/XORI/ORI/ANDI/SLLI/SRLI/SRAI; ADD/SUB/SLL/SLT/SLTU/XOR/SRL/SRA/OR/AND. FENCE is a no-op because memory operations are in order and complete each cycle. ECALL and EBREAK stop the execution environment with cause 11 and 3. No privileged ISA, CSRs, interrupts, M/A/C/F extensions, debug transport, cache, bus wait states or FENCE.I.

Illegal encodings stop with cause 2. Taken jumps/branches to non-word-aligned instruction addresses stop with cause 0; JALR clears target bit 0 before alignment checking. Halfword/word misaligned loads/stores stop with cause 4/6. A trap is sticky until reset: faulting instructions produce no retirement, register write or memory write. `trap_pc` identifies the faulting instruction. External memory is assumed accessible; access-fault inputs are not part of this milestone. Software must stay within the integrated memory map.

## Memory ports

`imem_addr` is PC, `imem_rdata` the instruction at that byte address. Data `dmem_addr` is the effective byte address. `dmem_rdata` is the entire little-endian 32-bit word at `(dmem_addr & ~3)`; the core extracts/sign-extends byte or halfword lanes. `dmem_valid` indicates a legal load/store during a running cycle. `dmem_wstrb` is zero for loads; otherwise its four bits select byte lanes of `dmem_wdata`, which is already shifted into place. A store commits only at a rising clock edge with `dmem_valid && |dmem_wstrb`. During reset or a sticky/new trap there is no data request.

## Retirement / test plan

Registered retirement outputs expose PC/instruction and nonzero destination register writeback for each completed instruction. A store retirement has no register destination. Testbench logs requests and retirement for comparison with an independently structured Python architectural model, including final byte-addressed memory. Programs are hand-encoded by a checked generator: directed instruction/edge cases and deterministic randomized programs. Include all branch outcomes, negative immediates, shifts, signed/unsigned boundaries, byte strobes, x0, jump link/target behavior, illegal encodings, misalignment and reset recovery. A timeout or comparison mismatch must fail the command. Mutation tests must demonstrate detection. This is not an official RISC-V architectural certification or formal proof.

First complete RTL verification and generic synthesis. Physical implementation, timing closure and GDSII require an actual tool/platform run with recorded constraints and reports. Never infer those results from the RTL or generic cell counts.
