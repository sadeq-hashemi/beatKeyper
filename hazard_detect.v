/*
  TODO: 
    1. Figure out hazard detection logic for SLL, SRA, ROR, LW, SW, LHB, LLB, B, BR, PCS
    2. Figure out what outputs we need for data hazard and control hazard
*/  

/*
  Helpful Reading:
    1. http://www.cs.cornell.edu/courses/cs3410/2012sp/lecture/10-hazards-i-g.pdf
    2. http://www.ece.ucsb.edu/~strukov/ece154aFall2013/viewgraphs/pipelinedMIPS.pdf
    3. https://courses.cs.washington.edu/courses/cse378/09wi/lectures/lec13.pdf
*/

/* input: - instruction: what the operation is (add, read, store, etc)
          - output of register file's reg
   output: - to IF/ID reg
	   - to PC
	   - to MUX before ID/EX Reg
*/

/* 
  What to do when there is a data hazard:
  1. Stall
  2. In SW reorder
  3. Forward/Bypass
*/


//module hazard_detect(sig_control, idex_mem_read, memwb_read, idex_rd, exmem_rd, memwb_rd, flush, rs, rt, stall);
module hazard_detect(branch, ID_EX_memread, ID_EX_reg, IF_ID_r1, IF_ID_r2,temp, temp2, cur_inst ,stall, flush);

input branch, ID_EX_memread;
input [3:0] ID_EX_reg, IF_ID_r1, IF_ID_r2; 
input [3:0] cur_inst;
input [15:0] temp, temp2;
output stall, flush; 

  //stalls if we are scheduled to read from memory from EX stage, reg to write to is not 0, and reg to write to equals to 
  //either register in ID stage   
// assign stall = ((ID_EX_memread /*| (cur_inst[3:0] == 4'b1010) | (cur_inst[3:0] == 4'b1011)*/) & (ID_EX_reg != 4'b0000) & (ID_EX_reg == IF_ID_r1 | ID_EX_reg == IF_ID_r2)) ? 1'b1: 1'b0; 
 /*
registers match AND LHB/SW for first AND SW/LW for second 
OR 
memory read/LHB/LLB
assign stall = ((temp[11:8] == temp2[11:8] & ((temp[15:12] == 4'b1001|temp[15:12] == 4'b1000)&
( temp2[15:12] == 4'b1001 |temp2[15:12] == 4'b1000))) | ((ID_EX_memread | (cur_inst[3:0] == 4'b1010) | (cur_inst[3:0] == 4'b1011)) & (ID_EX_reg != 4'b0000)


temp = inst_1 
temp2 = inst_3 

all 16 bits
*/  
//stalls if we are scheduled to read from memory from EX stage, reg to write to is not 0, and reg to write to equals to 
  //either register in ID stage   
 assign stall = ((temp[11:8] == temp2[11:8] & ((temp[15:12] == 4'b1001|temp[15:12] == 4'b1000)&( temp2[15:12] == 4'b1001 |temp2[15:12] == 4'b1000))) | ((ID_EX_memread | (cur_inst[3:0] == 4'b1010) | (cur_inst[3:0] == 4'b1011)) & (ID_EX_reg != 4'b0000) & (ID_EX_reg == IF_ID_r1 | ID_EX_reg == IF_ID_r2))) ? 1'b1: 1'b0; 
  //flushes on a taken branch instruction
 assign flush = branch ? 1'b1 : 1'b0;


endmodule
