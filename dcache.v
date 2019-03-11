module D_cache ( clk, rst, 
		enable, wr, addr, data_in, 	//input from CPU 
		D_data_valid, D_data_in, 	//input from MEM_arbitrary
		D_miss, D_wr, D_addr, D_data_out, txn_done, D_disable, //output to MEM_arbitrary
		data_out, state_out 			//output to CPU
		);

//--------------address constants--------------//
parameter ADDR_WIDTH = 16;
parameter PAGE_OFFSET = 4; //4 bits 
parameter VPN = 7; //7 bits 
parameter TAG = 5; //5 bits
parameter BYTE = 8; 
parameter ZERO_OFFSET = 4'b0000; 

//--------------fsm constants--------------//
parameter HIT = 1'b0; 
parameter MISS = 1'b1;
parameter BYTE_INCREMENT = 16'h0002; 
parameter RECEIVED = 4'd8; 	//counter value that should signal end 
parameter RECEIVED_txn = 4'd7; 	//counter value that should signal end 
parameter ZERO = 4'd0; 		//counter value that should signal end 

//--------------input--------------//
input clk, rst; 
input wr, enable; 
input [15:0] data_in, addr;

input D_data_valid; 		// data valid signal coming from memory
input [15:0] D_data_in; 

//--------------output--------------//
output [15:0] data_out; 	//data that will be fed to pipeline
output [15:0] D_data_out; 	//data that will be fed to memory
output [ADDR_WIDTH - 1:0] D_addr; //address that will be fed to memory for read or write
output D_miss, txn_done, D_disable; 			//miss signal for memory
output D_wr; 			//write signal for memory
output state_out;
//--------------fsm signals--------------//
wire meta; 			//signal for the tag existing
wire fsm_busy; 			//signal for busy (aka stall) TODO
wire wr_tag;			 //signal that the tag needs to be rewritten

//--------------counter signals--------------// 
wire [3:0] rcv_count; 		// receive counter tracking number of data valids
wire [3:0] rcv_count_next;	//next receive counter
wire [3:0] rcv_count_inc;	// rcv_count + 2; 
wire [3:0] txn_count; 		//transaction counter tracking number of address increments
wire [3:0] txn_count_next; 	//next transaction counter
wire [3:0] txn_count_inc; 	// txn_count + 2;
//--------------miss address signals--------------//
wire [ADDR_WIDTH - 1:0] txn_addr;
wire [ADDR_WIDTH - 1:0] txn_addr_next;
wire [ADDR_WIDTH - 1:0] txn_addr_inc;
wire [ADDR_WIDTH - 1:0] rcv_addr;
wire [ADDR_WIDTH - 1:0] rcv_addr_next;
wire [ADDR_WIDTH - 1:0] rcv_addr_inc;
wire [15:0] updated_rcv;
//--------------state signals--------------//
wire state;
wire state_next;
assign state_out = state;
//--------------interwires--------------//
wire [VPN - 1:0] vpn; 
wire [TAG - 1:0] tag;
wire [PAGE_OFFSET - 1:0] page_offset;

wire [VPN - 1:0] vpn_addr; 
wire [TAG - 1:0] tag_addr;
wire [PAGE_OFFSET - 1:0] page_offset_addr;

wire [VPN - 1:0] vpn_txn; 
wire [TAG - 1:0] tag_txn;
wire [PAGE_OFFSET - 1:0] page_offset_txn;

wire [VPN - 1:0] vpn_rcv; 
wire [TAG - 1:0] tag_rcv;
wire [PAGE_OFFSET - 1:0] page_offset_rcv;

wire [VPN - 1:0] vpn_base; 
wire [TAG - 1:0] tag_base;
wire [PAGE_OFFSET - 1:0] page_offset_base;

wire [BYTE - 1 : 0] meta_in; 		//aka expected meta
wire [BYTE - 1 : 0] meta_out; 
wire [127:0]	Blockenable; 		//one hot block enable
wire [7:0] WordEnable; 		//one hot word enable
wire [15:0] DataIn;

//===================================================================================================
//-------------state-----------------//
  assign state_next = (state == HIT) ? 
		//HIT 
 		(enable & !meta) ? MISS : HIT :
		//MISS 
		(rcv_count == RECEIVED) ? HIT : MISS; 

BitCell state_reg( .clk(clk),   .rst(rst),  .D(state_next),  .WriteEnable(1'b1),  .ReadEnable1(1'b1),  .ReadEnable2(1'b0),  .Bitline1(state),  .Bitline2() );

//-------------counters---------------//
assign rcv_count_next = (state == HIT & state_next == MISS) ? ZERO : rcv_count_inc; 
assign rcv_increment = state==MISS & D_data_valid & rcv_count != RECEIVED; 
Reg_4_Bit rcv_counter_reg( .clk(clk), .rst(rst | (state == HIT)), .D(rcv_count_next), .WriteReg(rcv_increment), 
			.ReadEnable1(1'b1), .Readenable2(1'b0), .Bitline1(rcv_count), .Bitline2());
CAE_Adder_4bit rcv_counter_adder(.a(rcv_count), .b(4'b0001), .cin(1'b0), .sum(rcv_count_inc), .p_out(), .g_out());

assign txn_count_next = (state == HIT & state_next == MISS) ? ZERO : txn_count_inc; 
assign txn_increment = state_next==MISS & txn_count != RECEIVED; 
Reg_4_Bit txn_counter_reg( .clk(clk), .rst(rst | (state == HIT)), .D(txn_count_next), .WriteReg(txn_increment), 
			.ReadEnable1(1'b1), .Readenable2(1'b0), .Bitline1(txn_count), .Bitline2());
CAE_Adder_4bit txn_counter_adder(.a(txn_count), .b(4'b0001), .cin(1'b0), .sum(txn_count_inc), .p_out(), .g_out());



//-------------miss addr calculation-----------------//
assign txn_addr_next = (/*state == MISS & txn_count == 4'd0*/ state == HIT & state_next == MISS) ? {vpn_base, tag_base, page_offset_base} : txn_addr_inc; 
assign txn_addrement = (state_next == MISS & ( txn_count != RECEIVED_txn | txn_count != RECEIVED ) ) ? 1'b1 : 1'b0;
Register txn_addr_reg( .clk(clk), .rst(rst), .D(txn_addr_next), .WriteReg(txn_addrement), .ReadEnable1(1'b1),
	.Readenable2(1'b0), .Bitline1(txn_addr), .Bitline2());
CLA_Adder txn_cla_adder(.a(txn_addr), .b(BYTE_INCREMENT), .sub(1'b0), .cout(), .sum(txn_addr_inc), .ovfl());


assign rcv_addr_next = (state == HIT & state_next == MISS) ? {vpn_base, tag_base, page_offset_base} : rcv_addr_inc; 
assign rcv_addrement = (state_next==MISS & D_data_valid & rcv_count != RECEIVED) ? 1'b1 : 1'b0;
//Register rcv_addr_reg( .clk(clk), .rst(rst), .D(rcv_addr_next), .WriteReg(rcv_addrement), .ReadEnable1(1'b1),
	//.Readenable2(1'b0), .Bitline1(rcv_addr), .Bitline2());=
CLA_Adder rcv_cla_adder(.a(rcv_addr), .b(BYTE_INCREMENT), .sub(1'b0), .cout(), .sum(rcv_addr_inc), .ovfl());

Register rcv_addr_reg( .clk(clk), .rst(rst), .D(rcv_addr_inc), .WriteReg(rcv_addrement), .ReadEnable1(1'b1),
	.Readenable2(1'b0), .Bitline1(updated_rcv), .Bitline2());

assign rcv_addr = (/*rcv_addrement & */rcv_count != 4'd0)? updated_rcv : {vpn_base, tag_base, page_offset_base} ;
//--------------fsm controls--------------//
assign fsm_busy = (state != HIT) ? 1'b1 : 1'b0; 
assign wr_tag = (state==MISS & (state_next== HIT)) ? 1'b1  : 1'b0; 

//--------------addr split--------------//
assign vpn_addr = addr[ADDR_WIDTH-1: ADDR_WIDTH - VPN];
assign tag_addr = addr[ADDR_WIDTH - VPN - 1: (ADDR_WIDTH - VPN) - TAG];
assign page_offset_addr =  addr[ADDR_WIDTH - VPN - TAG - 1: 0];

assign vpn_txn = txn_addr[ADDR_WIDTH-1: ADDR_WIDTH - VPN];
assign tag_txn = txn_addr[ADDR_WIDTH - VPN - 1: (ADDR_WIDTH - VPN) - TAG];
assign page_offset_txn =  txn_addr[ADDR_WIDTH - VPN - TAG - 1: 0];

assign vpn_rcv = rcv_addr[ADDR_WIDTH-1: ADDR_WIDTH - VPN];
assign tag_rcv = rcv_addr[ADDR_WIDTH - VPN - 1: (ADDR_WIDTH - VPN) - TAG];
assign page_offset_rcv =  rcv_addr[ADDR_WIDTH - VPN - TAG - 1: 0];

assign vpn_base = addr[ADDR_WIDTH-1: ADDR_WIDTH - VPN];
assign tag_base = addr[ADDR_WIDTH - VPN - 1: (ADDR_WIDTH - VPN) - TAG];
assign page_offset_base =  {ADDR_WIDTH - VPN - TAG{1'b0}};

//--------------meta calculation--------------//
assign meta_in = {1'b1, 1'b1, 1'b1, tag_addr}; 	// meta:  VALID  | DIRTY | REF | 5 bit TAG 
MetaDataArray meta_array(.clk(clk), .rst(rst), .DataIn(meta_in), .Write(wr_tag), .BlockEnable(Blockenable), .DataOut(meta_out));
assign meta = !wr_tag & meta_in == meta_out;	//miss if the meta that we have stored does not match what we we would store 
						//will need to be changed after dirty and ref

//--------------cache logic--------------//
assign vpn = state_next == MISS ? vpn_rcv : vpn_addr; 
assign tag = state_next == MISS ? tag_rcv : tag_addr; 
assign page_offset = state_next == MISS ? page_offset_rcv : page_offset_addr; 

//CHECK TODO
assign DataIn = state_next==HIT ? data_in : D_data_in; 
SLL_128 shift_blocken(.shift_in(128'b1), .shift_val(vpn), .shift_out(Blockenable));
SLL_8 shift_worden(.shift_in(8'h01), .shift_val(page_offset[PAGE_OFFSET - 1: 1]), .shift_out(WordEnable)); //every word is 2 bytes
DataArray darray(.clk(clk), .rst(rst), .DataIn(DataIn), .Write( (state_next == HIT & wr) | rcv_increment ) /*feed_cache | feed_mem*/, .BlockEnable(Blockenable),
	 .WordEnable(WordEnable), .DataOut(data_out)); 


//--------------mem out--------------//
assign D_miss = (/*state == MISS |*/  state_next == MISS) ? 1'b1 : 1'b0;
//assign D_miss = !meta; 
assign D_wr = state_next==HIT | (state == HIT & state_next == HIT)? wr : 1'b0; 
assign D_data_out = data_in;
assign D_addr = state_next == HIT ? addr : txn_addr; //TODO 
assign txn_done = (state == HIT | (state != HIT & txn_count == RECEIVED_txn)); 
assign D_disable = txn_count == RECEIVED ; 
endmodule


