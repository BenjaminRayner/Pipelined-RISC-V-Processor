module branch_comp(
  input wire [31:0] data_rs1,
  input wire [31:0] data_rs2,
  input wire BrUn,
  output wire BrEq,
  output wire BrLT
);

assign BrEq = (data_rs1 == data_rs2);
assign BrLT = ((BrUn && (data_rs1 < data_rs2)) || (!BrUn && ($signed(data_rs1) < $signed(data_rs2))));

endmodule
