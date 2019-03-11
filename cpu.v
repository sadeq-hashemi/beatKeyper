module cpu(clk, rst_n, hlt, pc);
  input clk, rst_n;
  output hlt;
  output [15:0] pc;

  wire [15:0] inst, inst_in;
  wire [15:0] write_data, alu_write_data, mem_write_data, branch_write_data; //output of DataMem or ALU, input into Registers
  wire [15:0]  alu2; //we must select Rt based on mux
  wire [3:0] Reg2;

  wire [15:0] Read1, Read2; //output of REGISTERS
  wire [15:0] SignedImm; //sign extended immediate

  wire RegDst, Branch, MemRead, MemtoReg, MemWrite, ALUSrc, RegWrite; //outputs of control logic
  wire [3:0] ALUOp; //output of control logic, will go straight to ALU

  wire [15:0] pc_next;
  wire [2:0] flag;

  //wire i_stall, d_stall;

  wire stall, flush;
 // wire global_stall; //incorporates hazard unit and cache stalls
  wire freeze;
  wire [15:0] inst_1, pc_1; //wires to connect the pipe1 to pipe2
  wire [15:0] inst_2, pc_2, Read1_2, Read2_2, SignedImm_2; //output of pipe2
  wire [3:0] ALUOp_2;
  wire RegDst_2, Branch_2, MemRead_2, MemtoReg_2, MemWrite_2, ALUSrc_2, RegWrite_2;
  wire [15:0] alu_3, inst_3, pc_3, Read1_3, Read2_3; //wires for the output of pipe3
  wire [2:0] flag_3;
  wire RegDst_3, Branch_3, MemRead_3, MemtoReg_3, MemWrite_3, RegWrite_3;
  wire [15:0] inst_4, alu_4, data_mem_4, branch_pc_4, pc_next_4; //wires for output of pipe4
  wire MemtoReg_4, RegWrite_4;

  //from forwarding logic
  wire [15:0] alu_forward_1, alu_forward_2; //outputs from forwarding mux

  assign hlt = (inst_4[15:12] == 4'hF) ? 1'b1: 1'b0;
  assign rst = ~rst_n; //some modules require active high rst but we are given an active low
  assign Reg2 = (inst_1[15:12] == 4'b1011 | inst_1[15:12] == 4'b1010 | inst_1[15:12] == 4'b1001 | inst_1[15:12] == 4'b1000) ? inst_1[11:8]: inst_1[3:0]; //if we have a LW or SW we used bits 11:8, otherwise 3:0
  assign alu2 = (ALUSrc_2 == 0) ? Read2_2 : SignedImm_2;
  wire rst_check;
  wire [15:0] pc_reg_in, pc_incremented;
  wire branch_taken_haz; //we need to check taht its a branch and its taken
  assign pc_reg_in = (Branch_3 == 0 | branch_taken_haz == 0) ? pc_incremented : pc_next; //branch_write_data; only branch if theyre both 1
  addsub_16bit PC_add(.A(pc), .B(16'h2), .sub(1'b0), .sum(pc_incremented), .ovfl()); //(PC + 2) 

  Register PC_REG(.clk(clk), .rst(rst), .D(pc_reg_in), .WriteReg(1'b1 & ~(freeze | stall)), .ReadEnable1(1'b1), .Readenable2(1'b0), .Bitline1(pc), .Bitline2());

  //We should never write to INST MEM, we are always reading
/*  
memory1c INST_MEM(.data_out(inst), .data_in(16'h0), .addr(pc), .enable(1'b1), .wr(1'b0), .clk(clk), .rst(rst));
  */

  //WriteReg is from control
  RegisterFile REGISTERS (.clk(clk), .rst(rst), .SrcReg1(inst_1[7:4]), .SrcReg2(Reg2), .DstReg(inst_4[11:8]), .WriteReg(RegWrite_4), 
						  .DstData(write_data), .SrcData1(Read1), .SrcData2(Read2));

  //addr = ALU out, MemWrite and MemRead = CONTROL out
  wire [15:0] data_out;
  wire [15:0] zero_addr_DM_Mem;
  assign zero_addr_DM_Mem = alu_3 & 16'hFFFE; //set bit 0 to zero
  Data_Mem DATA_MEM(.ReadData2(alu_3/*Read2_3*/), .inst(inst_3), .addr(alu_3), .w_data(Read2_3),
					.r_data(mem_write_data), .MemRead(MemRead_3),
					.MemWrite(MemWrite_3), .clk(clk), .rst(rst), .mems_data_out(data_out));
  //memory1c DATA(.data_out(data_out), .data_in(Read2_3), .addr(zero_addr_DM_Mem), .enable(MemRead_3 | MemWrite_3), .wr(MemWrite_3), .clk(clk), .rst(rst));




  
  Sign_Extend SIGNED(.inst(inst_1), .out(SignedImm));

  //All the control logic is in here, ALU Control and Control (datasheet ref)
  Control CONTROL(.rst(rst_check), .select(inst_1[15:12]), .RegDst(RegDst), .Branch(Branch), .MemRead(MemRead), .MemtoReg(MemtoReg), 
					.ALUOp(ALUOp), .MemWrite(MemWrite), .ALUSrc(ALUSrc), .RegWrite(RegWrite));

  PC_control_phase1 INST_BRANCH(.inst(inst_3), .FLAG(flag_3), .PC_in(pc_3),
                           .rd_val(Read2_3), .rs_val(Read1_3), .PC_out(pc_next), .wr(), .wr_val(branch_write_data), .branch_taken(branch_taken_haz));

  ALU THEALU(.clk(clk), .rst(rst), .alu_out(alu_write_data), .alu_in1(alu_forward_1), .alu_in2(alu_forward_2), .Opcode(ALUOp_2), .Flag(flag)); //opcode only needs lower 3 bits


  //IF_ID PIPE

  IF_ID if_id_pipe (.rst_check(rst_check), .clk(clk), .rst(flush | rst), .inst_in(inst), .pc_in(pc), .inst_out(inst_1), .pc_out(pc_1), .write_enable(1'b1 & ~(freeze | stall)));
  

  wire [3:0] read1_forward_out, read2_forward_out;
  ID_EX id_ex_pipe (.clk(clk), .rst(flush | stall | rst), .inst_in(inst_1), .pc_in(pc_1), .inst_out(inst_2), .pc_out(pc_2), .read1_in(Read1), .write_enable(~(freeze)),
					.read2_in(Read2),.read1_out(Read1_2), .read2_out(Read2_2), .sign_in(SignedImm), .sign_out(SignedImm_2), 
					.RegDst(RegDst), .Branch(Branch), .MemRead(MemRead), .MemtoReg(MemtoReg), 
					.ALUOp(ALUOp), .MemWrite(MemWrite), .ALUSrc(ALUSrc), .RegWrite(RegWrite), 
					.RegDst_out(RegDst_2), .Branch_out(Branch_2), .MemRead_out(MemRead_2), .MemtoReg_out(MemtoReg_2), 
					.ALUOp_out(ALUOp_2), .MemWrite_out(MemWrite_2), .ALUSrc_out(ALUSrc_2), .RegWrite_out(RegWrite_2), 
					.read1_num(inst_1[7:4]), .read2_num(Reg2), .read1_num_out(read1_forward_out), .read2_num_out(read2_forward_out));
  

  EX_MEM ex_mem_pipe(.clk(clk), .rst(flush | rst), .inst_in(inst_2), .pc_in(pc_2), .inst_out(inst_3), .pc_out(pc_3), .read1_in(Read1_2), .read2_in(Read2_2), .write_enable(~(freeze))
					 ,.read1_out(Read1_3), .read2_out(Read2_3), .flag_in(flag), .flag_out(flag_3), .alu_in(alu_write_data), .alu_out(alu_3),
					 .MemRead(MemRead_2), .MemToReg(MemtoReg_2), .MemWrite(MemWrite_2),
					 .RegWrite(RegWrite_2), .MemRead_out(MemRead_3), 
					 .MemToReg_out(MemtoReg_3), .MemWrite_out(MemWrite_3), .RegWrite_out(RegWrite_3), .Branch(Branch_2), .Branch_out(Branch_3));
  
  //we can reset this pipe with either the reset signal or when we encounter a flush we want to lose all current instr data
  MEM_WB mem_wb_pipe(.clk(clk), .rst(rst), .inst_in(inst_3), .inst_out(inst_4), .alu_in(alu_3), .data_mem_in(mem_write_data), .write_enable(~(freeze)),
			.branch_pc_in(branch_write_data), .alu_out(alu_4), .data_mem_out(data_mem_4), .branch_pc_out(branch_pc_4),
			.MemtoReg_out(MemtoReg_4), .RegWrite(RegWrite_3), .RegWrite_out(RegWrite_4), .MemtoReg(MemtoReg_3), .pc_next_in(pc_next), .pc_next_out(pc_next_4));

 wire [1:0] forwardA, forwardB;

 Forward for2ard_unit(.EX_MEM_wr(inst_3[11:8]), .MEM_WB_wr(inst_4[11:8]), .EX_MEM_wb(RegWrite_3), .MEM_WB_wb(RegWrite_4), 
						.IF_ID_r1(read1_forward_out), .IF_ID_r2(read2_forward_out), .forwardA(forwardA), .forwardB(forwardB));

 assign alu_forward_1 = (forwardA == 2'b00) ? Read1_2 : //these conditions are based on forward.v module
						(forwardA == 2'b01) ? alu_3 :
						 write_data;

 assign alu_forward_2 = (forwardB == 2'b00) ? alu2 : //alu2 becuase we first must mux read_2 and the sign extended //these conditions are based on forward.v module
						(forwardB == 2'b01) ? alu_3 :
						 write_data;


 //what data we write back to reg, ALU out, Mem Out or Branch Out
 assign write_data = (/*MemtoReg*/ MemtoReg_4 == 1) ?  data_mem_4 : //writing back Mem Data value
					  (inst_4[15:12] == 4'b1110) ? branch_pc_4: //writing back branch value
					   alu_4; //writing back ALU value
//make sure branch 3 works
//branch_taken_haz has to be one to say the flags matched and branch_3 to say it was a branch inst
hazard_detect HAZARD(.cur_inst(inst_2[15:12]), .branch(branch_taken_haz & Branch_3), .ID_EX_memread(MemRead_2), .ID_EX_reg(inst_2[11:8]), 
			.IF_ID_r1(inst_1[7:4]), .IF_ID_r2(Reg2),  .stall(stall), .flush(flush), .temp(inst_1) , .temp2(inst_3));


//////////////////////////////////////////////////////////////CACHE////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
wire D_data_valid, I_data_valid, mem_ready; 		// data valid signal coming from memory
wire [15:0] Dmem_data_in, Imem_data_in; 
wire [15:0] Dmem_data_out; 	//data that will be fed to memory
wire [15:0] Dmem_addr, Imem_addr; //address that will be fed to memory for read or write
wire D_miss, I_miss; 			//miss signal for memory
wire Dmem_wr; 			//write signal for memory


//reg //mem_valid; //TODwe need to set the enable on mem (we need to count the 4 * n cycles on memory)
wire i_state_out, d_state_out;
I_cache icache( .clk(clk),    .rst(rst),     
		.enable(1'b1), .addr(pc),   	//reg from CPU 
		.I_data_valid(I_data_valid), .I_data_in(Imem_data_in), .mem_ready(mem_ready),   //reg from MEM_arbitrary
		.I_miss(I_miss), .I_addr(Imem_addr),  .I_disable(I_disable),   //wire to MEM_arbitrary
		.data_out(inst) , .state_out(i_state_out)			//wire to CPU
		);

D_cache dcache( .clk(clk), .rst(rst),     
		.enable(MemRead_3 | MemWrite_3 ), .wr(MemWrite_3), .addr(zero_addr_DM_Mem), .data_in(Read2_3),    	//reg from CPU 
		.D_data_valid(D_data_valid),    .D_data_in(Dmem_data_in),    	//reg from MEM_arbitrary
		.D_miss(D_miss), .D_wr(Dmem_wr), .D_addr(Dmem_addr),.D_data_out(Dmem_data_out), .txn_done(txn_done),  .D_disable(D_disable), //wire to MEM_arbitrary
		.data_out(data_out), .state_out(d_state_out) 			//wire to CPU
		);

MEM_arbitrary memory( .clk(clk),  .rst(rst),  //cpu input
	.D_miss(D_miss),  .D_wr(Dmem_wr),  .D_addr(Dmem_addr),  .D_data_in(Dmem_data_out), .D_disable(D_disable),  //Dcache input
	.D_data_valid(D_data_valid),  .D_data_out(Dmem_data_in), .txn_done(txn_done),  //Dcache output
	.I_miss(I_miss),  .I_addr(Imem_addr), .mem_ready(mem_ready), .I_disable(I_disable),  //Icache input
	.I_data_valid(I_data_valid),  .I_data_out(Imem_data_in),//Icache output
	.freeze(freeze), .i_state_in(i_state_out), .d_state_in(d_state_out));//CPU output	



endmodule

