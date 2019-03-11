module flush(inst_in, inst_out);

input [15:0] inst_in;
output [15:0] inst_out;

assign inst_out = inst_in & 16'h0000;

endmodule