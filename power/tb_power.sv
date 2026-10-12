`timescale 1ns/1ps
module tb_power;
  reg clk=0,reset=1,power_good=1,isolate=1;
  always #5 clk=~clk;
  reg [31:0] imem_rdata=32'h00108093,dmem_rdata=0; // ADDI x1,x1,1
  wire [31:0] imem_addr,dmem_addr,dmem_wdata,trap_pc,retire_pc,retire_insn,retire_data;
  wire [3:0] dmem_wstrb,trap_cause;
  wire [4:0] retire_rd;
  wire dmem_valid,trapped,retire_valid;
  rv32i_power_shell dut(.*);
  integer cycles=0;
  task check_clamp;
    if({imem_addr,dmem_valid,dmem_addr,dmem_wdata,dmem_wstrb,trapped,trap_cause,trap_pc,retire_valid,retire_pc,retire_insn,retire_data,retire_rd} !== 0)
      $fatal(1,"isolation leak");
  endtask
  initial begin
    repeat(3)@(negedge clk);
    reset=0;isolate=0;
    repeat(5)@(negedge clk);
    if(retire_data!==5)$fatal(1,"initial execution");
    repeat(3)begin
      isolate=1;reset=1;@(negedge clk);power_good=0;
      // Explicit fault injection models unknown switched-domain outputs.
      force dut.core_imem_addr='x;force dut.core_dmem_valid=1'bx;
      force dut.core_dmem_addr='x;force dut.core_dmem_wdata='x;force dut.core_dmem_wstrb='x;
      force dut.core_trapped=1'bx;force dut.core_trap_cause='x;force dut.core_trap_pc='x;
      force dut.core_retire_valid=1'bx;force dut.core_retire_pc='x;force dut.core_retire_insn='x;
      force dut.core_retire_data='x;force dut.core_retire_rd='x;
      repeat(4)begin @(negedge clk);check_clamp();end
      power_good=1;
      release dut.core_imem_addr;release dut.core_dmem_valid;
      release dut.core_dmem_addr;release dut.core_dmem_wdata;release dut.core_dmem_wstrb;
      release dut.core_trapped;release dut.core_trap_cause;release dut.core_trap_pc;
      release dut.core_retire_valid;release dut.core_retire_pc;release dut.core_retire_insn;
      release dut.core_retire_data;release dut.core_retire_rd;
      repeat(2)@(negedge clk);
      reset=0;isolate=0;
      repeat(3)@(negedge clk);
      if(retire_data!==3)$fatal(1,"restart must begin with cleared registers");
    end
    $display("PASS three isolation/power-loss/restart cycles, all outputs clamped under X injection");$finish;
  end
  initial begin #5000;$fatal(1,"power test timeout");end
endmodule
