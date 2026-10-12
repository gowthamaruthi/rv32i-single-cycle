`timescale 1ns/1ps
module rv32i_core (
  input wire clk, reset,
  output wire [31:0] imem_addr,
  input wire [31:0] imem_rdata,
  output wire dmem_valid,
  output wire [31:0] dmem_addr, dmem_wdata,
  output wire [3:0] dmem_wstrb,
  input wire [31:0] dmem_rdata,
  output reg trapped,
  output reg [3:0] trap_cause,
  output reg [31:0] trap_pc,
  output reg retire_valid,
  output reg [31:0] retire_pc, retire_insn, retire_data,
  output reg [4:0] retire_rd
);
  reg [31:0] pc, regs[0:31];
  wire [31:0] insn=imem_rdata;
  wire [4:0] rs1=insn[19:15],rs2=insn[24:20],rd=insn[11:7];
  wire [2:0] funct3=insn[14:12];
  wire [6:0] funct7=insn[31:25];
  wire [31:0] a=rs1==0 ? 32'b0 : regs[rs1];
  wire [31:0] b=rs2==0 ? 32'b0 : regs[rs2];
  wire [31:0] imm_i={{20{insn[31]}},insn[31:20]};
  wire [31:0] imm_s={{20{insn[31]}},insn[31:25],insn[11:7]};
  wire [31:0] imm_b={{19{insn[31]}},insn[31],insn[7],insn[30:25],insn[11:8],1'b0};
  wire [31:0] imm_u={insn[31:12],12'b0};
  wire [31:0] imm_j={{11{insn[31]}},insn[31],insn[19:12],insn[20],insn[30:21],1'b0};
  reg [31:0] next_pc,result,store_data;
  wire [31:0] address=insn[6:0]==7'h03 ? a+imm_i : insn[6:0]==7'h23 ? a+imm_s : 32'b0;
  reg [3:0] strobes,cause;
  reg write_rd,memory_op,illegal,exception,taken;
  wire [31:0] load_shifted=dmem_rdata >> {address[1:0],3'b0};
  assign imem_addr=pc;
  assign dmem_addr=address;
  assign dmem_valid=!reset && !trapped && !exception && memory_op;
  assign dmem_wstrb=dmem_valid ? strobes : 4'b0;
  assign dmem_wdata=store_data;
  always @* begin
    next_pc=pc+4;result=0;store_data=0;strobes=0;
    cause=0;write_rd=0;memory_op=0;illegal=0;exception=0;taken=0;
    case(insn[6:0])
      7'h37: begin write_rd=1;result=imm_u;end
      7'h17: begin write_rd=1;result=pc+imm_u;end
      7'h6f: begin write_rd=1;result=pc+4;next_pc=pc+imm_j;taken=1;end
      7'h67: begin
        write_rd=1;result=pc+4;next_pc=(a+imm_i)&32'hfffffffe;taken=1;
        if(funct3!=0)illegal=1;
      end
      7'h63: begin
        case(funct3)
          0:taken=a==b;
          1:taken=a!=b;
          4:taken=$signed(a)<$signed(b);
          5:taken=$signed(a)>=$signed(b);
          6:taken=a<b;
          7:taken=a>=b;
          default:illegal=1;
        endcase
        if(taken)next_pc=pc+imm_b;
      end
      7'h03: begin
        memory_op=1;write_rd=1;
        case(funct3)
          0:result={{24{load_shifted[7]}},load_shifted[7:0]};
          1:result={{16{load_shifted[15]}},load_shifted[15:0]};
          2:result=load_shifted;
          4:result={24'b0,load_shifted[7:0]};
          5:result={16'b0,load_shifted[15:0]};
          default:illegal=1;
        endcase
        if(((funct3==1 || funct3==5) && address[0]) || (funct3==2 && |address[1:0]))begin exception=1;cause=4;end
      end
      7'h23: begin
        memory_op=1;store_data=b << {address[1:0],3'b0};
        case(funct3)
          0:strobes=4'b0001 << address[1:0];
          1:strobes=4'b0011 << address[1:0];
          2:strobes=4'b1111;
          default:illegal=1;
        endcase
        if((funct3==1 && address[0]) || (funct3==2 && |address[1:0]))begin exception=1;cause=6;end
      end
      7'h13: begin
        write_rd=1;
        case(funct3)
          0:result=a+imm_i;
          2:result={31'b0,$signed(a)<$signed(imm_i)};
          3:result={31'b0,a<imm_i};
          4:result=a^imm_i;
          6:result=a|imm_i;
          7:result=a&imm_i;
          1:begin result=a << insn[24:20];if(funct7!=0)illegal=1;end
          5:begin
            if(funct7==0)result=a >> insn[24:20];
            else if(funct7==7'h20)result=$signed(a) >>> insn[24:20];
            else illegal=1;
          end
          default:illegal=1;
        endcase
      end
      7'h33: begin
        write_rd=1;
        if(funct7!=0 && !(funct7==7'h20 && (funct3==0 || funct3==5)))illegal=1;
        case(funct3)
          0:result=funct7==7'h20 ? a-b : a+b;
          1:result=a << b[4:0];
          2:result={31'b0,$signed(a)<$signed(b)};
          3:result={31'b0,a<b};
          4:result=a^b;
          5:begin
            if(funct7==7'h20)result=$signed(a) >>> b[4:0];
            else result=a >> b[4:0];
          end
          6:result=a|b;
          7:result=a&b;
          default:illegal=1;
        endcase
      end
      7'h0f: if(funct3!=0)illegal=1; // base FENCE, in-order memory needs no action
      7'h73: begin
        exception=1;
        if(insn==32'h00000073)cause=11;
        else if(insn==32'h00100073)cause=3;
        else illegal=1;
      end
      default:illegal=1;
    endcase
    if(taken && |next_pc[1:0])begin exception=1;cause=0;end
    if(illegal)begin exception=1;cause=2;end
    if(|pc[1:0])begin exception=1;cause=0;end
  end
  integer index;
  always @(posedge clk) begin
    retire_valid<=0;
    if(reset)begin
      pc<=0;trapped<=0;trap_cause<=0;trap_pc<=0;
      retire_pc<=0;retire_insn<=0;retire_data<=0;retire_rd<=0;
      for(index=0;index<32;index=index+1)regs[index]<=0;
    end else if(!trapped)begin
      if(exception)begin trapped<=1;trap_cause<=cause;trap_pc<=pc;end
      else begin
        pc<=next_pc;
        if(write_rd && rd!=0)regs[rd]<=result;
        retire_valid<=1;retire_pc<=pc;retire_insn<=insn;
        retire_rd<=write_rd ? rd : 5'b0;
        retire_data<=write_rd && rd!=0 ? result : 32'b0;
      end
    end
  end
endmodule
