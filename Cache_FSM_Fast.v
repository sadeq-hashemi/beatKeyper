module cache_fsm_fast(clk, rst,
				 i_addr, i_miss, i_data_out, i_data_valid, i_wb_addr,  //I-Cache Control ... never writes data
				 d_addr, d_miss, d_data_out, d_data_valid, d_wb_addr, d_write, d_data_in, //D-Cache Control
				 mem_addr, data_from_mem, mem_data_valid, //Memory control 
				 d_write_done, i_mem_read_done, d_mem_read_done, mem_write_en, //used to let the caches know were done and when to write mem
				 hazard_stall , data_to_mem, mem_enable); //to stall the pipe and write through data

input clk, rst;
input i_miss, d_miss, d_write, mem_data_valid;
input [15:0] i_addr, d_addr, data_from_mem, d_data_in;

output mem_enable; //used to enable the memory for reads (and writes?)
output i_data_valid, d_data_valid, d_write_done, hazard_stall, i_mem_read_done, d_mem_read_done, mem_write_en;
output [15:0] i_data_out, i_wb_addr, d_data_out, d_wb_addr, mem_addr, data_to_mem;

//DW = D Cache is trying to write back
//DMW = D Cache wants to write, it first loads block from memory, and then writes it back 
//IM = I Cache misses so we read
localparam IDLE = 3'b000, IM = 3'b001, DM = 3'b010, DM_IM = 3'b011, 
		   DW = 3'b100, DMW = 3'b101, DW_IM = 3'b110, DMW_IM = 3'b111; //DM_IM = both I Cache and D Cache miss
localparam NINE = 4'd9;
//State Machine Logic
wire [2:0] state, n_state; 
Reg_3_Bit state_reg(.clk(clk), .rst(rst), .D(n_state), .WriteReg(1'b1), .ReadEnable1(1'b1), .Readenable2(1'b0), .Bitline1(state), .Bitline2()); //bitline 2 is not used as an output
//

wire [3:0] i_miss_count, d_miss_count, i_miss_count_next, d_miss_count_next, i_miss_count_incr, d_miss_count_incr; //used to keep track of how many blocks we have receieved/sent
wire [15:0] i_flop1, i_flop2, i_flop3, i_flop4; //last addr is the output i_wb_addr
wire [15:0] d_flop1, d_flop2, d_flop3, d_flop4, d_flop5; 
wire d_write_count_reg_en;
wire [3:0] d_write_count, d_write_count_next, d_write_count_incr;
//ADDR Registers
wire [15:0] i_addr_incr, d_addr_incr, i_addr_next, d_addr_next; //stores the current addr and the next (+2) addr

wire [15:0] i_addr_adder_out, d_addr_adder_out;
adder_4bit i_miss_counter_adder(.A(i_miss_count), .B(4'b1), .Sum(i_miss_count_incr));

Register I_ADDR_FLOP1_REG(.clk(clk), .rst(rst), .D(i_addr_incr), .WriteReg(1'b1), .ReadEnable1(1'b1), .Readenable2(1'b0), .Bitline1(i_flop1), .Bitline2());
Register I_ADDR_FLOP2_REG(.clk(clk), .rst(rst), .D(i_flop1), .WriteReg(1'b1), .ReadEnable1(1'b1), .Readenable2(1'b0), .Bitline1(i_flop2), .Bitline2());
Register I_ADDR_FLOP3_REG(.clk(clk), .rst(rst), .D(i_flop2), .WriteReg(1'b1), .ReadEnable1(1'b1), .Readenable2(1'b0), .Bitline1(i_flop3), .Bitline2());
Register I_ADDR_FLOP4_REG(.clk(clk), .rst(rst), .D(i_flop3), .WriteReg(1'b1), .ReadEnable1(1'b1), .Readenable2(1'b0), .Bitline1(i_flop4), .Bitline2());
Register I_ADDR_FLOP5_REG(.clk(clk), .rst(rst), .D(i_flop4), .WriteReg(1'b1), .ReadEnable1(1'b1), .Readenable2(1'b0), .Bitline1(i_wb_addr), .Bitline2());

assign i_miss_count_reg_en = (state == IDLE) 
				| ((state == IM & mem_data_valid)) 
				| (i_miss_count == 4'd8)
				| (state == DM_IM & d_miss_count == NINE & mem_data_valid)
				| (state == DW_IM & d_write_done & i_miss_count != NINE & mem_data_valid)
				| (state == DMW_IM & d_miss_count == NINE & d_write_done & mem_data_valid);
// TODO: examine all logic, we might wanna add & mem_data_valid to all these
Register I_ADDR_REG(.clk(clk), .rst(rst), .D(i_addr_incr), .WriteReg(1'b1), .ReadEnable1(1'b1), .Readenable2(1'b0), .Bitline1(i_addr_next), .Bitline2());

//is the mem_addr input
assign i_addr_incr = ((state == IDLE & i_miss) //dont need? 
						|(state == DM_IM & d_miss_count == 4'd7 & i_miss_count == 4'd0) 
						| (state == DW_IM & d_write_count == 4'd7 ) 
						| (state == DMW_IM & d_miss_count == NINE & d_write_count == 4'd7 & i_miss_count == 4'd0)) ? i_addr : //when we are done with d_mis sinside of IDmiss, we start handling the i_miss at the I addr, and then start counting by 2	 
		     		 (state == IM 
						| (state == DM_IM & (d_miss_count == NINE | d_miss_count == 4'd8))
						| (state == DW_IM & d_write_done & i_miss_count != NINE)  
						| (state == DMW_IM & d_miss_count == NINE & d_write_done))? i_addr_adder_out : 0;

//Output Logic... signals when the read phases are done 
assign i_data_valid = (state == IM & i_miss_count != 4'd8 & mem_data_valid) ? 1'b1 :
		      (state == DM_IM & d_miss_count == NINE & mem_data_valid) ? 1'b1 : 
		      (state == DW_IM & d_write_count == 4'd8 & mem_data_valid) ? 1'b1 : 
		      (state == DMW_IM & d_miss_count == NINE & d_write_count == NINE & mem_data_valid) ? 1'b1 : 1'b0; //if d_miss_count == 7, we are done processing d-miss, 

Reg_4_Bit i_miss_count_reg(.clk(clk), .rst(rst), .D(i_miss_count_next), .WriteReg(i_miss_count_reg_en), .ReadEnable1(1'b1), .Readenable2(1'b0), .Bitline1(i_miss_count), .Bitline2()); //bitline 2 is not used as an output
assign i_miss_count_next = (state == IDLE) ? 0 : i_miss_count_incr; //used to reset counter

//used to flop i_addr because the output i addr has to be delayed 4 cycles, so flop 4 times
Register D_ADDR_FLOP1_REG(.clk(clk), .rst(rst), .D(d_addr_incr), .WriteReg(1'b1), .ReadEnable1(1'b1), .Readenable2(1'b0), .Bitline1(d_flop1), .Bitline2());
Register D_ADDR_FLOP2_REG(.clk(clk), .rst(rst), .D(d_flop1), .WriteReg(1'b1), .ReadEnable1(1'b1), .Readenable2(1'b0), .Bitline1(d_flop2), .Bitline2());
Register D_ADDR_FLOP3_REG(.clk(clk), .rst(rst), .D(d_flop2), .WriteReg(1'b1), .ReadEnable1(1'b1), .Readenable2(1'b0), .Bitline1(d_flop3), .Bitline2());
Register D_ADDR_FLOP4_REG(.clk(clk), .rst(rst), .D(d_flop3), .WriteReg(1'b1), .ReadEnable1(1'b1), .Readenable2(1'b0), .Bitline1(d_flop4), .Bitline2());
Register D_ADDR_FLOP5_REG(.clk(clk), .rst(rst), .D(d_flop4), .WriteReg(1'b1), .ReadEnable1(1'b1), .Readenable2(1'b0), .Bitline1(d_flop5), .Bitline2());

//TO DO , fix it in teh case of a write
assign d_wb_addr = ((state == DM | (state == DMW | state == DMW_IM | state == DM_IM)) & d_miss_count != 4'd9) ? d_flop5 /*the delayed input*/ : d_addr_incr; //or grab current addr

adder_4bit d_miss_counter_adder(.A(d_miss_count), .B(4'b1), .Sum(d_miss_count_incr));

assign d_miss_count_reg_en = (state == IDLE) 
				| (state == DM & mem_data_valid)
				| (d_miss_count == 4'd8)
				| (state == DMW & d_miss_count != NINE & mem_data_valid)
				| (state == DMW_IM & d_miss_count != NINE & mem_data_valid)
				| (state == DM_IM & d_miss_count != NINE & mem_data_valid);

Reg_4_Bit d_miss_count_reg(.clk(clk), .rst(rst), .D(d_miss_count_next), .WriteReg(d_miss_count_reg_en), .ReadEnable1(1'b1), .Readenable2(1'b0), .Bitline1(d_miss_count), .Bitline2()); //bitline 2 is not used as an output
assign d_miss_count_next = (state == IDLE) ? 0 : d_miss_count_incr; //used to reset counter


Reg_4_Bit d_write_count_reg(.clk(clk), .rst(rst), .D(d_write_count_next), .WriteReg(d_write_count_reg_en), .ReadEnable1(1'b1), .Readenable2(1'b0), .Bitline1(d_write_count), .Bitline2()); //bitline 2 is not used as an output
adder_4bit d_write_counter_adder(.A(d_write_count), .B(4'b1), .Sum(d_write_count_incr));
assign d_write_count_reg_en = (state == IDLE) 
				| (state == DW) 
				| (state == DMW & d_miss_count == NINE)
				| (state == DW_IM & !d_write_done)
				| (state == DMW_IM & d_miss_count == NINE & !d_write_done) ? 1'b1 : 1'b0; //when we are writing, its ready every cycle
assign d_write_count_next = (state == IDLE) ? 0 : d_write_count_incr;

Register D_ADDR_REG(.clk(clk), .rst(rst), .D(d_addr_incr), .WriteReg(1'b1), .ReadEnable1(1'b1), .Readenable2(1'b0), .Bitline1(d_addr_next), .Bitline2());
CLA_Adder d_addr_adder(.a(d_addr_next), .b(16'h0002), .sub(1'b0), .cout(), .sum(d_addr_adder_out), .ovfl());
assign d_addr_incr = ((state == IDLE & (d_miss | d_write))) 
			| ((state == DMW) & (d_miss_count ==  4'd8) & d_write_count == 4'd0) 
			| (state == DMW_IM & (d_miss_count ==  4'd8) & d_write_count == 4'd0)? d_addr : 

		     ((state == DM) | (state == DM_IM & d_miss_count !=  NINE) 
			| (state == DW & !d_write_done)) 
			| (state == DMW)
			| (state == DW_IM & (!d_write_done | i_miss_count != 4'd8)) 
			| (state == DMW_IM) ? d_addr_adder_out : 0;


assign d_data_valid = (state == DM & mem_data_valid) ? 1'b1 :
		      (state == DM_IM & (d_miss_count != NINE & d_miss_count != 4'd8) & mem_data_valid) ? 1'b1 : 
			  (state == DMW & d_miss_count != NINE & mem_data_valid) ? 1'b1 : 
		      (state == DMW_IM & d_miss_count != NINE & mem_data_valid) ? 1'b1 : 1'b0; //we are in d phase until d_miss_count hits 7

CLA_Adder i_addr_adder(.a(i_addr_next), .b(16'h0002), .sub(1'b0), .cout(), .sum(i_addr_adder_out), .ovfl());

//Next State Logic
assign n_state = (state == IDLE) ? ((i_miss & d_miss & d_write) ? DMW_IM:
				 	     (d_miss & d_write) ? DMW : 
					     (d_write & i_miss) ? DW_IM : 
					     (d_miss & i_miss) ? DM_IM :
					     (i_miss) ? IM :
					     (d_write) ? DW :
					     (d_miss) ? DM : IDLE):

				 (state == IM) ? ((i_miss_count == 4'd8) ? IDLE : IM) :
				 (state == DM) ? ((d_miss_count == 4'd8) ? IDLE : DM) :
				 (state == DM_IM) ? (((i_miss_count == 4'd8) & (d_miss_count == NINE)) ? IDLE : DM_IM) :
				 (state == DW) ? (d_write_count == 4'd8 ? IDLE : DW) :
				 (state == DMW) ? (d_write_count == 4'd8 & d_miss_count == NINE ? IDLE : DMW) :
				 (state == DW_IM) ? (d_write_count == 4'd8 & i_miss_count == 4'd8 ? IDLE : DW_IM) :
				 (state == DMW_IM) ? (d_write_count == 4'd8 & d_miss_count == NINE & i_miss_count == 4'd8 ? IDLE : DMW_IM) : IDLE; //default is idle
//

assign mem_write_en = (state == DW 
			| (state == DMW & d_miss_count == NINE & d_write_count != 4'd8) 
			| (state == DW_IM & !d_write_done)
			| (state == DMW_IM & d_miss_count == NINE & d_write_count != 4'd8));

assign d_write_done = d_write_count == 4'd8 ? 1'b1 : 1'b0; //this should let the fsm know that the write is all done for d cache so we will move to the i-miss handlng
// D_miss_read logic, used to signal d-cache that the controller has supplied all 8 chunks of 2-byte data
assign d_mem_read_done = (state == DM & d_miss_count == 4'd8)
						| ((state == DM_IM | state == DMW | state == DMW_IM) & (d_miss_count == 4'd8)) ? 1'b1 : 1'b0;
// I_miss read logic, used to signal i-cache that the controller has supplied all 8 chunks of 2-byte data
assign i_mem_read_done = (state == IM | state == DM_IM | state == DW_IM | state == DMW_IM) & (i_miss_count == 4'd8) ? 1'b1 : 1'b0;
assign data_to_mem = d_data_in; //since the i-cache wont ever write data

//addr logic
assign mem_addr = ((state == IM) //handle i miss 
		 | (state == DM_IM & (d_miss_count == 4'd8 | d_miss_count == NINE))
		 | (state == DW_IM & d_write_count == 4'd8)
		 | (state == DMW_IM & d_write_count == 4'd8)) ? i_addr_next :
		  ((state == DM) //handle d phase
		 | (state == DM_IM & d_miss_count != NINE) 
		 | (state == DW) 
		 | (state == DMW) 
		 | (state == DW_IM & d_write_count != 4'd8)
		 | (state == DMW_IM & d_write_count != 4'd8) /*write will only increment after d_miss_count == 8*/) ? d_addr_next : 16'd0; 
wire i_lesseq_3, d_lesseq_3;
assign d_lesseq_3 =  d_miss_count == 4'd0 | d_miss_count == 4'd1  | d_miss_count == 4'd2 | d_miss_count == 4'd3;
assign i_lesseq_3 =  i_miss_count == 4'd0 | i_miss_count == 4'd1  | i_miss_count == 4'd2 | i_miss_count == 4'd3;
assign d_write_lesseq_3 = d_write_count == 4'd0 | d_write_count == 4'd1  | d_write_count == 4'd2 | d_write_count == 4'd3;
//TODO FININSH~~~~~~~~~~~~~
assign mem_enable = ((state == DM_IM & d_lesseq_3) | (state == DM_IM & (d_miss_count == 4'd8|d_miss_count == 4'd9) & i_lesseq_3))
					| (state == DM & d_lesseq_3)
 					| (state == IM & i_lesseq_3)
					| (state == DW & d_write_lesseq_3) 
					//////
					| ((state == DMW & d_lesseq_3 & d_write_count == 4'd0) | (state == DMW & d_write_lesseq_3 & (d_miss_count == 4'd8|d_miss_count == 4'd9)))
					| ((state == DW_IM & d_write_lesseq_3) | (d_write_count == 4'd8 & state == DW_IM & i_lesseq_3)) 
					| ((state == DMW_IM & d_lesseq_3) 
								| (state == DMW_IM & (d_miss_count == 4'd8|d_miss_count == 4'd9) & d_write_lesseq_3) 
								| (state == DMW_IM & (d_miss_count == 4'd8|d_miss_count == 4'd9) & d_write_count == 4'd8 & i_lesseq_3 ))? 1'b1 : 1'b0; //should be one while we feed in read addr
assign i_data_out = data_from_mem;
assign d_data_out = data_from_mem;
assign hazard_stall = (state != IDLE) ? 1'b1 : 0; //any time were not idling we must be stalling

endmodule