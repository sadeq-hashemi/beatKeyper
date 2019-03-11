module red (alu_in1, alu_in2, out);

input [15:0] alu_in1, alu_in2;
output [15:0] out;
wire [3:0] red1_out, red2_out, red3_out, red4_out, red_accum1_out, red_accum2_out, red_accum_final_out;
wire [3:0] red1, red2, red3, red4, red_accum1, red_accum2, red_accum_final;


// RED Calculation logic
four_bit_ripple_carry red_add1 (alu_in1[3:0], alu_in2[3:0], 1'b0, red1, ,);
four_bit_ripple_carry red_add2 (alu_in1[7:4], alu_in2[7:4], 1'b0, red2, ,);
four_bit_ripple_carry red_add3 (alu_in1[11:8], alu_in2[11:8], 1'b0, red3, ,);
four_bit_ripple_carry red_add4 (alu_in1[15:12], alu_in2[15:12], 1'b0, red4, ,);
four_bit_ripple_carry red_add5 (red1, red2, 1'b0, red_accum1, ,);
four_bit_ripple_carry red_add6 (red3, red4, 1'b0, red_accum2, ,);
four_bit_ripple_carry red_add7 (red_accum1, red_accum2, 1'b0, red_accum_final, ,);

assign red1_out = red1;
assign red2_out = red2;
assign red3_out = red3;
assign red4_out = red4;
assign red_accum1_out = red_accum1;
assign red_accum2_out = red_accum2;
assign red_accum_final_out = red_accum_final;
//assign out = ({{ 12{ red_accum_final[3]}},  red_accum_final[3:0]}); //WE THOUGHT THIS WAS FOR SIGN EXTENDING
assign out = ({ 12'b0,  red_accum_final[3:0]});
endmodule