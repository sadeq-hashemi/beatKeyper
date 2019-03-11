module Forward( EX_MEM_wr, MEM_WB_wr, EX_MEM_wb, MEM_WB_wb,
		IF_ID_r1, IF_ID_r2, forwardA, forwardB);
//wr = write register r = readregister
input [3:0]  EX_MEM_wr, MEM_WB_wr; //register num being written to at every stage
input EX_MEM_wb, MEM_WB_wb; //writeback signal at each stage
input [3:0] IF_ID_r1, IF_ID_r2; //input registers 

output [1:0] forwardA, forwardB;

wire [3:0] ID_EX_xor1, ID_EX_xor2, EX_MEM_xor1, EX_MEM_xor2, MEM_WB_xor1, MEM_WB_xor2; 
wire ID_EX_eq1, ID_EX_eq2, EX_MEM_eq1, EX_MEM_eq2, MEM_WB_eq1, MEM_WB_eq2; 

localparam ID = 2'b00;
localparam EX = 2'b01;
localparam MEM = 2'b10;
localparam NA = 2'b11;


//compares bits of write registers with those of read registers
assign EX_MEM_eq1 = EX_MEM_wr == IF_ID_r1 ? 1'b1 : 1'b0; 
assign EX_MEM_eq2 = EX_MEM_wr == IF_ID_r2 ? 1'b1 : 1'b0; 

assign MEM_WB_eq1 = MEM_WB_wr == IF_ID_r1 ? 1'b1 : 1'b0; 
assign MEM_WB_eq2 = MEM_WB_wr == IF_ID_r2 ? 1'b1 : 1'b0; 

assign forwardA = EX_MEM_wb & (EX_MEM_wr != 3'b000) & EX_MEM_eq1 ? EX : 
		MEM_WB_wb & (MEM_WB_wr != 3'b000) & MEM_WB_eq1 ?  MEM : 
							ID;   

assign forwardB = EX_MEM_wb & (EX_MEM_wr != 3'b000) & EX_MEM_eq2 ? EX : 
		MEM_WB_wb & (MEM_WB_wr != 3'b000) & MEM_WB_eq2 ?  MEM : 
							ID;  

endmodule

