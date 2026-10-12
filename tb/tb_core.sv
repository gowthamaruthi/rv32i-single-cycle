`timescale 1ns/1ps
module tb_core;
  reg clk=0,reset=1;
  always #5 clk=~clk;
  wire [31:0] imem_addr,dmem_addr,dmem_wdata;
  reg [31:0] imem_rdata,dmem_rdata;
  wire dmem_valid,trapped,retire_valid;
  wire [3:0] dmem_wstrb,trap_cause;
  wire [31:0] trap_pc,retire_pc,retire_insn,retire_data;
  wire [4:0] retire_rd;
  rv32i_core dut(.*);
  reg [31:0] instructions[0:4095];
  reg [7:0] memory[0:4095];
  string program_path,trace_path,memory_path,register_path;
  integer fd,k,cycles=0,base;
  reg req;
  reg [31:0] addr,wd;
  reg [3:0] strobe;
  always @* begin
    imem_rdata=32'hffffffff;
    if(imem_addr<16384)imem_rdata=instructions[imem_addr>>2];
    dmem_rdata=0;
    if(dmem_addr<4096)dmem_rdata={memory[{dmem_addr[11:2],2'b00}+3],memory[{dmem_addr[11:2],2'b00}+2],memory[{dmem_addr[11:2],2'b00}+1],memory[{dmem_addr[11:2],2'b00}]};
  end
  initial begin
    if(!$value$plusargs("PROGRAM=%s",program_path))$fatal(1,"PROGRAM missing");
    if(!$value$plusargs("TRACE=%s",trace_path))$fatal(1,"TRACE missing");
    if(!$value$plusargs("MEMORY=%s",memory_path))$fatal(1,"MEMORY missing");
    if(!$value$plusargs("REGISTERS=%s",register_path))$fatal(1,"REGISTERS missing");
    for(k=0;k<4096;k=k+1)begin instructions[k]=32'h13;memory[k]=8'(k*37+11);end
    $readmemh(program_path,instructions);
    fd=$fopen(trace_path,"w");if(!fd)$fatal(1,"trace open");
    if($test$plusargs("WAVES"))begin $dumpfile("failure.vcd");$dumpvars(0,tb_core);end
    repeat(3)@(negedge clk);reset=0;
    wait(trapped);#2;
    $fdisplay(fd,"TRAP %08x %01x",trap_pc,trap_cause);
    $writememh(memory_path,memory);$writememh(register_path,dut.regs);
    repeat(4)begin @(negedge clk);if(retire_valid || dmem_valid)$fatal(1,"activity after trap");end
    reset=1;@(negedge clk);#1;
    if(trapped || imem_addr!=0 || retire_valid || dmem_valid)$fatal(1,"reset recovery");
    for(k=0;k<32;k=k+1)if(dut.regs[k]!==0)$fatal(1,"register reset");
    $fclose(fd);$display("PASS simulation cycles=%0d",cycles);$finish;
  end
  always @(posedge clk)begin
    req=dmem_valid;addr=dmem_addr;wd=dmem_wdata;strobe=dmem_wstrb;
    if(!reset && !trapped)begin
      cycles=cycles+1;
      if(req)begin
        if(addr>=4096)$fatal(1,"data memory outside test environment");
        base=integer'(addr & 32'hfffffffc);
        for(integer lane=0;lane<4;lane=lane+1)if(strobe[lane])memory[base+lane]<=wd[lane*8+:8];
      end
      #1;
      if(dut.regs[0]!==0)$fatal(1,"x0 changed");
      if(retire_valid)$fdisplay(fd,"RET %08x %08x %02x %08x %01x %08x %01x %08x",retire_pc,retire_insn,retire_rd,retire_data,req,req ? addr:0,req ? strobe:0,req ? wd:0);
    end
  end
  initial begin #200000;$fatal(1,"watchdog");end
endmodule
