module Sign_Extend(inst, out);
  input [15:0] inst;
  output [15:0] out;
  
  wire [3:0] LWSW_OS; //lw and sw have a 4 bit offset, needs to shift << 1
  assign LWSW_OS = {inst[2:0], 1'b0}; // LW and SW Offset << 1
  assign out = ((inst[15:12] == 4'b1001) | (inst[15:12] == 4'b1000)) ? ({{12{LWSW_OS[3]}},LWSW_OS}) ://check the opcode for either a LW or SW
  			  ({{12{inst[3]}},inst[3:0]}); //default, sign extend the lower 4 bits to 16
endmodule

