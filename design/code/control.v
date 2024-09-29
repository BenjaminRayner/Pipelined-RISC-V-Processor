`define REG 5'h0c
`define IMM 5'h04
`define LOAD 5'h00
`define STORE 5'h08
`define BRANCH 5'h18
`define JAL 5'h1b
`define JALR 5'h19
`define LUI 5'h0d
`define AUIPC 5'h05
`define ECALL 5'h1c

module control(
  input wire [4:0] opcode_D,
  input wire [4:0] rs1_D,
  input wire [4:0] rs2_D,
  input wire [4:0] opcode_X,
  input wire [2:0] funct3_X,
  input wire funct7_X,
  input wire [4:0] rd_X,
  input wire [4:0] rs1_X,
  input wire [4:0] rs2_X,
  input wire [4:0] opcode_M,
  input wire [2:0] funct3_M,
  input wire [4:0] rd_M,
  input wire [4:0] rs2_M,
  input wire [4:0] opcode_W,
  input wire [4:0] rd_W,
  input wire BrEq,
  input wire BrLT,
  input wire valid_X,
  input wire valid_M,
  input wire valid_W,
  output wire PCSel,
  output wire Stall,
  output wire RegWEn,
  output wire BrUn,
  output wire MemWEn,
  output wire MemUn,
  output wire MemSel,
  output reg [1:0] Br1Sel,
  output reg [1:0] Br2Sel,
  output reg [1:0] ALU1Sel,
  output reg [1:0] ALU2Sel,
  output reg [2:0] ImmSel,
  output reg [3:0] ALUopSel,
  output reg [1:0] AccSize,
  output reg [1:0] WBSel
);

//Determines if an instruction's rd bits should be considered
wire validRD_X, validRD_M, validRD_W;
assign validRD_X = !(opcode_X == `BRANCH || opcode_X == `STORE) && valid_X && (rd_X != 5'h00);
assign validRD_M = !(opcode_M == `BRANCH || opcode_M == `STORE) && valid_M && (rd_M != 5'h00);
assign validRD_W = !(opcode_W == `BRANCH || opcode_W == `STORE) && valid_W && (rd_W != 5'h00);

// Two to One Muxes ----------------------------

//ALUout -> PC if JAL, JALR, or BRANCH, given that the branch is taken | Else, PC + 4 -> PC
assign PCSel = ((opcode_X == `JAL) || (opcode_X == `JALR) || ((opcode_X == `BRANCH) && (((funct3_X == 3'h0) && BrEq) || ((funct3_X == 3'h1) && !BrEq) ||
               (((funct3_X == 3'h4) || (funct3_X == 3'h6)) && BrLT) || (((funct3_X == 3'h5) || (funct3_X == 3'h7)) && (BrEq || !BrLT))))) && valid_X;

/* Stall pipeline if Read after LOAD (1 Away), STORE after Write (2 away), Read after Write (3 away).
   Dont need to stall for LUI, AUIPC, JAL, IMM on rs2, or if not valid rd. */
assign Stall = (((rs1_D == rd_X) || ((rs2_D == rd_X) && !((opcode_D == `STORE) || (opcode_D == `IMM)))) && (opcode_X == `LOAD)  && validRD_X) ||
                ((rs2_D == rd_M)                                                                        && (opcode_D == `STORE) && validRD_M) ||
               (((rs1_D == rd_W) || ((rs2_D == rd_W) && !(opcode_D == `IMM)))                                                   && validRD_W) &&
               !((opcode_D == `LUI) || (opcode_D == `AUIPC) || (opcode_D == `JAL));

//Enable unsigned branch comparison for BLTU, BGEU
assign BrUn = (funct3_X == 3'h6 || funct3_X === 3'h7);

//Enable mem write if STORE
assign MemWEn = (opcode_M == `STORE) && valid_M;

//Enable unsigned mem load for LBU and LHU
assign MemUn = (funct3_M == 3'h4 || funct3_M == 3'h5);

//WM Bypass for DMEM Data
assign MemSel = (rs2_M == rd_W) && validRD_W;

//Disable reg write for STORE and BRANCH
assign RegWEn = !(opcode_W == `STORE || opcode_W == `BRANCH) && valid_W;

// Many to One Muxes (Case better synth) ---------------------------

  always@(*)
  begin
    
    //ImmSel
    case(opcode_X)
      `IMM:
      begin
        case(funct3_X)
          3'h1, 3'h5:                   ImmSel = 3'h0;  //SHAMT
          default:                      ImmSel = 3'h1;  //I-type (IMM)
        endcase
      end
      `LOAD, `JALR:                     ImmSel = 3'h1;  //I-type (LOAD)
      `STORE:                           ImmSel = 3'h2;  //S-type
      `BRANCH:                          ImmSel = 3'h3;  //B-type
      `JAL:                             ImmSel = 3'h4;  //J-type
      default:                          ImmSel = 3'h5;  //U-type
    endcase

    //Br1Sel
    case ({rs1_X, 1'b1})
      {rd_M, validRD_M}:                Br1Sel = 2'h0; //alu_M -> Br1 (MX bypass)
      {rd_W, validRD_W}:                Br1Sel = 2'h1; //data_W -> Br1 (WX bypass)
      default:                          Br1Sel = 2'h2; //rs1_X -> Br1
    endcase
    //Br2Sel
    case ({rs2_X, 1'b1})
      {rd_M, validRD_M}:                Br2Sel = 2'h0; //alu_M -> Br2 (MX bypass)
      {rd_W, validRD_W}:                Br2Sel = 2'h1; //data_W -> Br2 (WX bypass)
      default:                          Br2Sel = 2'h2; //rs2_X -> Br2
    endcase
    
    //ALU1Sel
    case(opcode_X)
      `BRANCH, `AUIPC, `JAL:            ALU1Sel = 2'h0; //PC -> ALU1
      default:
      begin
        case ({rs1_X, 1'b1})
          {rd_M, validRD_M}:            ALU1Sel = 2'h1; //alu_M -> ALU1 (MX bypass)
          {rd_W, validRD_W}:            ALU1Sel = 2'h2; //data_W -> ALU1 (WX bypass)
          default:                      ALU1Sel = 2'h3; //rs1_X -> ALU1
        endcase
      end
    endcase
    //ALU2Sel
    case(opcode_X)
      `REG:
      begin
        case ({rs2_X, 1'b1})
          {rd_M, validRD_M}:            ALU2Sel = 2'h1; //alu_M -> ALU2 (MX bypass)
          {rd_W, validRD_W}:            ALU2Sel = 2'h2; //data_W -> ALU2 (WX bypass)
          default:                      ALU2Sel = 2'h3; //rs2_X -> ALU2
        endcase
      end
      default:                          ALU2Sel = 2'h0; //IMM -> ALU2
    endcase

    //ALUopSel
    case(opcode_X)
      `REG, `IMM:
      begin
        case(funct3_X)
          3'h0:
          begin
            if (funct7_X & opcode_X[3]) ALUopSel = 4'h0; //SUB
            else                        ALUopSel = 4'h1; //ADD, ADDI
          end
          3'h1:                         ALUopSel = 4'h2; //SLL, SLLI
          3'h2:                         ALUopSel = 4'h3; //SLT, SLTI
          3'h3:                         ALUopSel = 4'h4; //SLTU, SLTIU
          3'h4:                         ALUopSel = 4'h5; //XOR, XORI
          3'h5:
          begin
            if (funct7_X)               ALUopSel = 4'h6; //SRA, SRAI
            else                        ALUopSel = 4'h7; //SRL, SRLI
          end
          3'h6:                         ALUopSel = 4'h8; //OR, ORI
          default:                      ALUopSel = 4'h9; //AND, ANDI
        endcase
      end
      `LUI:                             ALUopSel = 4'ha; //LUI
      default:                          ALUopSel = 4'h1; //DEFAULT ADD
    endcase

    //Access Size
    case(funct3_M)
      3'h0, 3'h4:                       AccSize = 2'h0; //LB, LBU, SB
      3'h1, 3'h5:                       AccSize = 2'h1; //LH, LHU, SH
      default:                          AccSize = 2'h2; //LW, SW
    endcase

    //WBSel
    case(opcode_M)
      `JAL, `JALR:                      WBSel = 2'h0;  //PC + 4 to Reg
      `LOAD:                            WBSel = 2'h1;  //Mem to Reg
      default:                          WBSel = 2'h2;  //ALU to Reg
    endcase

    //Simulation Purposes
    if (opcode_W == `ECALL) $finish;

  end

endmodule