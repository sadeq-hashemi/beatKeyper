
//module cache_temp (data_valid, data_in, meta, addr, enable, wr, clk, rst); //test

module cache_temp ( mem_wr, mem_miss, mem_addr_out, mem_data_out, // these four go to fsm controller
		    mem_addr_in, mem_data_in, data_valid, // these three come from the fsm controller
		    data_out, // this goes to the cpu
                    data_in, addr, enable, wr, // These four all come from the cpu 
		    clk, rst, stall);

input clk, rst; 
input wr, enable; 
input [15:0] data_in, addr;

input data_valid; // data valid signal coming from memory
input [15:0] mem_data_in;
input [15:0] mem_addr_in;

//--------------address constants--------------//
parameter ADDR_WIDTH = 16;
parameter PAGE_OFFSET = 4; //4 bits 
parameter VPN = 7; //7 bits 
parameter TAG = 5; //5 bits
parameter BYTE = 8; 
parameter ZERO_OFFSET = 4'b0000; 

//--------------fsm constants--------------//
localparam HIT = 2'b00; 
localparam MISS = 2'b01;
localparam WR = 2'b10;
localparam NA = 2'b11;
localparam BYTE_INCREMENT = 16'h0002; 
localparam RECEIVED = 4'd8; //counter value that should signal end 
localparam ZERO = 4'd0; //counter value that should signal end 

//--------------fsm signals--------------//
wire meta; //signal for the tag existing
wire fsm_miss; //signal for a miss
wire fsm_wr; //signal for a miss
wire fsm_busy; //signal for busy (aka stall)
wire wr_tag; //signal that the tag needs to be rewritten
wire feed_cache; //signals the cache needs to be updated 
wire feed_mem; //signals the mem to be updated
wire data_valid; //signal that data coming from mem is valid

//--------------counter signals--------------//
wire increment_miss; 
wire increment_wr; 
wire increment; 
wire [3:0] count; //current address
wire [3:0] count_next; //current address
//wire [3:0] count_base; //base address
wire [3:0] count_inc; // count + 2; 

//--------------write address signals--------------//
wire [ADDR_WIDTH - 1:0]addr_inc;
wire [ADDR_WIDTH - 1:0]wr_addr;
wire [ADDR_WIDTH - 1:0] addr_next;

//--------------state signals--------------//
wire [1:0] state;
wire [1:0] state_next;

//--------------interwires--------------//
wire [VPN - 1:0] vpn; 
wire [TAG - 1:0] tag;
wire [PAGE_OFFSET - 1:0] page_offset;
wire [VPN - 1:0] vpn_addr; 
wire [TAG - 1:0] tag_addr;
wire [PAGE_OFFSET - 1:0] page_offset_addr;
wire [VPN - 1:0] vpn_mem; 
wire [TAG - 1:0] tag_mem;
wire [PAGE_OFFSET - 1:0] page_offset_mem;
wire [VPN - 1:0] vpn_wr; 
wire [TAG - 1:0] tag_wr;
wire [PAGE_OFFSET - 1:0] page_offset_wr;
wire [VPN - 1:0] vpn_base; 
wire [TAG - 1:0] tag_base;
wire [PAGE_OFFSET - 1:0] page_offset_base;
wire [BYTE - 1 : 0] meta_in; //aka expected meta
wire [BYTE - 1 : 0] meta_out; 
wire [127:0]	Blockenable; //one hot block enable
wire [7:0] WordEnable; //one hot word enable
wire [15:0] data_write;

//--------------output--------------//
output stall; 
output [15:0] data_out; //data that will be fed to pipeline
output [15:0] mem_data_out; //data that will be fed to memory
output [ADDR_WIDTH - 1:0] mem_addr_out; //address that will be fed to memory for read or write
output mem_miss; //miss signal for memory
output mem_wr; //write signal for memory
//=====================================
//-------------state-----------------//
  assign state_next = (state == HIT) ? 
		//HIT 
 		(enable & !meta) ? MISS : (enable & meta & wr) ? WR : HIT :
		//MISS 
		(state == MISS) ? (!wr & count == RECEIVED) ? HIT : (wr & count == RECEIVED) ? WR : MISS : 
		//WRITE
		(state == WR) ? (count == RECEIVED) ? HIT : WR :
			NA; // should never get here 

Reg_2_Bit fsm_state( .clk(clk), .rst(rst), .D(state_next), .WriteReg(1'b1), .ReadEnable1(1'b1), 
			.Readenable2(1'b0), .Bitline1(state), .Bitline2());



//-------------counter-----------------//
assign count_next = count_inc; //(state == HIT) ? ZERO : count_inc; //resets if in hit
assign increment_miss = (state == MISS & data_valid) ? 1'b1 : 1'b0; 
assign increment_wr = (state == WR) ? 1'b1 : 1'b0; 
assign increment = increment_miss | increment_wr; 
Reg_4_Bit counter_reg( .clk(clk), .rst(rst | (state == HIT) | (state==MISS & state_next==WR)), .D(count_next), .WriteReg(increment), 
			.ReadEnable1(1'b1), .Readenable2(1'b0), .Bitline1(count), .Bitline2());
CAE_Adder_4bit counter_adder(.a(count), .b(4'b0001), .cin(1'b0), .sum(count_inc), .p_out(), .g_out());

//-------------write addr calculation-----------------//
assign addr_next = (state != WR & state_next == WR) ? {vpn_base, tag_base, page_offset_base} : addr_inc; 
assign addrement = (state_next == WR /*& data_valid*/) ? 1'b1 : 1'b0;
Register addr_reg( .clk(clk), .rst(rst), .D(addr_next), .WriteReg(addrement), .ReadEnable1(1'b1),
	.Readenable2(1'b0), .Bitline1(wr_addr), .Bitline2());
CLA_Adder cla_adder(.a(wr_addr), .b(BYTE_INCREMENT), .sub(1'b0), .cout(), .sum(addr_inc), .ovfl());



//--------------fsm controls--------------//
assign fsm_miss = (state == MISS | state_next == MISS) ? 1'b1 : 1'b0; 
//assign fsm_wr = (state == WR | state_next == WR) ? 1'b1 : 1'b0; 
assign fsm_wr = (wr) ? 1'b1 : 1'b0; 

assign fsm_busy = (state != HIT) ? 1'b1 : 1'b0; 
assign feed_cache = (state == MISS & increment_miss) ? 1'b1 : 1'b0; 
assign feed_mem =  (state == WR & increment_wr) ? 1'b1 : 1'b0; 
assign wr_tag = (state==MISS & (state_next== HIT | state_next == WR)) ? 1'b1  : 1'b0; 

//--------------addr split--------------//
assign vpn_addr = addr[ADDR_WIDTH-1: ADDR_WIDTH - VPN];
assign tag_addr = addr[ADDR_WIDTH - VPN - 1: (ADDR_WIDTH - VPN) - TAG];
assign page_offset_addr =  addr[ADDR_WIDTH - VPN - TAG - 1: 0];
 
assign vpn_mem = mem_addr_in[ADDR_WIDTH-1: ADDR_WIDTH - VPN];
assign tag_mem = mem_addr_in[ADDR_WIDTH - VPN - 1: (ADDR_WIDTH - VPN) - TAG];
assign page_offset_mem =  mem_addr_in[ADDR_WIDTH - VPN - TAG - 1: 0]; 

assign vpn_wr = wr_addr[ADDR_WIDTH-1: ADDR_WIDTH - VPN];
assign tag_wr = wr_addr[ADDR_WIDTH - VPN - 1: (ADDR_WIDTH - VPN) - TAG];
assign page_offset_wr =  wr_addr[ADDR_WIDTH - VPN - TAG - 1: 0];

assign vpn_base = addr[ADDR_WIDTH-1: ADDR_WIDTH - VPN];
assign tag_base = addr[ADDR_WIDTH - VPN - 1: (ADDR_WIDTH - VPN) - TAG];
assign page_offset_base =  {ADDR_WIDTH - VPN - TAG{1'b0}};
//--------------meta calculation--------------//
assign meta_in = {1'b1, 1'b1, 1'b1, tag_addr}; // meta:  VALID  | DIRTY | REF | 5 bit TAG 
MetaDataArray meta_array(.clk(clk), .rst(rst), .DataIn(meta_in), .Write(wr_tag), .BlockEnable(Blockenable), .DataOut(meta_out));
assign meta = (!wr_tag & meta_in == meta_out)  ? 1'b1: 1'b0;	 //miss if the meta that we have stored does not match what we we would store 
							 //will need to be changed after dirty and ref
//--------------cache logic--------------//
//assign vpn = feed_cache ? vpn_mem : feed_mem? vpn_wr : vpn_addr; 
//assign tag = feed_cache ? tag_mem : feed_mem? tag_wr : tag_addr; 
//assign page_offset = feed_cache ? page_offset_mem : feed_mem? page_offset_wr : page_offset_addr; 

assign vpn = state_next == MISS ? vpn_mem : state == WR ? vpn_wr : vpn_addr; 
assign tag = state_next == MISS ? tag_mem : state == WR ? tag_wr : tag_addr; 
assign page_offset = state_next == MISS ? page_offset_mem : state == WR ? page_offset_wr : page_offset_addr; 


assign data_write = feed_cache ? mem_data_in :  data_in; 
SLL_128 shift_blocken(.shift_in(128'b1), .shift_val(vpn), .shift_out(Blockenable));
SLL_8 shift_worden(.shift_in(8'h01), .shift_val(page_offset[PAGE_OFFSET - 1: 1]), .shift_out(WordEnable)); //every word is 2 bytes
DataArray darray(.clk(clk), .rst(rst), .DataIn(data_write), .Write(state_next == MISS | (state != WR & state_next == WR)/*feed_cache | feed_mem*/), .BlockEnable(Blockenable),
	 .WordEnable(WordEnable), .DataOut(data_out)); //TODO: Wordenable?


//--------------mem logic--------------//
assign mem_data_out = data_out; 
assign mem_addr_out= fsm_miss ? {vpn_base, tag_base, page_offset_base}  : wr_addr; 
assign mem_miss = fsm_miss;
assign mem_wr = fsm_wr;
//--------------output--------------//
assign mem_addr = {tag, vpn, ZERO_OFFSET}; //recalculated address for page alignment
//assign stall =  fsm_busy ;
assign stall =  state_next != HIT ; 
endmodule


