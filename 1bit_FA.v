module full_adder_1bit (A, B, Cin, S, Cout);

input A, B, Cin;
output S, Cout;

assign S = A ^ B ^ Cin;
assign Cout = (A & B) | (B & Cin) | (A & Cin);

endmodule


// 4-bit ripple carry adder
module adder_16bit(A, B, sub, Sum, Ovfl);

input [15:0] A, B;
input sub;

wire [16:1] Cout;
wire [15:0] B_xor;
output [15:0] Sum;
output Ovfl;

xor (B_xor[0], B[0], sub);
xor (B_xor[1], B[1], sub);
xor (B_xor[2], B[2], sub);
xor (B_xor[3], B[3], sub);
xor (B_xor[4], B[4], sub);
xor (B_xor[5], B[5], sub);
xor (B_xor[6], B[6], sub);
xor (B_xor[7], B[7], sub);
xor (B_xor[8], B[8], sub);
xor (B_xor[9], B[9], sub);
xor (B_xor[10], B[10], sub);
xor (B_xor[11], B[11], sub);
xor (B_xor[12], B[12], sub);
xor (B_xor[13], B[13], sub);
xor (B_xor[14], B[14], sub);

full_adder_1bit FA1 (A[0],B_xor[0], sub, Sum[0], Cout[1]);
full_adder_1bit FA2 (A[1],B_xor[1], Cout[1], Sum[1], Cout[2]);
full_adder_1bit FA3 (A[2],B_xor[2], Cout[2], Sum[2], Cout[3]);
full_adder_1bit FA4 (A[3],B_xor[3], Cout[3], Sum[3], Cout[4]);
full_adder_1bit FA5 (A[4],B_xor[4], Cout[4], Sum[4], Cout[5]);
full_adder_1bit FA6 (A[5],B_xor[5], Cout[5], Sum[5], Cout[6]);
full_adder_1bit FA7 (A[6],B_xor[6], Cout[6], Sum[6], Cout[7]);
full_adder_1bit FA8 (A[7],B_xor[7], Cout[7], Sum[7], Cout[8]);
full_adder_1bit FA9 (A[8],B_xor[8], Cout[8], Sum[8], Cout[9]);
full_adder_1bit FA10 (A[9],B_xor[9], Cout[9], Sum[9], Cout[10]);
full_adder_1bit FA11 (A[10],B_xor[10], Cout[10], Sum[10], Cout[11]);
full_adder_1bit FA12 (A[11],B_xor[11], Cout[11], Sum[11], Cout[12]);
full_adder_1bit FA13 (A[12],B_xor[12], Cout[12], Sum[12], Cout[13]);
full_adder_1bit FA14 (A[13],B_xor[13], Cout[13], Sum[13], Cout[14]);
full_adder_1bit FA15 (A[14],B_xor[14], Cout[14], Sum[14], Cout[15]);

assign Ovfl = Cout[14] ^ Cout[15];

endmodule
