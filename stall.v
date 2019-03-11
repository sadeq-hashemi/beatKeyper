module stall (stall, r_ifid_out, r_memwb_out, r_exmem_out);

input stall;
output r_ifid_out, r_memwb_out, r_exmem_out;

assign r_ifid_out = stall ^ 1'b1;
assign r_memwb_out = stall ^ 1'b1;
assign r_exmem_out = stall ^ 1'b1;

endmodule