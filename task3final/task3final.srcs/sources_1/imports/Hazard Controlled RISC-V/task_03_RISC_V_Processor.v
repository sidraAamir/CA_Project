module Pipelined_Processor_Task_3
(
    clk, reset,
    element1,element2,element3,element4,
    r1,r2,r3,r4,r5
);
input clk,reset;
output wire [63:0] r1,r2,r3,r4,r5;
output wire [63:0] element1,element2,element3,element4;
wire [63:0] PC_to_IM;
wire [31:0] IM_to_IFID;
wire [6:0] opcode_out; 
wire[4:0] rd_out;
wire [2:0] funct3_out;
wire [6:0] funct7_out;
wire [4:0] rs1_out, rs2_out;
wire Branch_out, MemRead_out, MemtoReg_out, MemWrite_out, ALUSrc_out, RegWrite_out;
wire Is_Greater_out;
wire [1:0] ALUOp_out;
wire [63:0] mux_to_reg;
wire [63:0] mux_to_pc_in;
wire [3:0] ALU_C_Operation;
wire [63:0] ReadData1_out, ReadData2_out;
wire [63:0] imm_data_out;



wire [63:0] int_4 = 64'd4;
wire [63:0] PC_plus_4_to_mux;

wire [63:0] alu_mux_out;

wire [63:0] alu_result_out;
wire zero_out;

wire [63:0] imm_to_adder;
wire [63:0] imm_adder_to_mux;

wire [63:0] DM_Read_Data_out;

wire pc_mux_sel_wire;
wire PCWrite_out;


wire IDEX_Branch_out, IDEX_MemRead_out, IDEX_MemtoReg_out,
IDEX_MemWrite_out, IDEX_ALUSrc_out, IDEX_RegWrite_out;

//wires for id ex
wire [63:0] IDEX_PC_addr, IDEX_ReadData1_out, IDEX_ReadData2_out,
            IDEX_imm_data_out;
wire [3:0] IDEX_funct_in;
wire [4:0] IDEX_rd_out, IDEX_rs1_out, IDEX_rs2_out;
wire [1:0] IDEX_ALUOp_out;

assign imm_to_adder = IDEX_imm_data_out<< 1;


//wires for ex mem
wire EXMEM_Branch_out, EXMEM_MemRead_out, EXMEM_MemtoReg_out,
EXMEM_MemWrite_out, EXMEM_RegWrite_out; 
wire EXMEM_zero_out, EXMEM_Is_Greater_out;
wire [63:0] EXMEM_PC_plus_imm, EXMEM_alu_result_out,
    EXMEM_ReadData2_out;
wire [3:0] EXMEM_funct_in;
wire [4:0] EXMEM_rd_out;
wire Flush_signal;
wire [1:0] ALUop_IDEXin;

//wires for mem wb
wire MEMWB_MemtoReg_out, MEMWB_RegWrite_out;
wire [63:0] MEMWB_DM_Read_Data_out, MEMWB_alu_result_out;
wire [4:0] MEMWB_rd_out;


mux_2by1 mux_from_pc( .a(EXMEM_PC_plus_imm),   //value when sel is 1
    .b(PC_plus_4_to_mux), .sel(pc_mux_sel_wire), .data_out(mux_to_pc_in));

Program_Counter prog_count (.clk(clk), .reset(reset), .PCWrite(PCWrite_out), .PC_In(mux_to_pc_in), .PC_Out(PC_to_IM));

Adder from_pc_adder( .A(PC_to_IM), .B(int_4), .out(PC_plus_4_to_mux));

Instruction_Memory inst_mem(.Inst_Address(PC_to_IM), .Instruction(IM_to_IFID));

//wires for ifid
wire [63:0] IFID_PC_addr;
wire [31:0] IFID_parse;
wire IFID_Write_out;


IF_ID ifid(.clk(clk), .Flush(Flush_signal), .IFID_Write(IFID_Write_out),  .PC_addr(PC_to_IM), .Instruc(IM_to_IFID), .PC_store(IFID_PC_addr), .Instr_store(IFID_parse));

wire controlmux_sel_bit;

Hazard_Detection hazard_det_unit(.IDEX_rd(IDEX_rd_out), .IFID_rs1(rs1_out), .IFID_rs2(rs2_out), .IDEX_MemRead(IDEX_MemRead_out), .IDEX_mux_out(controlmux_sel_bit), .IFID_Write(IFID_Write_out), .PCWrite(PCWrite_out));

Instruction_Parser instr_parser(.instruc(IFID_parse), .opcode(opcode_out), .rd(rd_out), .funct3(funct3_out), .rs1(rs1_out), .rs2(rs2_out), .funct7(funct7_out));

wire [3:0] funct_in;
assign funct_in = {IFID_parse[30],IFID_parse[14:12]};

Control_Unit cont_unit
(.Opcode(opcode_out),  .Branch(Branch_out),  .MemRead(MemRead_out),  .MemtoReg(MemtoReg_out), .MemWrite(MemWrite_out), .ALUSrc(ALUSrc_out), .RegWrite(RegWrite_out), .ALUOp(ALUOp_out));

Register_File reg_file(.clk(clk),  .reset(reset), .RegWrite(MEMWB_RegWrite_out), .WriteData(mux_to_reg), .RS1(rs1_out), .RS2(rs2_out),  .RD(MEMWB_rd_out), .ReadData1(ReadData1_out), .ReadData2(ReadData2_out));

imm_data_generator imm_data_gen(.instruc(IFID_parse), .imm_data(imm_data_out));

assign MemtoReg_IDEXin = controlmux_sel_bit ? MemtoReg_out : 0;
assign RegWrite_IDEXin = controlmux_sel_bit ? RegWrite_out : 0;
assign Branch_IDEXin = controlmux_sel_bit ? Branch_out : 0;
assign MemWrite_IDEXin = controlmux_sel_bit ? MemWrite_out : 0;
assign MemRead_IDEXin = controlmux_sel_bit ? MemRead_out : 0;
assign ALUSrc_IDEXin = controlmux_sel_bit ? ALUSrc_out : 0;
assign ALUop_IDEXin = controlmux_sel_bit ? ALUOp_out : 2'b00;


ID_EX idex_reg(.clk(clk), .Flush(Flush_signal), .PC_addr(IFID_PC_addr), .read_data1(ReadData1_out), .read_data2(ReadData2_out), .imm_val(imm_data_out), .funct_in(funct_in), .rd_in(rd_out),  .rs1_in(rs1_out), .rs2_in(rs2_out), .RegWrite(RegWrite_IDEXin), .MemtoReg(MemtoReg_IDEXin), .Branch(Branch_IDEXin), .MemWrite(MemWrite_IDEXin), .MemRead(MemRead_IDEXin), .ALUSrc(ALUSrc_IDEXin), .ALU_op(ALUop_IDEXin), .PC_addr_store(IDEX_PC_addr), .read_data1_store(IDEX_ReadData1_out), .read_data2_store(IDEX_ReadData2_out), .imm_val_store(IDEX_imm_data_out), .funct_in_store(IDEX_funct_in), .rd_in_store(IDEX_rd_out), .rs1_in_store(IDEX_rs1_out), .rs2_in_store(IDEX_rs2_out), .RegWrite_store(IDEX_RegWrite_out), .MemtoReg_store(IDEX_MemtoReg_out), .Branch_store(IDEX_Branch_out),  .MemWrite_store(IDEX_MemWrite_out), .MemRead_store(IDEX_MemRead_out), .ALUSrc_store(IDEX_ALUSrc_out), .ALU_op_store(IDEX_ALUOp_out));

ALU_Control alu_control(.ALUOp(IDEX_ALUOp_out), .Funct(IDEX_funct_in), .Operation(ALU_C_Operation));

wire [1:0] fwd_A_out, fwd_B_out;

wire [63:0] muxout_a, muxout_b;

mux_2by1 mux_with_ALU(.a(IDEX_imm_data_out), .b(muxout_b), .sel(IDEX_ALUSrc_out), .data_out(alu_mux_out));

mux_3by1 fwd_a_mux(.a(IDEX_ReadData1_out), .b(mux_to_reg), .c(EXMEM_alu_result_out), .sel(fwd_A_out), .data_out(muxout_a));

mux_3by1 fwd_b_mux(.a(IDEX_ReadData2_out), .b(mux_to_reg), .c(EXMEM_alu_result_out), .sel(fwd_B_out), .data_out(muxout_b));

ALU_64_bit alu_64(.a(muxout_a), .b(alu_mux_out), .ALUOp(ALU_C_Operation), .Result(alu_result_out), .Zero(zero_out), .Greater_Check(Is_Greater_out));

Forwarding_Unit fwd_unit(.EXMEM_rd(EXMEM_rd_out), .MEMWB_rd(MEMWB_rd_out), .IDEX_rs1(IDEX_rs1_out), .IDEX_rs2(IDEX_rs2_out), .EXMEM_RegWrite(EXMEM_RegWrite_out), .EXMEM_MemtoReg(EXMEM_MemtoReg_out), .MEMWB_RegWrite(MEMWB_RegWrite_out), .fwd_A(fwd_A_out), .fwd_B(fwd_B_out));

wire [63:0] adder_send_exmem;
//send the output of the adder to ex mem reg

Adder imm_to_PC(.A(IDEX_PC_addr), .B(imm_to_adder), .out(adder_send_exmem));

EX_MEM ex_mem_reg(.clk(clk), .Flush(Flush_signal), .RegWrite(IDEX_RegWrite_out), .MemtoReg(IDEX_MemtoReg_out), .Branch(IDEX_Branch_out), .Zero(zero_out), .Greater_Check(Is_Greater_out), .MemWrite(IDEX_MemWrite_out), .MemRead(IDEX_MemRead_out), .PCplusimm(adder_send_exmem), .ALU_result(alu_result_out), .WriteData(muxout_b), .funct_in(IDEX_funct_in), .rd(IDEX_rd_out), .RegWrite_store(EXMEM_RegWrite_out), .MemtoReg_store(EXMEM_MemtoReg_out), .Branch_store(EXMEM_Branch_out), .Zero_store(EXMEM_zero_out), .Is_Greater_store(EXMEM_Is_Greater_out), .MemWrite_store(EXMEM_MemWrite_out), .MemRead_store(EXMEM_MemRead_out), .PCplusimm_store(EXMEM_PC_plus_imm), .ALU_result_store(EXMEM_alu_result_out), .WriteData_store(EXMEM_ReadData2_out), .funct_in_store(EXMEM_funct_in), .rd_store(EXMEM_rd_out));

Branch_Control branch_cont(.Branch(EXMEM_Branch_out), .Flush(Flush_signal), .Zero(EXMEM_zero_out), .Greater_Check(EXMEM_Is_Greater_out), .funct(EXMEM_funct_in), .switch_branch(pc_mux_sel_wire));


Data_Memory dm(EXMEM_alu_result_out,EXMEM_ReadData2_out,clk,EXMEM_MemWrite_out,EXMEM_MemRead_out,DM_Read_Data_out,element1,element2, element3,element4);



MEM_WB mem_wb_reg(.clk(clk), .RegWrite(EXMEM_RegWrite_out), .MemtoReg(EXMEM_MemtoReg_out), .ReadData(DM_Read_Data_out), .ALU_result(EXMEM_alu_result_out), .rd(EXMEM_rd_out), .RegWrite_store(MEMWB_RegWrite_out), .MemtoReg_store(MEMWB_MemtoReg_out), .ReadData_store(MEMWB_DM_Read_Data_out), .ALU_result_store(MEMWB_alu_result_out), .rd_store(MEMWB_rd_out));


mux_2by1 muxx(.a(MEMWB_DM_Read_Data_out),.b(MEMWB_alu_result_out), .sel(MEMWB_MemtoReg_out), .data_out(mux_to_reg));

endmodule