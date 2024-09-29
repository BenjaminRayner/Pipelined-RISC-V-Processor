module alu(
  input wire [3:0] ALUSel,
  input wire [31:0] ALU1,
  input wire [31:0] ALU2,
  output reg [31:0] ALUout
);

always@(*)
begin
  case(ALUSel)
    4'h0: //Sub
      ALUout = $signed(ALU1) - $signed(ALU2);
    4'h1: //Add
      ALUout = $signed(ALU1) + $signed(ALU2);
    4'h2: //Shift Left Logical
      ALUout = ALU1 << ALU2[4:0];
    4'h3: //Set Less Than
      ALUout = ($signed(ALU1) < $signed(ALU2)) ? 1 : 0;
    4'h4: //Set Less Than Unsigned
      ALUout = (ALU1 < ALU2) ? 1 : 0;
    4'h5: //XOR
      ALUout = ALU1 ^ ALU2;
    4'h6: //Shift Right Arithmetic
      ALUout = $signed(ALU1) >>> ALU2[4:0];
    4'h7: //Shift Right Logical
      ALUout = ALU1 >> ALU2[4:0];
    4'h8: //OR
      ALUout = ALU1 | ALU2;
    4'h9: //AND
      ALUout = ALU1 & ALU2;
    default: //LUI (NO-OP)
      ALUout = ALU2;
  endcase
end

endmodule