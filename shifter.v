module Shifter (Shift_Out, Shift_In, Shift_Val, Mode);

input [15:0] Shift_In; //This is the number to perform shift operation on
input [3:0] Shift_Val; //Shift amount (used to shift the ?Shift_In?)
input  Mode; // To indicate SLL or SRA 
wire [15:0] SLL, SLL_1, SLL_2, SLL_3, SLL_Fin;
wire [15:0] SRA, SRA_1, SRA_2, SRA_3, SRA_Fin;
output [15:0] Shift_Out; //Shifter value

// Mode 0 - SLL: shift left, and 0-fill the lower bits
// Mode 1 - SRA: shift right, and fill the upper bits according to the most significant bit

assign SRA = Shift_In;
assign SLL = Shift_In;
 
 assign SLL_Fin[15:0] = 	(Shift_Val == 0) ? (Shift_In[15:0]) :
				(Shift_Val == 1) ? ({Shift_In[14:0], 1'b0}) :
				(Shift_Val == 2) ? ({Shift_In[13:0], 2'b0}) :
				(Shift_Val == 3) ? ({Shift_In[12:0], 3'b0}) :
				(Shift_Val == 4) ? ({Shift_In[11:0], 4'b0}) :
				(Shift_Val == 5) ? ({Shift_In[10:0], 5'b0}) :
				(Shift_Val == 6) ? ({Shift_In[9:0], 6'b0}) :
				(Shift_Val == 7) ? ({Shift_In[8:0], 7'b0}) :
				(Shift_Val == 8) ? ({Shift_In[7:0], 8'b0}) :
				(Shift_Val == 9) ? ({Shift_In[6:0], 9'b0}) :
				(Shift_Val == 10) ? ({Shift_In[5:0], 10'b0}) :
				(Shift_Val == 11) ? ({Shift_In[4:0], 11'b0}) :
				(Shift_Val == 12) ? ({Shift_In[3:0], 12'b0}) :
				(Shift_Val == 13) ? ({Shift_In[2:0], 13'b0}) :
				(Shift_Val == 14) ? ({Shift_In[1:0], 14'b0}) :
				({Shift_In[0], 15'b0}); //default case of shifting 15 bits

  assign SRA_Fin[15:0] = 	(Shift_Val == 0) ? (Shift_In[15:0]) : //These are all mode 1 operations
				(Shift_Val == 1) ? ({{1{Shift_In[15]}}, Shift_In[15:1]}) :
				(Shift_Val == 2) ? ({{2{Shift_In[15]}}, Shift_In[15:2]}) :
				(Shift_Val == 3) ? ({{3{Shift_In[15]}}, Shift_In[15:3]}) :
				(Shift_Val == 4) ? ({{4{Shift_In[15]}}, Shift_In[15:4]}) :
				(Shift_Val == 5) ? ({{5{Shift_In[15]}}, Shift_In[15:5]}) :
				(Shift_Val == 6) ? ({{6{Shift_In[15]}}, Shift_In[15:6]}) :
				(Shift_Val == 7) ? ({{7{Shift_In[15]}}, Shift_In[15:7]}) :
				(Shift_Val == 8) ? ({{8{Shift_In[15]}}, Shift_In[15:8]}) :
				(Shift_Val == 9) ? ({{9{Shift_In[15]}}, Shift_In[15:9]}) :
				(Shift_Val == 10) ? ({{10{Shift_In[15]}}, Shift_In[15:10]}) :
				(Shift_Val == 11) ? ({{11{Shift_In[15]}}, Shift_In[15:11]}) :
				(Shift_Val == 12) ? ({{12{Shift_In[15]}}, Shift_In[15:12]}) :
				(Shift_Val == 13) ? ({{13{Shift_In[15]}}, Shift_In[15:13]}) :
				(Shift_Val == 14) ? ({{14{Shift_In[15]}}, Shift_In[15:14]}) :
				({{15{Shift_In[15]}}, Shift_In[15]}); //default case

assign Shift_Out = Mode ? SRA_Fin : SLL_Fin;

endmodule

module SLL_128(shift_in, shift_val, shift_out);

input [127:0] shift_in; //This is the number to perform shift operation on
input [6:0] shift_val; //Shift amount (used to shift the ?shift_in?) 
output [127:0] shift_out; //Shifter value

//buffers that hold intermediate values
wire [127:0] SLL1;
wire [127:0] SLL2;
wire [127:0] SLL4;
wire [127:0] SLL8;
wire [127:0] SLL16;
wire [127:0] SLL32;
wire [127:0] SLL64;
wire [127:0] SLL128;

assign SLL1[127:0] = shift_val[0] ? {shift_in[126:0], 1'b0}: shift_in[127:0];
assign SLL2[127:0] = shift_val[1] ? {SLL1[125:0], {2{1'b0}} }: SLL1[127:0];
assign SLL4[127:0] = shift_val[2] ? {SLL2[123:0], {4{1'b0}} }: SLL2[127:0];
assign SLL8[127:0] = shift_val[3] ? {SLL4[119:0], {8{1'b0}} }: SLL4[127:0];
assign SLL16[127:0] = shift_val[4] ? {SLL8[111:0], {16{1'b0}} }: SLL8[127:0];
assign SLL32[127:0] = shift_val[5] ? {SLL16[95:0], {32{1'b0}} }: SLL16[127:0];
assign SLL64[127:0] = shift_val[6] ? {SLL32[63:0], {64{1'b0}} }: SLL32[127:0];

assign shift_out[127:0] = SLL64[127:0]; 

endmodule;

module SLL_8(shift_in, shift_val, shift_out);

input [7:0] shift_in; //This is the number to perform shift operation on
input [2:0] shift_val; //Shift amount (used to shift the ?shift_in?) 
output [7:0] shift_out; //Shifter value

//buffers that hold intermediate values
wire [7:0] SLL1;
wire [7:0] SLL2;
wire [7:0] SLL4;


assign SLL1[7:0] = shift_val[0] ? {shift_in[6:0], 1'b0}: shift_in[7:0];
assign SLL2[7:0] = shift_val[1] ? {SLL1[5:0], {2{1'b0}} }: SLL1[7:0];
assign SLL4[7:0] = shift_val[2] ? {SLL2[3:0], {4{1'b0}} }: SLL2[7:0];


assign shift_out[7:0] = SLL4[7:0]; 

endmodule;
