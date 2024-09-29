module register_file(
  input wire clock,
  input wire write_enable,
  input wire [31:0] data_rd,
  input wire [4:0] addr_rd,
  input wire [4:0] addr_rs1,
  input wire [4:0] addr_rs2,
  output wire [31:0] data_rs1,
  output wire [31:0] data_rs2
);

reg [31:0] registers[31:0];

//Set stack pointer
initial begin
  registers[2] = `MEM_DEPTH + 32'h01000000;
end

//Write
always@(posedge clock)
begin
  if (write_enable & (addr_rd != 5'h00)) registers[addr_rd] <= data_rd;
end

//Read
assign data_rs1 = registers[addr_rs1];
assign data_rs2 = registers[addr_rs2];

endmodule
