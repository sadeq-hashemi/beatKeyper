module MEM_arbitrary( clk, rst,			//cpu input
	D_miss, D_wr, D_addr, D_data_in, D_disable, 	//Dcache input
	D_data_valid, D_data_out, txn_done, 	//Dcache output
	I_miss, I_addr, mem_ready, I_disable,	//Icache input
	I_data_valid, I_data_out,		//Icache output
	freeze, i_state_in, d_state_in 		//CPU output	
);
//--------------param--------------//
parameter ADDR_WIDTH = 16;
//--------------input signals--------------//
input clk, rst; 
input D_miss, D_wr, I_miss, I_disable, D_disable;  
input [ADDR_WIDTH - 1:0] D_addr, I_addr;
input [15:0] D_data_in;
input txn_done;
input i_state_in, d_state_in;

//--------------mem signals--------------//
wire [15:0] data_out;
wire [15:0] data_in;
wire [ADDR_WIDTH - 1:0] addr; 
wire enable;
wire wr; 
wire data_valid;
wire D_miss_flop, I_miss_flop, D_wr_flop;

//--------------output signals--------------//
output D_data_valid, I_data_valid;
output [15:0] D_data_out, I_data_out;
output freeze, mem_ready; 
//_________________________________________________________________________________________________//

//--------------arbitration--------------//
/* prioritize D_miss >> I_miss >> D_wr*/
BitCell DMISS( .clk(clk),   .rst(rst),  .D(D_miss),  .WriteEnable(1'b1),  .ReadEnable1(1'b1),  .ReadEnable2(1'b0),  .Bitline1(D_miss_flop),  .Bitline2() );
BitCell IMISS( .clk(clk),   .rst(rst),  .D(I_miss),  .WriteEnable(1'b1),  .ReadEnable1(1'b1),  .ReadEnable2(1'b0),  .Bitline1(I_miss_flop),  .Bitline2() );
BitCell DWR( .clk(clk),   .rst(rst),  .D(D_wr),  .WriteEnable(1'b1),  .ReadEnable1(1'b1),  .ReadEnable2(1'b0),  .Bitline1(D_wr_flop),  .Bitline2() );
BitCell TXNDONE( .clk(clk),   .rst(rst),  .D(txn_done),  .WriteEnable(1'b1),  .ReadEnable1(1'b1),  .ReadEnable2(1'b0),  .Bitline1(txn_done_flop),  .Bitline2() );

//--------------mem--------------//
assign enable = /**/( D_wr | (i_state_in | d_state_in) &( (D_miss_flop & !D_disable) | (I_miss_flop & ! I_disable))); //mem is disabled when all signals are low
assign wr = D_miss | I_miss ? 1'b0 : D_wr ? 1'b1 : 1'b0; //only write when no misses 
assign addr = D_miss_flop & !txn_done_flop ?		D_addr :
		I_miss_flop? 	I_addr : 
		  D_wr_flop ? 	D_addr : 
		 		16'd0; 

assign data_in = D_miss | I_miss ? 16'dz : D_wr ? D_data_in : 16'dz;
 
memory4c mem( .data_out(data_out), .data_in(data_in), .addr(addr), .enable(enable), .wr(wr), .clk(clk), .rst(rst), .data_valid(data_valid));

//--------------output--------------//
assign D_data_valid =  D_miss_flop ?	data_valid :
			I_miss_flop? 	1'b0 : 
		 	 D_wr_flop ? 	1'b0 : 
		 			1'b0; 

assign D_data_out =	D_miss_flop ?	data_out :
			 I_miss_flop? 	16'dz : 
		  	  D_wr_flop ? 	16'dz : 
		 			16'dz;

assign I_data_valid =	D_miss_flop ?	1'b0 :
			 I_miss_flop? 	data_valid : 
		 	  D_wr_flop? 	1'b0 : 
		 			1'b0;

assign I_data_out = 	D_miss_flop ?	16'dz :
			 I_miss_flop? 	data_out : 
		  	  D_wr_flop ? 	16'dz : 
		 			16'dz;

assign mem_ready = txn_done ;//& I_miss_flop;
 
assign freeze = D_miss | I_miss ; 
endmodule;

//_________________________________________________________________________________________________//
