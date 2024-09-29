`define PC_START 32'h01000000
`define INST_BYTES 4
`define ALIGNMENT 32'hfffffffe
`define NOP 32'h00000013

module pd(
  input clock,
  input reset
);

//Used to mark valid data in stage
reg valid_F, valid_D, valid_X, valid_M, valid_W;

// Fetch ----------------------------------------------------------------------
  
  //Supply new inst addr to imem
  reg [31:0] pc_F;
  always@(posedge clock)
  begin
    if (reset) begin
      pc_F <= `PC_START;
      valid_F <= 1;
      valid_D <= 0;
      valid_X <= 0;
      valid_M <= 0;
      valid_W <= 0;
    end
    else
    begin
      valid_D <= valid_F;
      valid_X <= valid_D;
      valid_M <= valid_X;
      valid_W <= valid_M;
      if (PCSel) pc_F <= ALUout & `ALIGNMENT;
      else if (!Stall) pc_F <= pc_F + `INST_BYTES;
    end
  end

  //Fetch inst at addr
  wire [31:0] inst_F;
  imemory imem (
    .addr(pc_F),
    .inst(inst_F)
  );

  //Insert Decode NOP on jump
  wire [31:0] inst_FMux;
  assign inst_FMux = (PCSel ? `NOP : inst_F);

// Decode ---------------------------------------------------------------------

  reg [31:0] pc_D, inst_D;
  always@(posedge clock)
  begin
    if (!Stall || PCSel)
    begin
      pc_D <= pc_F;
      inst_D <= inst_FMux;
    end
  end

  //Access register file
  wire [31:0] data_rs1, data_rs2;
  register_file file (
    .clock(clock),
    .write_enable(RegWEn),
    .data_rd(data_W),
    .addr_rd(inst_W[11:7]),
    .addr_rs1(inst_D[19:15]),
    .addr_rs2(inst_D[24:20]),
    .data_rs1(data_rs1),
    .data_rs2(data_rs2)
  );

  //Insert Execute NOP on stall or jump
  wire [31:0] inst_DMux;
  assign inst_DMux = ((Stall || PCSel) ? `NOP : inst_D);

// Execute --------------------------------------------------------------------

  reg [31:0] pc_X, rs1_X, rs2_X, inst_X;
  always@(posedge clock)
  begin
    pc_X <= pc_D;
    rs1_X <= data_rs1;
    rs2_X <= data_rs2;
    inst_X <= inst_DMux;
  end

  //Generate immediate
  wire [31:0] imm;
  imm_gen gen (
    .inst(inst_X[31:7]),
    .ImmSel(ImmSel),
    .imm(imm)
  );

  //Decides if branch is taken
  reg [31:0] Br1, Br2;
  always@(*)
  begin
    case(Br1Sel)
      2'h0:     Br1 = alu_M;
      2'h1:     Br1 = data_W;
      default:  Br1 = rs1_X;
    endcase
    case(Br2Sel)
      2'h0:     Br2 = alu_M;
      2'h1:     Br2 = data_W;
      default:  Br2 = rs2_X;
    endcase
  end
  wire BrEq, BrLT;
  branch_comp branch (
    .data_rs1(Br1),
    .data_rs2(Br2),
    .BrUn(BrUn),
    .BrEq(BrEq),
    .BrLT(BrLT)
  );

  //Perform math operations
  reg [31:0] ALU1, ALU2;
  always@(*)
  begin
    case(ALU1Sel)
      2'h0:     ALU1 = pc_X;
      2'h1:     ALU1 = alu_M;
      2'h2:     ALU1 = data_W;
      default:  ALU1 = rs1_X;
    endcase
    case(ALU2Sel)
      2'h0:     ALU2 = imm;
      2'h1:     ALU2 = alu_M;
      2'h2:     ALU2 = data_W;
      default:  ALU2 = rs2_X;
    endcase
  end
  wire [31:0] ALUout;
  alu math (
    .ALUSel(ALUopSel),
    .ALU1(ALU1),
    .ALU2(ALU2),
    .ALUout(ALUout)
  );

// Memory ---------------------------------------------------------------------

  reg [31:0] pc_M, alu_M, rs2_M, inst_M;
  always@(posedge clock)
  begin
    pc_M <= pc_X;
    alu_M <= ALUout;
    rs2_M <= rs2_X;
    inst_M <= inst_X;
  end

  //Data memory access
  wire [31:0] data_in;
  assign data_in = (MemSel ? data_W : rs2_M);
  wire [31:0] MemOut;
  dmemory dmem (
    .clock(clock),
    .addr(alu_M),
    .data(data_in),
    .AccSize(AccSize),
    .MemUn(MemUn),
    .MemWEn(MemWEn),
    .MemOut(MemOut)
  );

  //Selects data for write back stage
  reg [31:0] data;
  always@(*)
  begin
    case(WBSel)
      2'h0:       data = pc_M + `INST_BYTES;
      2'h1:       data = MemOut;
      default:    data = alu_M;
    endcase
  end

// Write back -----------------------------------------------------------------
  
  //Push data to register file
  reg [31:0] pc_W, data_W, inst_W;
  always@(posedge clock)
  begin
    pc_W <= pc_M;
    data_W <= data;
    inst_W <= inst_M;
  end

// Control --------------------------------------------------------------------

  wire PCSel, Stall, RegWEn, MemWEn, MemUn, BrUn, MemSel;
  wire [1:0] Br1Sel, Br2Sel, ALU1Sel, ALU2Sel, WBSel, AccSize;
  wire [2:0] ImmSel;
  wire [3:0] ALUopSel;
  control cont (
    //Input
    .opcode_D(inst_D[6:2]),
    .rs1_D(inst_D[19:15]),
    .rs2_D(inst_D[24:20]),
    .opcode_X(inst_X[6:2]),
    .funct3_X(inst_X[14:12]),
    .funct7_X(inst_X[30]),
    .rd_X(inst_X[11:7]),
    .rs1_X(inst_X[19:15]),
    .rs2_X(inst_X[24:20]),
    .opcode_M(inst_M[6:2]),
    .funct3_M(inst_M[14:12]),
    .rd_M(inst_M[11:7]),
    .rs2_M(inst_M[24:20]),
    .opcode_W(inst_W[6:2]),
    .rd_W(inst_W[11:7]),
    .BrEq(BrEq),
    .BrLT(BrLT),
    .valid_X(valid_X),
    .valid_M(valid_M),
    .valid_W(valid_W),
    //Output
    .PCSel(PCSel),
    .Stall(Stall),
    .ImmSel(ImmSel),
    .BrUn(BrUn),
    .Br1Sel(Br1Sel),
    .Br2Sel(Br2Sel),
    .ALU1Sel(ALU1Sel),
    .ALU2Sel(ALU2Sel),
    .ALUopSel(ALUopSel),
    .MemSel(MemSel),
    .MemWEn(MemWEn),
    .MemUn(MemUn),
    .AccSize(AccSize),
    .WBSel(WBSel),
    .RegWEn(RegWEn)
  );

endmodule
