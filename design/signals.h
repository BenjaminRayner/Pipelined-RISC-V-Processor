
/* Your Code Below! Enable the following define's 
 * and replace ??? with actual wires */
// ----- signals -----
// You will also need to define PC properly
`define F_PC                pc_F
`define F_INSN              inst_F

`define D_PC                pc_D
`define D_OPCODE            inst_D[6:0]
`define D_RD                inst_D[11:7]
`define D_RS1               inst_D[19:15]
`define D_RS2               inst_D[24:20]
`define D_FUNCT3            inst_D[14:12]
`define D_FUNCT7            inst_D[31:25]
`define D_IMM               imm             //Decode?
`define D_SHAMT             imm[4:0]        //Decode?

`define R_WRITE_ENABLE      RegWEn
`define R_WRITE_DESTINATION inst_W[11:7]
`define R_WRITE_DATA        Data_W
`define R_READ_RS1          inst_D[19:15]
`define R_READ_RS2          inst_D[24:20]
`define R_READ_RS1_DATA     data_rs1
`define R_READ_RS2_DATA     data_rs2

`define E_PC                pc_X
`define E_ALU_RES           ALUout
`define E_BR_TAKEN          PCSel

`define M_PC                pc_M
`define M_ADDRESS           alu_M
`define M_RW                MemWEn
`define M_SIZE_ENCODED      AccSize
`define M_DATA              data

`define W_PC                pc_W
`define W_ENABLE            RegWEn
`define W_DESTINATION       inst_W[11:7]
`define W_DATA              data_W

// ----- signals -----

// ----- design -----
`define TOP_MODULE                 pd
// ----- design -----
