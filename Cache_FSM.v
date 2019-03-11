module cache_fsm(clk, rst,
				 i_addr, i_miss, i_data_out, i_data_valid, i_wb_addr,  //I-Cache Control ... never writes data
				 d_addr, d_miss, d_data_out, d_data_valid, d_wb_addr, d_write, d_data_in, //D-Cache Control
				 mem_addr, data_from_mem, mem_data_valid, //Memory control 
				 d_write_done, i_mem_read_done, d_mem_read_done, mem_write_en, //used to let the caches know were done and when to write mem
				 hazard_stall , data_to_mem); //to stall the pipe and write through data

input clk, rst;
input i_miss, d_miss, d_write, mem_data_valid;
input [15:0] i_addr, d_addr, data_from_mem, d_data_in;

output i_data_valid, d_data_valid, d_write_done, hazard_stall, i_mem_read_done, d_mem_read_done, mem_write_en;
output [15:0] i_data_out, i_wb_addr, d_data_out, d_wb_addr, mem_addr, data_to_mem;

//DW = D Cache is trying to write back
//DMW = D Cache wants to write, it first loads block from memory, and then writes it back 
//IM = I Cache misses so we read
localparam IDLE = 3'b000, IM = 3'b001, DM = 3'b010, DM_IM = 3'b011, 
		   DW = 3'b100, DMW = 3'b101, DW_IM = 3'b110, DMW_IM = 3'b111; //DM_IM = both I Cache and D Cache miss


//State Machine Logic
wire [2:0] state, n_state; 
Reg_3_Bit state_reg(.clk(clk), .rst(rst), .D(n_state), .WriteReg(1'b1), .ReadEnable1(1'b1), .Readenable2(1'b0), .Bitline1(state), .Bitline2()); //bitline 2 is not used as an output
//


//Counters to know how many blocks have been receieved
wire [3:0] i_miss_count, d_miss_count, i_miss_count_next, d_miss_count_next, i_miss_count_incr, d_miss_count_incr; //used to keep track of how many blocks we have receieved/sent
adder_4bit i_miss_counter_adder(.A(i_miss_count), .B(4'b1), .Sum(i_miss_count_incr));
adder_4bit d_miss_counter_adder(.A(d_miss_count), .B(4'b1), .Sum(d_miss_count_incr));

// TODO: does d_miss_count need to be reset after we're done with a ID_miss?
wire i_miss_count_reg_en, d_miss_count_reg_en;

assign i_miss_count_reg_en = (state == IDLE) 
				| ((state == IM & mem_data_valid)) 
				| (state == DM_IM & d_miss_count == 4'd8 & mem_data_valid)
				| (state == DW_IM & d_write_done & i_miss_count != 8 & mem_data_valid)
				| (state == DMW_IM & d_miss_count == 4'd8 & d_write_done & mem_data_valid);

assign d_miss_count_reg_en = (state == IDLE) 
				| (state == DM & mem_data_valid)
				| (state == DMW & mem_data_valid)
				| (state == DMW_IM & d_miss_count != 4'd8 & mem_data_valid)
				| (state == DM_IM & d_miss_count != 4'd8 & mem_data_valid);

Reg_4_Bit i_miss_count_reg(.clk(clk), .rst(rst), .D(i_miss_count_next), .WriteReg(i_miss_count_reg_en), .ReadEnable1(1'b1), .Readenable2(1'b0), .Bitline1(i_miss_count), .Bitline2()); //bitline 2 is not used as an output
Reg_4_Bit d_miss_count_reg(.clk(clk), .rst(rst), .D(d_miss_count_next), .WriteReg(d_miss_count_reg_en), .ReadEnable1(1'b1), .Readenable2(1'b0), .Bitline1(d_miss_count), .Bitline2()); //bitline 2 is not used as an output
assign i_miss_count_next = (state == IDLE) ? 0 : i_miss_count_incr; //used to reset counter
assign d_miss_count_next = (state == IDLE) ? 0 : d_miss_count_incr; //used to reset counter


//counters for writing
wire d_write_count_reg_en;
wire [3:0] d_write_count, d_write_count_next, d_write_count_incr;
Reg_4_Bit d_write_count_reg(.clk(clk), .rst(rst), .D(d_write_count_next), .WriteReg(d_write_count_reg_en), .ReadEnable1(1'b1), .Readenable2(1'b0), .Bitline1(d_write_count), .Bitline2()); //bitline 2 is not used as an output
adder_4bit d_write_counter_adder(.A(d_write_count), .B(4'b1), .Sum(d_write_count_incr));
assign d_write_count_reg_en = (state == IDLE) 
				| (state == DW) 
				| (state == DMW & d_miss_count == 4'd8)
				| (state == DW_IM & !d_write_done)
				| (state == DMW_IM & d_miss_count == 4'd8 & !d_write_done) ? 1'b1 : 1'b0; //when we are writing, its ready every cycle
assign d_write_count_next = (state == IDLE) ? 0 : d_write_count_incr;
//


//ADDR Registers
wire [15:0] i_addr_incr, d_addr_incr, i_addr_next, d_addr_next; //stores the current addr and the next (+2) addr
wire I_ADDR_REG_en, D_ADDR_REG_en;


// TODO: examine all logic, we might wanna add & mem_data_valid to all these
assign I_ADDR_REG_en = ((state == IDLE & i_miss)) /*grabs init addr */ | mem_data_valid /*get next addr +2 */ 
						| ((state == DM_IM & d_miss_count == 4'd8 & i_miss_count == 4'd0) 
						| (state == DW_IM & d_write_done & i_miss_count != 4'd8 & mem_data_valid) /*i_miss cycle is starting so get init*/)
						| (state == DMW_IM & d_miss_count == 4'd8 & d_write_count == 4'd8 & i_miss_count == 4'd0);
assign D_ADDR_REG_en = (state == IDLE & d_miss) | mem_data_valid
						| (state == DW & !d_write_done) 
						| (state == DW_IM & !d_write_done & d_write == 1'b1)
						| (state == DMW & d_miss_count == 4'd8)
						| ((state == DMW | state == DMW_IM) & d_miss_count != 4'd8 & mem_data_valid) 
						| (state == DMW_IM & d_miss_count == 4'd8 & !d_write_done); //when we finish d read phase we need to reset addr so mem_addr is writing block 0

Register I_ADDR_REG(.clk(clk), .rst(rst), .D(i_addr_incr), .WriteReg(I_ADDR_REG_en), .ReadEnable1(1'b1), .Readenable2(1'b0), .Bitline1(i_addr_next), .Bitline2());
Register D_ADDR_REG(.clk(clk), .rst(rst), .D(d_addr_incr), .WriteReg(D_ADDR_REG_en), .ReadEnable1(1'b1), .Readenable2(1'b0), .Bitline1(d_addr_next), .Bitline2());



wire [15:0] i_addr_adder_out;
wire [15:0] d_addr_adder_out;
CLA_Adder i_addr_adder(.a(i_addr_next), .b(16'h0002), .sub(1'b0), .cout(), .sum(i_addr_adder_out), .ovfl());
CLA_Adder d_addr_adder(.a(d_addr_next), .b(16'h0002), .sub(1'b0), .cout(), .sum(d_addr_adder_out), .ovfl());


// TODO: clean up logic for this part
assign i_addr_incr = (state == IDLE & i_miss) ? i_addr : 
					 (
		     (state == DM_IM & d_miss_count == 4'd8 & i_miss_count == 4'd0) 
			| (state == DW_IM & d_write_done & i_miss_count == 4'd0) 
			| (state == DMW_IM & d_miss_count == 4'd8 & d_write_count == 4'd8 & i_miss_count == 4'd0)) ? i_addr : //when we are done with d_mis sinside of IDmiss, we start handling the i_miss at the I addr, and then start counting by 2
					 
		     ((state == IM) 
			| (state == DM_IM & d_miss_count == 4'd8))
			| (state == DW_IM & d_write_done & i_miss_count != 4'd8)  
			| (state == DMW_IM & d_miss_count == 4'd8 & d_write_done)? i_addr_adder_out : 0;
// TODO: Assign i_miss_count == 4'd8 to a wire called "i_miss_done", and replace everything?


assign d_addr_incr = ((state == IDLE & d_miss) 
			| ((state == DMW) & (d_miss_count == 4'd0 | d_miss_count == 4'd8) & d_write_count == 4'd0)) 
			| (state == DW & d_write_count == 4'd0) | (state == DW_IM & d_write_count == 4'd0) 
			| (state == DMW_IM & (d_miss_count == 4'd0 | d_miss_count == 4'd8) & d_write_count == 4'd0)? d_addr : 

		     ((state == DM) | (state == DM_IM & d_miss_count != 4'd8) 
			| (state == DW & !d_write_done)) 
			| (state == DMW & d_miss_count == 4'd8 & d_write_count != 4'd8 & d_write_count != 4'd0)
			| (state == DW_IM & !d_write_done) 
			| (state == DMW_IM & d_miss_count == 4'd8 & d_write_count != 4'd8 & d_write_count != 4'd0) ? d_addr_adder_out : 0;


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
				 (state == DM_IM) ? (((i_miss_count == 4'd8) & (d_miss_count == 4'd8)) ? IDLE : DM_IM) :
				 (state == DW) ? (d_write_count == 4'd8 ? IDLE : DW) :
				 (state == DMW) ? (d_write_count == 4'd8 & d_miss_count == 4'd8 ? IDLE : DMW) :
				 (state == DW_IM) ? (d_write_count == 4'd8 & i_miss_count == 4'd8 ? IDLE : DW_IM) :
				 (state == DMW_IM) ? (d_write_count == 4'd8 & d_miss_count == 4'd8 & i_miss_count == 4'd8 ? IDLE : DMW_IM) : IDLE; //default is idle
//

//Output Logic... signals when the read phases are done 
assign i_data_valid = (state == IM & mem_data_valid) ? 1'b1 :
		      (state == DM_IM & d_miss_count == 4'd8 & mem_data_valid) ? 1'b1 : 
		      (state == DW_IM & d_write_count == 4'd8 & mem_data_valid) ? 1'b1 : 
		      (state == DMW_IM & d_miss_count == 4'd8 & d_write_count == 4'd8 & mem_data_valid) ? 1'b1 : 1'b0; //if d_miss_count == 7, we are done processing d-miss, 
														       // so we are processing i

assign d_data_valid = (state == DM & mem_data_valid) ? 1'b1 :
		      (state == DM_IM & d_miss_count != 4'd8 & mem_data_valid) ? 1'b1 : 
		      //(state == DW & d_write_count != 4'd8 & mem_data_valid) ? 1'b1 : 
		      (state == DMW & d_miss_count != 4'd8 & mem_data_valid) ? 1'b1 : 
		      //(state == DW_IM & d_miss_count != 4'd8 & mem_data_valid) ? 1'b1 : 
		      (state == DMW_IM & d_miss_count != 4'd8 & mem_data_valid) ? 1'b1 : 1'b0; //we are in d phase until d_miss_count hits 7

assign i_data_out = data_from_mem;
assign d_data_out = data_from_mem;

assign mem_write_en = (state == DW 
			| (state == DMW & d_miss_count == 4'd8) 
			| (state == DW_IM & !d_write_done)
			| (state == DMW_IM & d_miss_count == 4'd8 & d_write_count != 4'd8));

assign d_write_done = d_write_count == 4'd8 ? 1'b1 : 1'b0; //this should let the fsm know that the write is all done for d cache so we will move to the i-miss handlng

// D_miss_read logic, used to signal d-cache that the controller has supplied all 8 chunks of 2-byte data
assign d_mem_read_done = (state == DM | state == DM_IM | state == DMW | state == DMW_IM) & (d_miss_count == 4'd8) ? 1'b1 : 1'b0;

// I_miss read logic, used to signal i-cache that the controller has supplied all 8 chunks of 2-byte data
assign i_mem_read_done = (state == IM | state == DM_IM | state == DW_IM | state == DMW_IM) & (i_miss_count == 4'd8) ? 1'b1 : 1'b0;


assign data_to_mem = d_data_in; //since the i-cache wont ever write data

//addr logic
assign mem_addr = ((state == IM) 
		 | (state == DM_IM & d_miss_count == 4'd8)
		 | (state == DW_IM & d_write_count == 4'd8)
		 | (state == DMW_IM & d_write_count == 4'd8)) ? i_addr_next :
		  ((state == DM) 
		 | (state == DM_IM & d_miss_count != 4'd8) 
		 | (state == DW) 
		 | (state == DMW) 
		 | (state == DW_IM & d_write_count != 4'd8)
		 | (state == DMW_IM & d_write_count != 4'd8) /*write will only increment after d_miss_count == 8*/) ? d_addr_next : 16'd0; 

wire [15:0] i_addr_next_out, d_addr_next_out;

Register I_ADDR_REG_DELAY(.clk(clk), .rst(rst), .D(i_addr_next), .WriteReg(mem_data_valid), .ReadEnable1(1'b1), .Readenable2(1'b0), .Bitline1(i_addr_next_out), .Bitline2());
Register D_ADDR_REG_DELAY(.clk(clk), .rst(rst), .D(d_addr_next), .WriteReg(mem_data_valid), .ReadEnable1(1'b1), .Readenable2(1'b0), .Bitline1(d_addr_next_out), .Bitline2());
assign i_wb_addr = i_addr_next_out;
assign d_wb_addr = d_addr_next_out;

assign hazard_stall = (state != IDLE) ? 1'b1 : 0; //any time were not idling we must be stalling
//

endmodule