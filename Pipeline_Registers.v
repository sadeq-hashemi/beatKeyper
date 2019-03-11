module IF_ID(rst_check, clk, rst, inst_in, pc_in, inst_out, pc_out, write_enable);
  input clk, rst, write_enable;
  input [15:0] inst_in, pc_in;
  output rst_check;
  output [15:0] inst_out, pc_out;  
  Register inst_reg(.clk(clk), .rst(rst), .D(inst_in), .WriteReg(write_enable), .ReadEnable1(1'b1), .Readenable2(1'b0), .Bitline1(inst_out), .Bitline2());
  Register pc_reg(.clk(clk), .rst(rst), .D(pc_in), .WriteReg(write_enable), .ReadEnable1(1'b1), .Readenable2(1'b0), .Bitline1(pc_out), .Bitline2());
 
  BitCell rstcheck_reg(.clk(clk), .rst(rst), .D(1'b1), .WriteEnable(1'b1), .ReadEnable1(1'b1), .ReadEnable2(1'b0), .Bitline1(rst_check), .Bitline2());

endmodule

module ID_EX(clk, rst, inst_in, pc_in, inst_out, pc_out, read1_in, read2_in, read1_out, read2_out, sign_in, sign_out, 
			 RegDst, Branch, MemRead, MemtoReg, ALUOp, MemWrite, ALUSrc, RegWrite, RegDst_out, Branch_out, MemRead_out, 
			 MemtoReg_out, MemWrite_out, ALUSrc_out, RegWrite_out,  ALUOp_out, read1_num, read2_num, read1_num_out, read2_num_out, write_enable);
  input clk, rst, write_enable;
  input RegDst, Branch, MemRead, MemtoReg, MemWrite, ALUSrc, RegWrite;
  input [3:0] ALUOp, read1_num, read2_num;
  input [15:0] inst_in, pc_in, read1_in, read2_in, sign_in;
  
  output RegDst_out, Branch_out, MemRead_out, MemtoReg_out, MemWrite_out, ALUSrc_out, RegWrite_out;
  output [3:0] ALUOp_out, read1_num_out, read2_num_out;
  output [15:0] inst_out, pc_out, read1_out, read2_out, sign_out;
  
  wire [15:0] ALUOut,read1_num_16_out, read2_num_16_out;

  Register inst_reg(.clk(clk), .rst(rst), .D(inst_in), .WriteReg(write_enable), .ReadEnable1(1'b1), .Readenable2(1'b0), .Bitline1(inst_out), .Bitline2());
  Register pc_reg(.clk(clk), .rst(rst), .D(pc_in), .WriteReg(write_enable), .ReadEnable1(1'b1), .Readenable2(1'b0), .Bitline1(pc_out), .Bitline2());
 
  Register read1_reg(.clk(clk), .rst(rst), .D(read1_in), .WriteReg(write_enable), .ReadEnable1(1'b1), .Readenable2(1'b0), .Bitline1(read1_out), .Bitline2());
  Register read2_reg(.clk(clk), .rst(rst), .D(read2_in), .WriteReg(write_enable), .ReadEnable1(1'b1), .Readenable2(1'b0), .Bitline1(read2_out), .Bitline2());
  Register sign_reg(.clk(clk), .rst(rst), .D(sign_in), .WriteReg(write_enable), .ReadEnable1(1'b1), .Readenable2(1'b0), .Bitline1(sign_out), .Bitline2());

  BitCell regdst_reg(.clk(clk), .rst(rst), .D(RegDst), .WriteEnable(write_enable), .ReadEnable1(1'b1), .ReadEnable2(1'b0), .Bitline1(RegDst_out), .Bitline2());
  BitCell branch_reg(.clk(clk), .rst(rst), .D(Branch), .WriteEnable(write_enable), .ReadEnable1(1'b1), .ReadEnable2(1'b0), .Bitline1(Branch_out), .Bitline2());
  BitCell memread_reg(.clk(clk), .rst(rst), .D(MemRead), .WriteEnable(write_enable), .ReadEnable1(1'b1), .ReadEnable2(1'b0), .Bitline1(MemRead_out), .Bitline2());
  BitCell memtoreg_reg(.clk(clk), .rst(rst), .D(MemtoReg), .WriteEnable(write_enable), .ReadEnable1(1'b1), .ReadEnable2(1'b0), .Bitline1(MemtoReg_out), .Bitline2());
  BitCell memwrite_reg(.clk(clk), .rst(rst), .D(MemWrite), .WriteEnable(write_enable), .ReadEnable1(1'b1), .ReadEnable2(1'b0), .Bitline1(MemWrite_out), .Bitline2());
  BitCell alusrc_reg(.clk(clk), .rst(rst), .D(ALUSrc), .WriteEnable(write_enable), .ReadEnable1(1'b1), .ReadEnable2(1'b0), .Bitline1(ALUSrc_out), .Bitline2());
  BitCell regwrite_reg(.clk(clk), .rst(rst), .D(RegWrite), .WriteEnable(write_enable), .ReadEnable1(1'b1), .ReadEnable2(1'b0), .Bitline1(RegWrite_out), .Bitline2());
  //using a 16 bit reg but only really need 4
  Register aluop_reg(.clk(clk), .rst(rst), .D({12'b0, ALUOp[3:0]}), .WriteReg(write_enable), .ReadEnable1(1'b1), .Readenable2(1'b0), .Bitline1(ALUOut), .Bitline2());
  Register read1_num_reg(.clk(clk), .rst(rst), .D({12'b0, read1_num[3:0]}), .WriteReg(write_enable), .ReadEnable1(1'b1), .Readenable2(1'b0), .Bitline1(read1_num_16_out), .Bitline2());
  Register read2_num_reg(.clk(clk), .rst(rst), .D({12'b0, read2_num[3:0]}), .WriteReg(write_enable), .ReadEnable1(1'b1), .Readenable2(1'b0), .Bitline1(read2_num_16_out), .Bitline2()); 
 assign ALUOp_out = ALUOut[3:0]; //we only want lower 4 bits
 assign read1_num_out = read1_num_16_out[3:0]; //we only want lower 4 bits
 assign read2_num_out = read2_num_16_out[3:0]; //we only want lower 4 bits

 endmodule

module EX_MEM(clk, rst, inst_in, pc_in, inst_out, pc_out, read1_in, read2_in, read1_out, read2_out, flag_in, flag_out, alu_in, alu_out, 
				RegWrite, MemToReg, RegWrite_out, MemToReg_out, MemRead, MemWrite, MemRead_out ,MemWrite_out, Branch, Branch_out, write_enable);
  input clk, rst, write_enable;
  input RegWrite, MemToReg, MemWrite, MemRead, Branch;
  input [15:0] inst_in, pc_in, read1_in, read2_in, alu_in;
  input [2:0] flag_in;

  output RegWrite_out, MemToReg_out, MemWrite_out, MemRead_out, Branch_out;
  output [2:0] flag_out;
  output [15:0] inst_out, pc_out, read1_out, read2_out, alu_out;
  
  BitCell memread_reg(.clk(clk), .rst(rst), .D(MemRead), .WriteEnable(write_enable), .ReadEnable1(1'b1), .ReadEnable2(1'b0), .Bitline1(MemRead_out), .Bitline2());
  BitCell memtoreg_reg(.clk(clk), .rst(rst), .D(MemToReg), .WriteEnable(write_enable), .ReadEnable1(1'b1), .ReadEnable2(1'b0), .Bitline1(MemToReg_out), .Bitline2());
  BitCell memwrite_reg(.clk(clk), .rst(rst), .D(MemWrite), .WriteEnable(write_enable), .ReadEnable1(1'b1), .ReadEnable2(1'b0), .Bitline1(MemWrite_out), .Bitline2());
  BitCell regwrite_reg(.clk(clk), .rst(rst), .D(RegWrite), .WriteEnable(write_enable), .ReadEnable1(1'b1), .ReadEnable2(1'b0), .Bitline1(RegWrite_out), .Bitline2());
  BitCell branch_reg(.clk(clk), .rst(rst), .D(Branch), .WriteEnable(write_enable), .ReadEnable1(1'b1), .ReadEnable2(1'b0), .Bitline1(Branch_out), .Bitline2());

  Register alu_reg(.clk(clk), .rst(rst), .D(alu_in), .WriteReg(write_enable), .ReadEnable1(1'b1), .Readenable2(1'b0), .Bitline1(alu_out), .Bitline2());
  Register inst_reg(.clk(clk), .rst(rst), .D(inst_in), .WriteReg(write_enable), .ReadEnable1(1'b1), .Readenable2(1'b0), .Bitline1(inst_out), .Bitline2());
  Register pc_reg(.clk(clk), .rst(rst), .D(pc_in), .WriteReg(write_enable), .ReadEnable1(1'b1), .Readenable2(1'b0), .Bitline1(pc_out), .Bitline2());
  Register read1_reg(.clk(clk), .rst(rst), .D(read1_in), .WriteReg(write_enable), .ReadEnable1(1'b1), .Readenable2(1'b0), .Bitline1(read1_out), .Bitline2());
  Register read2_reg(.clk(clk), .rst(rst), .D(read2_in), .WriteReg(write_enable), .ReadEnable1(1'b1), .Readenable2(1'b0), .Bitline1(read2_out), .Bitline2());
  Register_3Bit FLAG_REG(.clk(clk), .rst(rst), .D(flag_in), .WriteReg({3{write_enable}}), .ReadEnable1(1'b1), .Readenable2(1'b0), .Bitline1(flag_out), .Bitline2());
 endmodule


module MEM_WB(clk, rst, inst_in, inst_out, alu_in, data_mem_in, branch_pc_in, alu_out, data_mem_out, branch_pc_out, 
				RegWrite, MemtoReg, RegWrite_out, MemtoReg_out, pc_next_in, pc_next_out, write_enable);
  
  input RegWrite, MemtoReg, write_enable;
  input clk, rst;
  input [15:0] alu_in, data_mem_in, branch_pc_in, inst_in, pc_next_in;
  
  output [15:0] alu_out, data_mem_out, branch_pc_out, inst_out, pc_next_out;
  output RegWrite_out, MemtoReg_out;
  
  BitCell memtoreg_reg(.clk(clk), .rst(rst), .D(MemtoReg), .WriteEnable(write_enable), .ReadEnable1(1'b1), .ReadEnable2(1'b0), .Bitline1(MemtoReg_out), .Bitline2());
  BitCell regwrite_reg(.clk(clk), .rst(rst), .D(RegWrite), .WriteEnable(write_enable), .ReadEnable1(1'b1), .ReadEnable2(1'b0), .Bitline1(RegWrite_out), .Bitline2());

  Register alu_data(.clk(clk), .rst(rst), .D(alu_in), .WriteReg(write_enable), .ReadEnable1(1'b1), .Readenable2(1'b0), .Bitline1(alu_out), .Bitline2());
  Register data_mem(.clk(clk), .rst(rst), .D(data_mem_in), .WriteReg(write_enable), .ReadEnable1(1'b1), .Readenable2(1'b0), .Bitline1(data_mem_out), .Bitline2());
  Register branch_pc(.clk(clk), .rst(rst), .D(branch_pc_in), .WriteReg(write_enable), .ReadEnable1(1'b1), .Readenable2(1'b0), .Bitline1(branch_pc_out), .Bitline2());
  Register inst_reg(.clk(clk), .rst(rst), .D(inst_in), .WriteReg(write_enable), .ReadEnable1(1'b1), .Readenable2(1'b0), .Bitline1(inst_out), .Bitline2());
  Register pc_next_reg(.clk(clk), .rst(rst), .D(pc_next_in), .WriteReg(write_enable), .ReadEnable1(1'b1), .Readenable2(1'b0), .Bitline1(pc_next_out), .Bitline2());
endmodule
