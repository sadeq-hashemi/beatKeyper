module full_adder_1bit(A, B, Cin, S, Cout);

input A, B, Cin;
output S, Cout;

assign S = A ^ B ^ Cin;
assign Cout = (A & B) | (B & Cin) | (A & Cin);

endmodule


//----------------------------------------------------------------------------------------------------------------
module addsub_4bit ( A, B, sub, sum, ovfl);
input [3:0] A, B; //Input values
input sub; // add-sub indicatoroutput

wire [3:0] B2; 
wire [3:0]cin;
wire cout;
output [3:0] sum; //sum output
output ovfl; //To indicate overflow

assign B2[0] = sub ^ B[0]; // addition: B XOR 0 = B	substraction B XOR 1 = ~B
assign B2[1] = sub ^ B[1];
assign B2[2] = sub ^ B[2];
assign B2[3] = sub ^ B[3];
assign cin[0] = sub; //1 if substraction



full_adder_1bit FA1 (A[0], B2[0], cin[0], sum[0], cin[1] ); //Example of using the one bit full adder (which you must also design)
full_adder_1bit FA2 (A[1], B2[1], cin[1], sum[1], cin[2]);
full_adder_1bit FA3 (A[2], B2[2], cin[2], sum[2], cin[3]);
full_adder_1bit FA4 (A[3], B2[3], cin[3], sum[3], cout);

// sol1:There has been overflow in the addition of two n-bit two's complement
// numbers when the sign of the two operands are the same and the sign
// of the sum is different.
// sol2: The OVERFLOW flag is the XOR of the carry coming into the sign bit
// (if any) with the carry going out of the sign bit (if any)
assign ovfl = A[3]!= B2[3]? 0: 
		A[3] == sum[3] ? 0 : 1;

endmodule

//----------------------------------------------------------------------------------------------------------------
module addsub_16bit ( A, B, sub, sum, ovfl);
input [15:0] A, B; //Input values
input sub; // add-sub indicatoroutput

wire [15:0] B2; 
wire [15:0]cin;
wire cout;
output [15:0] sum; //sum output
output ovfl; //To indicate overflow

assign B2[0] = sub ^ B[0]; // addition: B XOR 0 = B	substraction B XOR 1 = ~B
assign B2[1] = sub ^ B[1];
assign B2[2] = sub ^ B[2];
assign B2[3] = sub ^ B[3];

assign B2[4] = sub ^ B[4]; // addition: B XOR 0 = B	substraction B XOR 1 = ~B
assign B2[5] = sub ^ B[5];
assign B2[6] = sub ^ B[6];
assign B2[7] = sub ^ B[7];

assign B2[8] = sub ^ B[8]; // addition: B XOR 0 = B	substraction B XOR 1 = ~B
assign B2[9] = sub ^ B[9];
assign B2[10] = sub ^ B[10];
assign B2[11] = sub ^ B[11];

assign B2[12] = sub ^ B[12]; // addition: B XOR 0 = B	substraction B XOR 1 = ~B
assign B2[13] = sub ^ B[13];
assign B2[14] = sub ^ B[14];
assign B2[15] = sub ^ B[15];
assign cin[0] = sub; //1 if substraction



full_adder_1bit FA1 (A[0], B2[0], cin[0], sum[0], cin[1] ); //Example of using the one bit full adder (which you must also design)
full_adder_1bit FA2 (A[1], B2[1], cin[1], sum[1], cin[2]);
full_adder_1bit FA3 (A[2], B2[2], cin[2], sum[2], cin[3]);
full_adder_1bit FA4 (A[3], B2[3], cin[3], sum[3], cin[4]);

full_adder_1bit FA5 (A[4], B2[4], cin[4], sum[4], cin[5] ); //Example of using the one bit full adder (which you must also design)
full_adder_1bit FA6 (A[5], B2[5], cin[5], sum[5], cin[6]);
full_adder_1bit FA7 (A[6], B2[6], cin[6], sum[6], cin[7]);
full_adder_1bit FA8 (A[7], B2[7], cin[7], sum[7], cin[8]);

full_adder_1bit FA9 (A[8], B2[8], cin[8], sum[8], cin[9] ); //Example of using the one bit full adder (which you must also design)
full_adder_1bit FA10 (A[9], B2[9], cin[9], sum[9], cin[10]);
full_adder_1bit FA11 (A[10], B2[10], cin[10], sum[10], cin[11]);
full_adder_1bit FA12 (A[11], B2[11], cin[11], sum[11], cin[12]);

full_adder_1bit FA13 (A[12], B2[12], cin[12], sum[12], cin[13] ); //Example of using the one bit full adder (which you must also design)
full_adder_1bit FA14 (A[13], B2[13], cin[13], sum[13], cin[14]);
full_adder_1bit FA15 (A[14], B2[14], cin[14], sum[14], cin[15]);
full_adder_1bit FA16 (A[15], B2[15], cin[15], sum[15], cout);

// sol1:There has been overflow in the addition of two n-bit two's complement
// numbers when the sign of the two operands are the same and the sign
// of the sum is different.
// sol2: The OVERFLOW flag is the XOR of the carry coming into the sign bit
// (if any) with the carry going out of the sign bit (if any)
/*assign ovfl =  A[3] ^ B[3] ? 1'b0 : 
		 A[3] & B[3] ? ~sum[3] : sum[3];*/
assign ovfl = A[15]!= B2[15]? 0: 
		A[15] == sum[15] ? 0 : 1;

endmodule