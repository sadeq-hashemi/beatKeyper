module CAE_Adder_4bit(input[3:0] a, input[3:0] b, input cin, output[3:0] sum,
                           output p_out, output g_out);
wire [3:0] temp_sum; 
wire [3:0] p, g, c;


full_adder_1bit adder_inst0(.A(a[0]), .B(b[0]), .Cin(cin), .S(sum[0]), .Cout());
full_adder_1bit adder_inst1(.A(a[1]), .B(b[1]), .Cin(c[1]), .S(sum[1]), .Cout());
full_adder_1bit adder_inst2(.A(a[2]), .B(b[2]), .Cin(c[2]), .S(sum[2]), .Cout());
full_adder_1bit adder_inst3(.A(a[3]), .B(b[3]), .Cin(c[3]), .S(sum[3]), .Cout());

//propagate logic
assign p[0] = a[0] | b[0];
assign p[1] = a[1] | b[1];
assign p[2] = a[2] | b[2];
assign p[3] = a[3] | b[3];
//generate logic
assign g[0] = a[0] & b[0];
assign g[1] = a[1] & b[1];
assign g[2] = a[2] & b[2];
assign g[3] = a[3] & b[3];
//carry logic
assign c[1] = g[0] | (p[0] & cin);
assign c[2] = g[1] | (p[1] & c[1]);
assign c[3] = g[2] | (p[2] & c[2]);
assign cout = g[3] | (p[3] & c[3]);
//pout and gout
assign p_out = p[3] & p[2] & p[1] & p[0];
assign g_out = g[3] | (p[3]& g[2]) | (p[3] & p[2] & g[1] ) | (p[3] & p[2] & p[1] & g[0]); 
endmodule



module CLA_Adder(a, b, sub, cout, sum, ovfl);

input [15:0] a, b;
wire [3:0] p, g, P, G, C;
wire [15:0] b2;
input sub;

output [15:0] sum;
output cout, ovfl;

assign b2 = sub ? ~b : b; 

CAE_Adder_4bit CLA_inst1(.a(a[3:0]), .b(b2[3:0]), .cin(C[0]), .sum(sum[3:0]), .p_out(p[0]), .g_out(g[0]));
CAE_Adder_4bit CLA_inst2(.a(a[7:4]), .b(b2[7:4]), .cin(C[1]), .sum(sum[7:4]), .p_out(p[1]), .g_out(g[1]));
CAE_Adder_4bit CLA_inst3(.a(a[11:8]), .b(b2[11:8]), .cin(C[2]), .sum(sum[11:8]),  .p_out(p[2]), .g_out(g[2]));
CAE_Adder_4bit CLA_inst4(.a(a[15:12]), .b(b2[15:12]), .cin(C[3]), .sum(sum[15:12]),  .p_out(p[3]), .g_out(g[3]));

//carry logic
assign C[0] = sub;
assign C[1] = g[0] | (p[0] & C[0]);
assign C[2] = g[1] | (p[1] & C[1]);
assign C[3] = g[2] | (p[2] & C[2]);
assign cout = g[3] | (p[3] & C[3]);

assign ovfl = a[15]!= b2[15]? 0: 
		a[15] == sum[15] ? 0 : 1;

endmodule