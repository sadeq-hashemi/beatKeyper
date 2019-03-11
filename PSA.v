module PSA_16bit (Sum, Error, A, B);
input [15:0] A, B; //Input values
output [15:0] Sum; //sum output
output Error; //To indicate overflows
wire ovfl1, ovfl2, ovfl3, ovfl4;

//(A, B, sub, Sum, Ovfl);

adder_4bit Four_BA1(A[15:12], B[15:12], 1'b0, Sum[15:12], ovfl1);
adder_4bit Four_BA2(A[11:8], B[11:8], 1'b0, Sum[11:8], ovfl2);
adder_4bit Four_BA3(A[7:4], B[7:4], 1'b0, Sum[7:4], ovfl3);
adder_4bit Four_BA4(A[3:0], B[3:0], 1'b0, Sum[3:0], ovfl4);

assign Error = ovfl1 | ovfl2 | ovfl3 | ovfl4;

endmodule