//#####################################################################################################################
//Branch instruction
// B type and Br type share same logic
module B_inst  (input op, input [2:0]c, input [8:0] i, input [2:0] f, input[15:0] rs_val, input [15:0] PC_in, output [15:0]PC_out, output branch_taken);

wire [15:0]not_taken;
wire [15:0] taken_B;
wire [15:0] taken_Br;
wire [15:0] taken;
wire err, err2; 
wire [15:0] shifted_PC;
wire [15:0] shifted_i; 
wire N, V, Z; 

//f[2] = N f[1]=  V f[0] = Z
assign N = f[2];
assign V = f[1];
assign Z = f[0];

addsub_16bit PC_add(.A(PC_in), .B(16'h2), .sub(1'b0), .sum(shifted_PC), .ovfl(err)); //(PC + 2) 

Shifter i_shift(.Shift_In({{7{i[8]}},i[8:0]}), .Shift_Val(4'h1), .Mode(1'b0), .Shift_Out(shifted_i)); // I << 1  

assign not_taken = shifted_PC; //not_taken = PC + 2

addsub_16bit add(.A(shifted_PC), .B(shifted_i), .sub(1'b0), .sum(taken_B), .ovfl(err2)); //taken = (PC + 2) + (I << 1)
assign taken_Br = rs_val; 
assign taken = op ? taken_Br : taken_B;
assign PC_out = c[2] ? 
		  c[1] ?
		     c[0] ?
		       taken : //C = 111 (unconditional)
		       V ? taken : not_taken : //c = 110 (overflow)
		     c[0] ? 
	 	       N | Z ? taken : not_taken : //c = 101 (less than or equal to)
		       Z | (~Z & ~N) ? taken : not_taken : //c = 100 (greater than or equal to)
		  c[1] ?
		    c[0] ? 
		      N ? taken : not_taken : //c = 011 (less than)
		      (~Z & ~N) ? taken : not_taken : //c = 010  (greater than)
		    c[0] ?
		      Z ? taken : not_taken : //c = 001 (equal)
		      ~Z ? taken : not_taken; //c = 000 (not equal)

assign branch_taken = c[2] ? 
		  c[1] ?
		     c[0] ?
		       1'b1 : //C = 111 (unconditional)
		       V ? 1'b1 : 1'b0 : //c = 110 (overflow)
		     c[0] ? 
	 	       N | Z ? 1'b1 : 1'b0 : //c = 101 (less than or equal to)
		       Z | (~Z & ~N) ? 1'b1 : 1'b0 : //c = 100 (greater than or equal to)
		  c[1] ?
		    c[0] ? 
		      N ? 1'b1 : 1'b0 : //c = 011 (less than)
		      (~Z & ~N) ? 1'b1 : 1'b0 : //c = 010  (greater than)
		    c[0] ?
		      Z ? 1'b1 : 1'b0 : //c = 001 (equal)
		      ~Z ? 1'b1 : 1'b0; //c = 000 (not equal)
endmodule

//#####################################################################################################################
//PC_control 
module PC_control_phase1 (input[15:0] inst, input[2:0] FLAG, input[15:0] PC_in,
                           input[15:0] rd_val, input[15:0] rs_val, output[15:0] PC_out, output wr, output[15:0] wr_val, output branch_taken);

wire err;
wire [3:0] opcode; //global opcode
wire [2:0] cond; //ccc for B and BR
wire [3:0] rs; //register rs for BR
wire [3:0] rd; //register rd for PCS
wire [8:0] imm; //immediate for B 
wire [15:0] PC_B_Br, PC_PCS, PC_HLT;
wire took_branch;
assign opcode = inst[15:12];
assign cond = inst[11:9];
assign rs = inst[7:4];
assign rd = inst[11:8];
assign imm = inst[8:0];

B_inst  BandBr(.op(opcode[0]), .c(cond), .i(imm), .f(FLAG), .rs_val(rs_val), .PC_in(PC_in), .PC_out(PC_B_Br), .branch_taken(took_branch)); //how do i get RS_val?
addsub_16bit PC_add(.A(PC_in), .B(16'h2), .sub(1'b0), .sum(PC_PCS), .ovfl(err)); //PC_pcs = (PC_in + 2)
assign PC_HLT = PC_in; //PC_HLT = PC_in
assign branch_taken = took_branch;
//assuming opcode[3] == 1, opcode[2] == 1
// if opcode[1] == 1 then PCS (opcode[0] == 0) or HALT(opcode[0] == 1)
// if opcode[1] == 0 then take B_andBr
assign PC_out = (opcode == 4'b1100 | opcode == 4'b1101) ? PC_B_Br: //branch or BR
			 	(opcode == 4'b1111) ? PC_HLT : //halt
				 PC_PCS;


assign wr = (opcode == 4'b1110) ? 1'b1 :
			 1'b0;    

assign  wr_val = (opcode == 4'b1110) ? PC_PCS :
			 	 16'h0;  
               
endmodule











 