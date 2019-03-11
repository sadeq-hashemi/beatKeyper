module full_adder_1bit (A, B, Cin, S, Cout);

input A, B, Cin;
output S, Cout;

assign S = A ^ B ^ Cin;
assign Cout = (A & B) | (B & Cin) | (A & Cin);

endmodule

module four_bit_ripple_carry(a, b, cin, s, cout, ovfl);

input [3:0] a, b;
input cin;
output [3:0] s;
output cout, ovfl;

wire c1, c2, c3;

full_adder_1bit fa1(a[0], b[0], 1'b0, s[0], c1);
full_adder_1bit fa2(a[1], b[1], c1, s[1], c2);
full_adder_1bit fa3(a[2], b[2], c2, s[2], c3);
full_adder_1bit fa4(a[3], b[3], c3, s[3], cout);

assign ovfl = c3 ^ cout;

endmodule
