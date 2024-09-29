module imm_gen(
  input wire [24:0] inst,
  input wire [2:0] ImmSel,
  output reg [31:0] imm
);

always@(*)
begin
  case(ImmSel)
    3'h0: //SHAMT
      imm = {{27{1'b0}}, inst[17:13]};
    3'h1: //I-Type
      imm = {{21{inst[24]}}, inst[23:13]};
    3'h2: //S-Type
      imm = {{21{inst[24]}}, inst[23:18], inst[4:0]};
    3'h3: //B-Type
      imm = {{20{inst[24]}}, inst[0], inst[23:18], inst[4:1], 1'b0};
    3'h4: //J-Type
      imm = {{12{inst[24]}}, inst[12:5], inst[13], inst[23:14], 1'b0};
    default: //U-Type
      imm = {inst[24:5], {12{1'b0}}};
  endcase
end

endmodule