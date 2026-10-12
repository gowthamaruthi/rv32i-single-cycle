`timescale 1ns/1ps
// Explicit digital isolation model. Supply loss is modeled in the testbench.
module rv32i_power_shell (
  input wire clk, reset,
  input wire power_good, isolate,
  output wire [31:0] imem_addr,
  input wire [31:0] imem_rdata,
  output wire dmem_valid,
  output wire [31:0] dmem_addr, dmem_wdata,
  output wire [3:0] dmem_wstrb,
  input wire [31:0] dmem_rdata,
  output wire trapped,
  output wire [3:0] trap_cause,
  output wire [31:0] trap_pc,
  output wire retire_valid,
  output wire [31:0] retire_pc, retire_insn, retire_data,
  output wire [4:0] retire_rd
);
  wire [31:0] core_imem_addr;
  wire [0:0] core_dmem_valid;
  wire [31:0] core_dmem_addr;
  wire [31:0] core_dmem_wdata;
  wire [3:0] core_dmem_wstrb;
  wire [0:0] core_trapped;
  wire [3:0] core_trap_cause;
  wire [31:0] core_trap_pc;
  wire [0:0] core_retire_valid;
  wire [31:0] core_retire_pc;
  wire [31:0] core_retire_insn;
  wire [31:0] core_retire_data;
  wire [4:0] core_retire_rd;
  rv32i_core u_core (.clk(clk), .reset(reset), .imem_rdata(imem_rdata), .dmem_rdata(dmem_rdata),
    .imem_addr(core_imem_addr),
    .dmem_valid(core_dmem_valid),
    .dmem_addr(core_dmem_addr),
    .dmem_wdata(core_dmem_wdata),
    .dmem_wstrb(core_dmem_wstrb),
    .trapped(core_trapped),
    .trap_cause(core_trap_cause),
    .trap_pc(core_trap_pc),
    .retire_valid(core_retire_valid),
    .retire_pc(core_retire_pc),
    .retire_insn(core_retire_insn),
    .retire_data(core_retire_data),
    .retire_rd(core_retire_rd));
  assign imem_addr=isolate ? 32'b0 : core_imem_addr;
  assign dmem_valid=isolate ? 1'b0 : core_dmem_valid;
  assign dmem_addr=isolate ? 32'b0 : core_dmem_addr;
  assign dmem_wdata=isolate ? 32'b0 : core_dmem_wdata;
  assign dmem_wstrb=isolate ? 4'b0 : core_dmem_wstrb;
  assign trapped=isolate ? 1'b0 : core_trapped;
  assign trap_cause=isolate ? 4'b0 : core_trap_cause;
  assign trap_pc=isolate ? 32'b0 : core_trap_pc;
  assign retire_valid=isolate ? 1'b0 : core_retire_valid;
  assign retire_pc=isolate ? 32'b0 : core_retire_pc;
  assign retire_insn=isolate ? 32'b0 : core_retire_insn;
  assign retire_data=isolate ? 32'b0 : core_retire_data;
  assign retire_rd=isolate ? 5'b0 : core_retire_rd;
  // A powered-off core is not clocked by the integration environment.
  // power_good is observed by the sequencing monitor, not used as a clock gate.
`ifndef SYNTHESIS
  always @(posedge clk) begin
    if(!power_good && !isolate)$fatal(1,"isolation must precede power loss");
    if(!power_good && !reset)$fatal(1,"reset must stay asserted while power is off");
  end
`endif
endmodule
