module Control(rst, select, RegDst, Branch, MemRead, MemtoReg, ALUOp, MemWrite, ALUSrc, RegWrite);
  input [3:0] select; //this corresponds to bits [15:12] of the INST
  input rst; //we watch to see if the registers get reset, if they do we will keep the controls to 0 
  output RegDst, Branch, MemRead, MemtoReg, MemWrite, ALUSrc, RegWrite;
  output [3:0] ALUOp;

  // values for Opcodes
  localparam ADD = 4'b0000;
  localparam SUB = 4'b0001;
  localparam RED = 4'b0010;
  localparam XOR = 4'b0011;
  localparam SLL = 4'b0100;
  localparam SRA = 4'b0101;
  localparam ROR = 4'b0110;
  localparam PADDSB = 4'b0111;

  localparam LW = 4'b1000;
  localparam SW = 4'b1001;
  localparam LHB = 4'b1010;
  localparam LLB = 4'b1011;

  localparam B = 4'b1100;
  localparam BR = 4'b1101;
  localparam PCS = 4'b1110;
  localparam HLT = 4'b1111;

  assign MemWrite = (select == SW) ? 1 : 0; 
  assign MemRead = (select == LW) ? 1 : 0; 
  assign RegWrite = (rst != 1'b1) ? 0 : (select == SW | select == B | select == BR | select == HLT) ? 0 : 1; //those 4 opcodes do not write
  assign Branch = (select == B | select == BR) ? 1 : 0;
  assign MemtoReg = (select == LW | select == LHB | select == LLB) ? 1 : 0;//which output are we writing back?
  assign ALUSrc = (select == SLL | select == SRA | select == ROR | select == LW | select == SW ) ? 1 : 0; //NEED TO ADD ALU OPS

  assign ALUOp = (select == LW | select == SW) ? 4'b0000 : select[3:0]; //select[2:0] will pass lower 3 bits, which is all that matters for add sub red ,etc.

endmodule


