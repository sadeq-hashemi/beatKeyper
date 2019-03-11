
module cache_fill_FSM (clk, rst, miss_detected, miss_address, fsm_busy, write_data_array,
			 write_tag_array,memory_address, memory_data, memory_data_valid);

//  data/address 16 bits
//  cache 2 KB
//  memory 64 KB
//  block size 2 bytes

input clk, rst;

input miss_detected; // active high when tag match logic detects a miss

input [15:0]miss_address; // address that missed the cache
input [15:0] memory_data; // data returned by memory (after  delay)
input memory_data_valid; // active high indicates valid data returning on memory bus

output fsm_busy; // asserted while FSM is busy handling the miss (can be used as pipeline stall signal)
output write_data_array; // write enable to cache data array to signal when filling with memory_data
output write_tag_array; // write enable to cache tag array to write tag and valid bit once all words are filled in to data array
output [15:0] memory_address; // address to read from memory

wire state;
wire state_next;
wire received; 
//wire [4:0] counter_next;
//wire [4:0] counter; //current value for counter
wire [2:0] counter_next;
wire [2:0] counter; //current value for counter
wire increment;

wire [15:0] address_init; //starting address
wire [15:0] address_curr; // current addresswire
wire [15:0] address_inc; // current address
wire [15:0] address_next; // following address
wire addrement; //address increment...get it

localparam IDLE = 1'b0; 
localparam WAIT = 1'b1;
localparam BYTE_INCREMENT = 16'd2; 
localparam RECEIVED = 3'd7; //counter value that should signal end 


  BitCell fsm_state( .clk(clk), .rst(rst), .D(state_next), .WriteEnable(1'b1), .ReadEnable1(1'b1), 
			.ReadEnable2(1'b0), .Bitline1(state), .Bitline2());

//adder for address
  adder_16bit address_adder(.A(address_curr), .B(address_inc), .sub(1'b0), .Sum(address_inc), .Ovfl());
  assign address_next = (state==IDLE & state_next==WAIT) ? miss_address : address_inc; 
  assign addrement =(state == WAIT & memory_data_valid) ? 1'b1 : 1'b0;
  Register addr_reg( .clk(clk), .rst(rst), .D(address_next), .WriteReg(addrement), .ReadEnable1(1'b1),
	 .Readenable2(1'b0), .Bitline1(address_curr), .Bitline2());

//counter that counts to 7 
  //adder_5bit counter_adder(.A(counter_in), .B(1'b1), .Sum(counter_out));
  adder_3bit counter_adder(.A(counter), .B(3'b1), .Sum(counter_next));


//holds count value;
  //Register_5Bit counter_reg( .clk(clk), .rst(!rst_n), .D(counter_out), .WriteReg(3'b111), 
  //			.ReadEnable1(1'b1), .Readenable2(1'b0), .Bitline1(counter_val:),);
  Register_3Bit counter_reg( .clk(clk), .rst(rst), .D(counter_next), .WriteReg(increment), 
			.ReadEnable1(1'b1), .Readenable2(1'b0), .Bitline1(counter), .Bitline2());

  Register address_reg( .clk(clk),  .rst(rst), .D(), .WriteReg(addrement), .ReadEnable1(1'b1), 
	.Readenable2(), .Bitline1(), .Bitline2());
  assign state_next = (state == IDLE) ? 
		//IDLE
 			(miss_detected == 1) ? WAIT : IDLE : 
		//WAIT
			(counter == RECEIVED) ? IDLE : WAIT;


  assign increment = (state == WAIT & memory_data_valid ) ? 1'b1 : 1'b0; 
  assign fsm_busy = (state_next == IDLE) ? 1'b0 : 1'b1; 
  assign write_tag_array = (state == WAIT & state_next == IDLE) ? 1'b1 : 1'b0;
  assign write_data_array = memory_data_valid;
  
endmodule

//==================================================================
module adder_5bit(A, B, Sum);

input [4:0]A, B;

wire [5:1] Cout;
wire [4:0] B_xor;
output [4:0] Sum;

xor (B_xor[0], B[0], 1'b0);
xor (B_xor[1], B[1], 1'b0);
xor (B_xor[2], B[2], 1'b0);
xor (B_xor[3], B[3], 1'b0);
xor (B_xor[4], B[4], 1'b0);


full_adder_1bit FA1 (A[0],B_xor[0], 1'b0, Sum[0], Cout[1]);
full_adder_1bit FA2 (A[1],B_xor[1], Cout[1], Sum[1], Cout[2]);
full_adder_1bit FA3 (A[2],B_xor[2], Cout[2], Sum[2], Cout[3]);
full_adder_1bit FA4 (A[3],B_xor[3], Cout[3], Sum[3], Cout[4]);
full_adder_1bit FA5 (A[4],B_xor[4], Cout[4], Sum[4], Cout[5]);


endmodule

module Register_5Bit( input clk,  input rst, input [4:0] D, input WriteReg,
	 input ReadEnable1, input Readenable2, inout [4:0] Bitline1, inout [5:0] Bitline2);
  
  BitCell bit0(.clk(clk), .rst(rst), .D(D[0]), .WriteEnable(WriteReg), .ReadEnable1(ReadEnable1),
	 .ReadEnable2(Readenable2), .Bitline1(Bitline1[0]), .Bitline2(Bitline2[0]));
 
  BitCell bit1(.clk(clk), .rst(rst), .D(D[1]), .WriteEnable(WriteReg), .ReadEnable1(ReadEnable1),
	 .ReadEnable2(Readenable2), .Bitline1(Bitline1[1]), .Bitline2(Bitline2[1]));
  
  BitCell bit2(.clk(clk), .rst(rst), .D(D[2]), .WriteEnable(WriteReg), .ReadEnable1(ReadEnable1),
	 .ReadEnable2(Readenable2), .Bitline1(Bitline1[2]), .Bitline2(Bitline2[2]));

  BitCell bit3(.clk(clk), .rst(rst), .D(D[3]), .WriteEnable(WriteReg), .ReadEnable1(ReadEnable1),
	 .ReadEnable2(Readenable2), .Bitline1(Bitline1[3]), .Bitline2(Bitline2[3]));

  BitCell bit4(.clk(clk), .rst(rst), .D(D[4]), .WriteEnable(WriteReg), .ReadEnable1(ReadEnable1),
	 .ReadEnable2(Readenable2), .Bitline1(Bitline1[4]), .Bitline2(Bitline2[4]));

  
  endmodule

module adder_3bit(A, B, Sum);

input [2:0]A, B;

wire [3:1] Cout;
wire [2:0] B_xor;
output [2:0] Sum;

xor (B_xor[0], B[0], 1'b0);
xor (B_xor[1], B[1], 1'b0);
xor (B_xor[2], B[2], 1'b0);

full_adder_1bit FA1 (A[0],B[0], 1'b0, Sum[0], Cout[1]);
full_adder_1bit FA2 (A[1],B[1], Cout[1], Sum[1], Cout[2]);
full_adder_1bit FA3 (A[2],B[2], Cout[2], Sum[2], Cout[3]);

endmodule
module adder_4bit(A, B, Sum);

input [3:0]A, B;

wire [4:1] Cout;
wire [3:0] B_xor;
output [3:0] Sum;

xor (B_xor[0], B[0], 1'b0);
xor (B_xor[1], B[1], 1'b0);
xor (B_xor[2], B[2], 1'b0);
xor (B_xor[3], B[3], 1'b0);

full_adder_1bit FA1 (A[0],B_xor[0], 1'b0, Sum[0], Cout[1]);
full_adder_1bit FA2 (A[1],B_xor[1], Cout[1], Sum[1], Cout[2]);
full_adder_1bit FA3 (A[2],B_xor[2], Cout[2], Sum[2], Cout[3]);
full_adder_1bit FA4 (A[3],B_xor[3], Cout[3], Sum[3], Cout[4]);
endmodule

module Register_3Bit_counter( input clk,  input rst, input [2:0] D, input WriteReg,
	 input ReadEnable1, input Readenable2, inout [2:0] Bitline1, inout [2:0] Bitline2);
  
  BitCell bit0(.clk(clk), .rst(rst), .D(D[0]), .WriteEnable(WriteReg), .ReadEnable1(ReadEnable1),
	 .ReadEnable2(Readenable2), .Bitline1(Bitline1[0]), .Bitline2(Bitline2[0]));
 
  BitCell bit1(.clk(clk), .rst(rst), .D(D[1]), .WriteEnable(WriteReg), .ReadEnable1(ReadEnable1),
	 .ReadEnable2(Readenable2), .Bitline1(Bitline1[1]), .Bitline2(Bitline2[1]));
  
  BitCell bit2(.clk(clk), .rst(rst), .D(D[2]), .WriteEnable(WriteReg), .ReadEnable1(ReadEnable1),
	 .ReadEnable2(Readenable2), .Bitline1(Bitline1[2]), .Bitline2(Bitline2[2]));

   endmodule



