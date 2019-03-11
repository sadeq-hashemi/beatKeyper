module dff (q, d, wen, clk, rst);

    output         q; //DFF output
    input          d; //DFF input
    input 	   wen; //Write Enable
    input          clk; //Clock
    input          rst; //Reset (used synchronously)

    reg            state;

    assign q = state;

    always @(posedge clk) begin
      state = rst ? 0 : (wen ? d : state);
    end

endmodule

module ReadDecoder_4_16(input [3:0] RegId, output [15:0] Wordline);
  assign Wordline[15:0] = (RegId == 0) ? 16'h0001 :
			  (RegId == 1) ? 16'h0002 :
			  (RegId == 2) ? 16'h0004 :
			  (RegId == 3) ? 16'h0008 :
			  (RegId == 4) ? 16'h0010 :
			  (RegId == 5) ? 16'h0020 :
			  (RegId == 6) ? 16'h0040 :
			  (RegId == 7) ? 16'h0080 :
			  (RegId == 8) ? 16'h0100 :
			  (RegId == 9) ? 16'h0200 :
			  (RegId == 10) ? 16'h0400 :			
			  (RegId == 11) ? 16'h0800 :
			  (RegId == 12) ? 16'h1000 :
			  (RegId == 13) ? 16'h2000 :
			  (RegId == 14) ? 16'h4000 :
			  16'h8000;
endmodule

module WriteDecoder_4_16(input [3:0] RegId, input WriteReg, output [15:0] Wordline);
 wire [15:0] DecodeOut;
 assign DecodeOut[15:0] = (RegId == 0) ? 16'h0001 :
			  (RegId == 1) ? 16'h0002 :
			  (RegId == 2) ? 16'h0004 :
			  (RegId == 3) ? 16'h0008 :
			  (RegId == 4) ? 16'h0010 :
			  (RegId == 5) ? 16'h0020 :
			  (RegId == 6) ? 16'h0040 :
			  (RegId == 7) ? 16'h0080 :
			  (RegId == 8) ? 16'h0100 :
			  (RegId == 9) ? 16'h0200 :
			  (RegId == 10) ? 16'h0400 :			
			  (RegId == 11) ? 16'h0800 :
			  (RegId == 12) ? 16'h1000 :
			  (RegId == 13) ? 16'h2000 :
			  (RegId == 14) ? 16'h4000 :
			  16'h8000;
  assign Wordline[15:0] = (WriteReg) ? DecodeOut : 16'h0000;
endmodule

module BitCell( input clk,  input rst, input D, input WriteEnable, input ReadEnable1, input ReadEnable2, inout Bitline1, inout Bitline2);
 wire Q, out1, out2;
 dff flop(.q(Q), .d(D), .wen(WriteEnable), .clk(clk), .rst(rst));
 //assign out1 = (WriteEnable & ReadEnable1) ? D : Q;
 //assign out2 = (WriteEnable & ReadEnable2) ? D : Q;
 assign out1 = Q;
 assign out2 = Q;
 assign Bitline1 = (ReadEnable1) ? out1 : 1'bz;
 assign Bitline2 = (ReadEnable2) ? out2 : 1'bz;
endmodule

module BitCell_bp( input clk,  input rst, input D, input WriteEnable, input ReadEnable1, input ReadEnable2, inout Bitline1, inout Bitline2);
 wire Q, out1, out2;
 dff flop(.q(Q), .d(D), .wen(WriteEnable), .clk(clk), .rst(rst));
 assign out1 = (WriteEnable & ReadEnable1) ? D : Q;
 assign out2 = (WriteEnable & ReadEnable2) ? D : Q;
 //assign out1 = Q;
 //assign out2 = Q;
 assign Bitline1 = (ReadEnable1) ? out1 : 1'bz;
 assign Bitline2 = (ReadEnable2) ? out2 : 1'bz;
endmodule

module Register_3Bit( input clk,  input rst, input [2:0] D, input [2:0] WriteReg, input ReadEnable1, input Readenable2, inout [2:0] Bitline1, inout [2:0] Bitline2);
  //Z
  BitCell bit0(.clk(clk), .rst(rst), .D(D[0]), .WriteEnable(WriteReg[0]), .ReadEnable1(ReadEnable1), .ReadEnable2(Readenable2), .Bitline1(Bitline1[0]), .Bitline2(Bitline2[0]));
  //V
  BitCell bit1(.clk(clk), .rst(rst), .D(D[1]), .WriteEnable(WriteReg[1]), .ReadEnable1(ReadEnable1), .ReadEnable2(Readenable2), .Bitline1(Bitline1[1]), .Bitline2(Bitline2[1]));
  //N
  BitCell bit2(.clk(clk), .rst(rst), .D(D[2]), .WriteEnable(WriteReg[2]), .ReadEnable1(ReadEnable1), .ReadEnable2(Readenable2), .Bitline1(Bitline1[2]), .Bitline2(Bitline2[2]));
  endmodule

module Reg_2_Bit( input clk,  input rst, input [1:0] D, input WriteReg, input ReadEnable1, input Readenable2, inout [1:0] Bitline1, inout [1:0] Bitline2);
	BitCell bit[1:0](.clk(clk), .rst(rst), .D(D), .WriteEnable(WriteReg), .ReadEnable1(ReadEnable1), .ReadEnable2(Readenable2), .Bitline1(Bitline1), .Bitline2(Bitline2));
endmodule

module Reg_3_Bit( input clk,  input rst, input [2:0] D, input WriteReg, input ReadEnable1, input Readenable2, inout [2:0] Bitline1, inout [2:0] Bitline2);
	BitCell bit[2:0](.clk(clk), .rst(rst), .D(D), .WriteEnable(WriteReg), .ReadEnable1(ReadEnable1), .ReadEnable2(Readenable2), .Bitline1(Bitline1), .Bitline2(Bitline2));
endmodule

module Reg_4_Bit( input clk,  input rst, input [3:0] D, input WriteReg, input ReadEnable1, input Readenable2, inout [3:0] Bitline1, inout [3:0] Bitline2);
	BitCell bit[3:0](.clk(clk), .rst(rst), .D(D), .WriteEnable(WriteReg), .ReadEnable1(ReadEnable1), .ReadEnable2(Readenable2), .Bitline1(Bitline1), .Bitline2(Bitline2));
endmodule

module Register_bp( input clk,  input rst, input [15:0] D, input WriteReg, input ReadEnable1, input Readenable2, inout [15:0] Bitline1, inout [15:0] Bitline2);
  BitCell_bp bit0(.clk(clk), .rst(rst), .D(D[0]), .WriteEnable(WriteReg), .ReadEnable1(ReadEnable1), .ReadEnable2(Readenable2), .Bitline1(Bitline1[0]), .Bitline2(Bitline2[0]));
  BitCell_bp bit1(.clk(clk), .rst(rst), .D(D[1]), .WriteEnable(WriteReg), .ReadEnable1(ReadEnable1), .ReadEnable2(Readenable2), .Bitline1(Bitline1[1]), .Bitline2(Bitline2[1]));
  BitCell_bp bit2(.clk(clk), .rst(rst), .D(D[2]), .WriteEnable(WriteReg), .ReadEnable1(ReadEnable1), .ReadEnable2(Readenable2), .Bitline1(Bitline1[2]), .Bitline2(Bitline2[2]));
  BitCell_bp bit3(.clk(clk), .rst(rst), .D(D[3]), .WriteEnable(WriteReg), .ReadEnable1(ReadEnable1), .ReadEnable2(Readenable2), .Bitline1(Bitline1[3]), .Bitline2(Bitline2[3]));
  BitCell_bp bit4(.clk(clk), .rst(rst), .D(D[4]), .WriteEnable(WriteReg), .ReadEnable1(ReadEnable1), .ReadEnable2(Readenable2), .Bitline1(Bitline1[4]), .Bitline2(Bitline2[4]));
  BitCell_bp bit5(.clk(clk), .rst(rst), .D(D[5]), .WriteEnable(WriteReg), .ReadEnable1(ReadEnable1), .ReadEnable2(Readenable2), .Bitline1(Bitline1[5]), .Bitline2(Bitline2[5]));
  BitCell_bp bit6(.clk(clk), .rst(rst), .D(D[6]), .WriteEnable(WriteReg), .ReadEnable1(ReadEnable1), .ReadEnable2(Readenable2), .Bitline1(Bitline1[6]), .Bitline2(Bitline2[6]));
  BitCell_bp bit7(.clk(clk), .rst(rst), .D(D[7]), .WriteEnable(WriteReg), .ReadEnable1(ReadEnable1), .ReadEnable2(Readenable2), .Bitline1(Bitline1[7]), .Bitline2(Bitline2[7]));
  BitCell_bp bit8(.clk(clk), .rst(rst), .D(D[8]), .WriteEnable(WriteReg), .ReadEnable1(ReadEnable1), .ReadEnable2(Readenable2), .Bitline1(Bitline1[8]), .Bitline2(Bitline2[8]));
  BitCell_bp bit9(.clk(clk), .rst(rst), .D(D[9]), .WriteEnable(WriteReg), .ReadEnable1(ReadEnable1), .ReadEnable2(Readenable2), .Bitline1(Bitline1[9]), .Bitline2(Bitline2[9]));
  BitCell_bp bit10(.clk(clk), .rst(rst), .D(D[10]), .WriteEnable(WriteReg), .ReadEnable1(ReadEnable1), .ReadEnable2(Readenable2), .Bitline1(Bitline1[10]), .Bitline2(Bitline2[10]));
  BitCell_bp bit11(.clk(clk), .rst(rst), .D(D[11]), .WriteEnable(WriteReg), .ReadEnable1(ReadEnable1), .ReadEnable2(Readenable2), .Bitline1(Bitline1[11]), .Bitline2(Bitline2[11]));
  BitCell_bp bit12(.clk(clk), .rst(rst), .D(D[12]), .WriteEnable(WriteReg), .ReadEnable1(ReadEnable1), .ReadEnable2(Readenable2), .Bitline1(Bitline1[12]), .Bitline2(Bitline2[12]));
  BitCell_bp bit13(.clk(clk), .rst(rst), .D(D[13]), .WriteEnable(WriteReg), .ReadEnable1(ReadEnable1), .ReadEnable2(Readenable2), .Bitline1(Bitline1[13]), .Bitline2(Bitline2[13]));
  BitCell_bp bit14(.clk(clk), .rst(rst), .D(D[14]), .WriteEnable(WriteReg), .ReadEnable1(ReadEnable1), .ReadEnable2(Readenable2), .Bitline1(Bitline1[14]), .Bitline2(Bitline2[14]));
  BitCell_bp bit15(.clk(clk), .rst(rst), .D(D[15]), .WriteEnable(WriteReg), .ReadEnable1(ReadEnable1), .ReadEnable2(Readenable2), .Bitline1(Bitline1[15]), .Bitline2(Bitline2[15]));
endmodule

module Register( input clk,  input rst, input [15:0] D, input WriteReg, input ReadEnable1, input Readenable2, inout [15:0] Bitline1, inout [15:0] Bitline2);
  BitCell bit0(.clk(clk), .rst(rst), .D(D[0]), .WriteEnable(WriteReg), .ReadEnable1(ReadEnable1), .ReadEnable2(Readenable2), .Bitline1(Bitline1[0]), .Bitline2(Bitline2[0]));
  BitCell bit1(.clk(clk), .rst(rst), .D(D[1]), .WriteEnable(WriteReg), .ReadEnable1(ReadEnable1), .ReadEnable2(Readenable2), .Bitline1(Bitline1[1]), .Bitline2(Bitline2[1]));
  BitCell bit2(.clk(clk), .rst(rst), .D(D[2]), .WriteEnable(WriteReg), .ReadEnable1(ReadEnable1), .ReadEnable2(Readenable2), .Bitline1(Bitline1[2]), .Bitline2(Bitline2[2]));
  BitCell bit3(.clk(clk), .rst(rst), .D(D[3]), .WriteEnable(WriteReg), .ReadEnable1(ReadEnable1), .ReadEnable2(Readenable2), .Bitline1(Bitline1[3]), .Bitline2(Bitline2[3]));
  BitCell bit4(.clk(clk), .rst(rst), .D(D[4]), .WriteEnable(WriteReg), .ReadEnable1(ReadEnable1), .ReadEnable2(Readenable2), .Bitline1(Bitline1[4]), .Bitline2(Bitline2[4]));
  BitCell bit5(.clk(clk), .rst(rst), .D(D[5]), .WriteEnable(WriteReg), .ReadEnable1(ReadEnable1), .ReadEnable2(Readenable2), .Bitline1(Bitline1[5]), .Bitline2(Bitline2[5]));
  BitCell bit6(.clk(clk), .rst(rst), .D(D[6]), .WriteEnable(WriteReg), .ReadEnable1(ReadEnable1), .ReadEnable2(Readenable2), .Bitline1(Bitline1[6]), .Bitline2(Bitline2[6]));
  BitCell bit7(.clk(clk), .rst(rst), .D(D[7]), .WriteEnable(WriteReg), .ReadEnable1(ReadEnable1), .ReadEnable2(Readenable2), .Bitline1(Bitline1[7]), .Bitline2(Bitline2[7]));
  BitCell bit8(.clk(clk), .rst(rst), .D(D[8]), .WriteEnable(WriteReg), .ReadEnable1(ReadEnable1), .ReadEnable2(Readenable2), .Bitline1(Bitline1[8]), .Bitline2(Bitline2[8]));
  BitCell bit9(.clk(clk), .rst(rst), .D(D[9]), .WriteEnable(WriteReg), .ReadEnable1(ReadEnable1), .ReadEnable2(Readenable2), .Bitline1(Bitline1[9]), .Bitline2(Bitline2[9]));
  BitCell bit10(.clk(clk), .rst(rst), .D(D[10]), .WriteEnable(WriteReg), .ReadEnable1(ReadEnable1), .ReadEnable2(Readenable2), .Bitline1(Bitline1[10]), .Bitline2(Bitline2[10]));
  BitCell bit11(.clk(clk), .rst(rst), .D(D[11]), .WriteEnable(WriteReg), .ReadEnable1(ReadEnable1), .ReadEnable2(Readenable2), .Bitline1(Bitline1[11]), .Bitline2(Bitline2[11]));
  BitCell bit12(.clk(clk), .rst(rst), .D(D[12]), .WriteEnable(WriteReg), .ReadEnable1(ReadEnable1), .ReadEnable2(Readenable2), .Bitline1(Bitline1[12]), .Bitline2(Bitline2[12]));
  BitCell bit13(.clk(clk), .rst(rst), .D(D[13]), .WriteEnable(WriteReg), .ReadEnable1(ReadEnable1), .ReadEnable2(Readenable2), .Bitline1(Bitline1[13]), .Bitline2(Bitline2[13]));
  BitCell bit14(.clk(clk), .rst(rst), .D(D[14]), .WriteEnable(WriteReg), .ReadEnable1(ReadEnable1), .ReadEnable2(Readenable2), .Bitline1(Bitline1[14]), .Bitline2(Bitline2[14]));
  BitCell bit15(.clk(clk), .rst(rst), .D(D[15]), .WriteEnable(WriteReg), .ReadEnable1(ReadEnable1), .ReadEnable2(Readenable2), .Bitline1(Bitline1[15]), .Bitline2(Bitline2[15]));
endmodule

module RegisterFile (input clk, input rst, input [3:0] SrcReg1, input [3:0] SrcReg2, input [3:0] DstReg, input WriteReg, input [15:0] DstData, inout [15:0] SrcData1, inout [15:0] SrcData2);
 wire [15:0] ReadEnable1, ReadEnable2, WriteEnable;
 ReadDecoder_4_16 ReadDecoder1(.RegId(SrcReg1), .Wordline(ReadEnable1));
 ReadDecoder_4_16 ReadDecoder2(.RegId(SrcReg2), .Wordline(ReadEnable2));
 WriteDecoder_4_16 WriteDecoder(.RegId(DstReg), .WriteReg(WriteReg), .Wordline(WriteEnable));
 
 Register_bp register0(.clk(clk), .rst(rst), .D(DstData), .WriteReg(1'b0) /*We want zero register to awlays be zero*/, .ReadEnable1(ReadEnable1[0]), .Readenable2(ReadEnable2[0]), .Bitline1(SrcData1), .Bitline2(SrcData2));
 Register_bp register1(.clk(clk), .rst(rst), .D(DstData), .WriteReg(WriteEnable[1]), .ReadEnable1(ReadEnable1[1]), .Readenable2(ReadEnable2[1]), .Bitline1(SrcData1), .Bitline2(SrcData2));
 Register_bp register2(.clk(clk), .rst(rst), .D(DstData), .WriteReg(WriteEnable[2]), .ReadEnable1(ReadEnable1[2]), .Readenable2(ReadEnable2[2]), .Bitline1(SrcData1), .Bitline2(SrcData2));
 Register_bp register3(.clk(clk), .rst(rst), .D(DstData), .WriteReg(WriteEnable[3]), .ReadEnable1(ReadEnable1[3]), .Readenable2(ReadEnable2[3]), .Bitline1(SrcData1), .Bitline2(SrcData2));
 Register_bp register4(.clk(clk), .rst(rst), .D(DstData), .WriteReg(WriteEnable[4]), .ReadEnable1(ReadEnable1[4]), .Readenable2(ReadEnable2[4]), .Bitline1(SrcData1), .Bitline2(SrcData2));
 Register_bp register5(.clk(clk), .rst(rst), .D(DstData), .WriteReg(WriteEnable[5]), .ReadEnable1(ReadEnable1[5]), .Readenable2(ReadEnable2[5]), .Bitline1(SrcData1), .Bitline2(SrcData2));
 Register_bp register6(.clk(clk), .rst(rst), .D(DstData), .WriteReg(WriteEnable[6]), .ReadEnable1(ReadEnable1[6]), .Readenable2(ReadEnable2[6]), .Bitline1(SrcData1), .Bitline2(SrcData2));
 Register_bp register7(.clk(clk), .rst(rst), .D(DstData), .WriteReg(WriteEnable[7]), .ReadEnable1(ReadEnable1[7]), .Readenable2(ReadEnable2[7]), .Bitline1(SrcData1), .Bitline2(SrcData2));
 Register_bp register8(.clk(clk), .rst(rst), .D(DstData), .WriteReg(WriteEnable[8]), .ReadEnable1(ReadEnable1[8]), .Readenable2(ReadEnable2[8]), .Bitline1(SrcData1), .Bitline2(SrcData2));
 Register_bp register9(.clk(clk), .rst(rst), .D(DstData), .WriteReg(WriteEnable[9]), .ReadEnable1(ReadEnable1[9]), .Readenable2(ReadEnable2[9]), .Bitline1(SrcData1), .Bitline2(SrcData2));
 Register_bp register10(.clk(clk), .rst(rst), .D(DstData), .WriteReg(WriteEnable[10]), .ReadEnable1(ReadEnable1[10]), .Readenable2(ReadEnable2[10]), .Bitline1(SrcData1), .Bitline2(SrcData2));
 Register_bp register11(.clk(clk), .rst(rst), .D(DstData), .WriteReg(WriteEnable[11]), .ReadEnable1(ReadEnable1[11]), .Readenable2(ReadEnable2[11]), .Bitline1(SrcData1), .Bitline2(SrcData2));
 Register_bp register12(.clk(clk), .rst(rst), .D(DstData), .WriteReg(WriteEnable[12]), .ReadEnable1(ReadEnable1[12]), .Readenable2(ReadEnable2[12]), .Bitline1(SrcData1), .Bitline2(SrcData2));
 Register_bp register13(.clk(clk), .rst(rst), .D(DstData), .WriteReg(WriteEnable[13]), .ReadEnable1(ReadEnable1[13]), .Readenable2(ReadEnable2[13]), .Bitline1(SrcData1), .Bitline2(SrcData2));
 Register_bp register14(.clk(clk), .rst(rst), .D(DstData), .WriteReg(WriteEnable[14]), .ReadEnable1(ReadEnable1[14]), .Readenable2(ReadEnable2[14]), .Bitline1(SrcData1), .Bitline2(SrcData2));
 Register_bp register15(.clk(clk), .rst(rst), .D(DstData), .WriteReg(WriteEnable[15]), .ReadEnable1(ReadEnable1[15]), .Readenable2(ReadEnable2[15]), .Bitline1(SrcData1), .Bitline2(SrcData2));
endmodule