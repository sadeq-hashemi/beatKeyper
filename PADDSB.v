module PADDSB(alu_in1, alu_in2, PADDSB_Out);

input [15:0] alu_in1, alu_in2;
wire [3:0] para1, para2, para3, para4;
wire para1_ovfl, para2_ovfl, para3_ovfl, para4_ovfl;
wire [3:0] para1_sat, para2_sat, para3_sat, para4_sat;
output [15:0] PADDSB_Out;

// PADDSB Logic
four_bit_ripple_carry PADDSB_adder1(alu_in1[3:0], alu_in2[3:0], 1'b0, para1, , para1_ovfl);
four_bit_ripple_carry PADDSB_adder2(alu_in1[7:4], alu_in2[7:4], 1'b0, para2, , para2_ovfl);
four_bit_ripple_carry PADDSB_adder3(alu_in1[11:8], alu_in2[11:8], 1'b0, para3, , para3_ovfl);
four_bit_ripple_carry PADDSB_adder4(alu_in1[15:12], alu_in2[15:12], 1'b0, para4, , para4_ovfl);

assign para1_sat = ((alu_in1[3] == 0) && (alu_in2[3] == 0)) ? para1_ovfl ? 4'h7 : para1 : // overflow
                   ((alu_in1[3] == 1) && (alu_in2[3] == 1)) ? para1_ovfl ? 4'h8 : para1 : para1; // underflow 

assign para2_sat = ((alu_in1[7] == 0) && (alu_in2[7] == 0)) ? para2_ovfl ? 4'h7 : para2 :  // overflow
                   ((alu_in1[7] == 1) && (alu_in2[7] == 1)) ? para2_ovfl ? 4'h8 : para2 : para2; // underflow 

assign para3_sat = ((alu_in1[11] == 0) && (alu_in2[11] == 0)) ? para3_ovfl ? 4'h7 : para3 :  // overflow
		   ((alu_in1[11] == 1) && (alu_in2[11] == 1)) ? para3_ovfl ? 4'h8 : para3 : para3; // underflow 

assign para4_sat = ((alu_in1[15] == 0) && (alu_in2[15] == 0)) ? para4_ovfl ? 4'h7 : para4 : // overflow
	           ((alu_in1[15] == 1) && (alu_in2[15] == 1)) ? para4_ovfl ? 4'h8 : para4 : para4; // underflow 

assign PADDSB_Out = {para4_sat, para3_sat, para2_sat, para1_sat};

endmodule
