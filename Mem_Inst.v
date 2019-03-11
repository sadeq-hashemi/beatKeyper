module Data_Mem(ReadData2, inst, addr, w_data, r_data, MemRead, MemWrite, clk, rst,
				mems_data_out);
  input clk, rst;
  input MemRead, MemWrite; //Control Logic
  input [15:0] ReadData2, inst, mems_data_out; //used for LLB and LHB, assume ReadData2 is Reg2 and inst is the full inst
  input [15:0] addr, w_data; //addr = where to read or write, w_data = data we are actually writing 

  output [15:0] r_data; //Output

//  wire [15:0] zero_addr; //The ALU adds Reg[Rs] + Offset << 1, we need to get this addr[0] to be zero when reading mem
  //wire [15:0] data_out; //Stores the value we read in the case of a LW
  wire [15:0] set_reg; //Stores the LLB or LHB output
  wire enable; //Used to enable the DATA_MEM

  /*
  DATA MEM LOGIC
  enable wr  Function       data_out 
  0      X   No operation   0 
  1      0   Read M[addr]   M[addr]
  1      1   Write data_in  0 
  */
  //LW receives the control sigs MemRead = 1 and MemWrite = 0
  //SW receives the control sigs MemRead = 0 and MemWrite = 1
  assign enable = (MemRead | MemWrite); //The only case we aren't enabled is when we aren't reading or writing
 // assign zero_addr = addr & 16'hFFFE; //set bit 0 to zero
 // memory1c DATA(.data_out(data_out), .data_in(w_data), .addr(zero_addr), .enable(enable), .wr(MemWrite), .clk(clk), .rst(rst));

  //1011 = LHB and 1010 = LLB.
  assign set_reg = (inst[15:12] == 4'b1011) ? ((ReadData2 & 16'hFF00) | ({8'h00, inst[7:0]})) : //LLB, clear upper 8 bits and set with offset
						((ReadData2 & 16'h00FF) | ({inst[7:0], 8'h00})); //LHb clear upper 8 bits

  //set the output based LW or LLB/LHB
  assign r_data = (enable) ? (mems_data_out) : //LW or SW
				   set_reg; //LLB or LHB

endmodule

