module Rotator (ror_out, ror_in, ror_val);

input [15:0] ror_in; //This is the number to perform shift operation on
input [3:0] ror_val; //Shift amount (used to shift the ?Shift_In?)
wire [15:0] ROR_1, ROR_2, ROR_3, ROR_Fin;
output [15:0] ror_out; //Shifter value

// For ROR,bits are rotated off the right end are inserted into the vacated bit positions on the left.

assign ROR_1 = ror_val[0] ? ({ ror_in[0], ror_in[15:1]}) : (ror_in);
assign ROR_2 = ror_val[1] ? ({ ROR_1[1:0], ROR_1[15:2]}) : (ROR_1);
assign ROR_3 = ror_val[2] ? ({ ROR_2[3:0], ROR_2[15:4]}) : (ROR_2);
assign ROR_Fin = ror_val[3] ? ({ ROR_3[7:0], ROR_3[15:8]}) : (ROR_3);

assign ror_out = ROR_Fin;

endmodule