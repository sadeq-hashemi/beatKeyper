module ALU (clk, rst, alu_out, alu_in1, alu_in2, Opcode, Flag);

// Assume ALU_In2 to be the shift operand
input [15:0] alu_in1, alu_in2;
input [3:0] Opcode; 
input clk, rst;

wire Ovfl, Zero, Negative;
wire [3:0] red1, red2, red3, red4, red_accum1, red_accum2;
wire [15:0] RED_Out;
wire  cla_cout;
wire [15:0] cla_sum;
wire  cla_ovfl;
wire [15:0] Adder_Out_Sat;
wire [15:0] Shifter_Out;
wire [15:0] Rotator_Out;
wire [15:0] PADDSB_Out;
wire [15:0] sat_pos;
wire [15:0] sat_neg;
wire [2:0] flag_reg_in;
wire [2:0] flag_write; //used to let the reg know which flags need to be updated
output [15:0] alu_out;

// Bit order of the flag is N, V, Z
output [2:0] Flag;

// values for Opcodes
localparam ADD = 4'b0000;
localparam SUB = 4'b0001;
localparam RED = 4'b0010;
localparam XOR = 4'b0011;
localparam SLL = 4'b0100;
localparam SRA = 4'b0101;
localparam ROR = 4'b0110;
localparam PADDSB = 4'b0111;
localparam LHB = 4'b1010;
localparam LLB = 4'b1011;

// CLA Adder
CLA_Adder cla_adder(.a(alu_in1), .b(alu_in2), .sub(Opcode[0]), .cout(cla_cout), .sum(cla_sum), .ovfl(cla_ovfl));

// PADDSB Logic
PADDSB pad(.alu_in1(alu_in1), .alu_in2(alu_in2), .PADDSB_Out(PADDSB_Out));

// module Shifter (Shift_Out, Shift_In, Shift_Val, Mode);
Shifter shifter(Shifter_Out, alu_in1, alu_in2[3:0], Opcode[0]);

// module Rotator (ror_out, ror_in, ror_val);
Rotator rotator(.ror_out(Rotator_Out), .ror_in(alu_in1), .ror_val(alu_in2[3:0]));

// RED logic
red red(.alu_in1(alu_in1), .alu_in2(alu_in2), .out(RED_Out));

assign sat_pos = (alu_in1[15] == 1'b0 & alu_in2[15] == 1'b0) ? 16'h7FFF : 16'h8000;
assign sat_neg = (alu_in1[15] == 1'b0 & alu_in2[15] == 1'b1) ? 16'h7FFF : 16'h8000;
// output choosing logic
assign alu_out = Opcode==ADD ? 
					(cla_ovfl == 0 ? cla_sum : sat_pos) :
       			Opcode==SUB ? (cla_ovfl == 0 ? cla_sum : sat_neg) :
			 	Opcode==RED ? RED_Out: 
       			Opcode==XOR ? alu_in1 ^ alu_in2 : 
			 	Opcode==SLL ? Shifter_Out :
			 	Opcode==SRA ? Shifter_Out : 
		 		Opcode==ROR ? Rotator_Out : 
		 		Opcode==PADDSB ? PADDSB_Out: 
				Opcode == LHB ? alu_in2:
				Opcode == LLB ? alu_in2: 16'b0;

// PADDSB logic
/*
The PADDSBinstruction  performs  four  half-byte  additions  in  parallel  to  realize sub-word  parallelism. 
Specifically, each ofthe four half bytes (4-bits) will be treated as separate numbers stored in a single word as  a  byte  vector. 
When  PADDSB  is  performed,  the  four  numbers  will  be  added  separately.  To  be  more specific, let the contents in rs and rt are aaaa_bbbb_cccc_dddd, 
eeee_ffff_gggg_hhhh respectively where a, b, c, d, e, f, g, and h in {0, 1}. Then after execution of PADDSB, 
the content of rd will be {sat(aaaa+eeee), sat(bbbb+ffff),  sat(cccc+gggg),  sat(dddd+hhhh)}.  The  four  half-bytes  of  result  should  be  saturated separately, 
meaning if a result exceeds the most positive number (2^3-1) then the result is saturated to (2^3-1), 
and if the result were to underflow the most negative number (-2^3) then the result would be saturated to ?2^3.
*/

// Flag logic

// TODO: set flag logic based on opcode
assign Zero = Opcode == ADD ? alu_out == 0 ? 1'b1 : 0 : 
              Opcode == SUB ? alu_out == 0 ? 1'b1 : 0 : 
              Opcode == XOR ? alu_out == 0 ? 1'b1 : 0 : 
              Opcode == SLL ? alu_out == 0 ? 1'b1 : 0 : 
              Opcode == SRA ? alu_out == 0 ? 1'b1 : 0 : 
              Opcode == ROR ? alu_out == 0 ? 1'b1 : 0 : 0;
	      

assign Negative = Opcode == ADD ? (cla_sum[15] == 1) ? 1'b1 : 0 :
		  Opcode == SUB ? (cla_sum[15] == 1) ? 1'b1 : 0 : 0;

assign flag_reg_in = {Negative, cla_ovfl, Zero};
assign flag_write = Opcode == ADD ?  3'b111 : 
              Opcode == SUB ? 3'b111 : 
              Opcode == XOR ? 3'b001 : 
              Opcode == SLL ? 3'b001 : 
              Opcode == SRA ? 3'b001 : 
              Opcode == ROR ?  3'b001 : 3'b000;

Register_3Bit FLAG_REG(.clk(clk), .rst(rst), .D(flag_reg_in), .WriteReg(flag_write), .ReadEnable1(1'b1), .Readenable2(1'b0), .Bitline1(Flag), .Bitline2());

 
endmodule
