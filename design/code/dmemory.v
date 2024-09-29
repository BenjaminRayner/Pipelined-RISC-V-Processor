module dmemory(
  input wire clock,
  input wire [31:0] addr,
  input wire [31:0] data,
  input wire [1:0] AccSize,
  input wire MemUn,
  input wire MemWEn,
  output reg [31:0] MemOut
);

  integer i;
  reg [7:0] mem[`MEM_DEPTH:0];
  reg [31:0] temp[`LINE_COUNT:0];

  //Load mem
  initial
  begin
    $readmemh(`MEM_PATH, temp);
    for (i = 0; i < `LINE_COUNT; i = i + 1)
    begin
        {mem[`PC_START+(`INST_BYTES*i+3)], mem[`PC_START+(`INST_BYTES*i+2)],
        mem[`PC_START+(`INST_BYTES*i+1)], mem[`PC_START+(`INST_BYTES*i)]} = temp[i];
    end
  end

//Read
always@(*) begin
  case(AccSize)
    2'h0:
    begin
      if (MemUn) MemOut = {{24{1'b0}}, mem[addr]};         //LBU
      else       MemOut = {{24{mem[addr][7]}}, mem[addr]}; //LB
    end
    2'h1:
    begin
      if (MemUn) MemOut = {{16{1'b0}}, mem[addr+1], mem[addr]};           //LHU
      else       MemOut = {{16{mem[addr+1][7]}}, mem[addr+1], mem[addr]}; //LH
    end
    default:     MemOut = {mem[addr+3], mem[addr+2], mem[addr+1], mem[addr]}; //LW
  endcase
end

//Write
always@(posedge clock) begin
  if (MemWEn) begin
    case(AccSize)
      2'h0: mem[addr] <= data[7:0];  //SB
      2'h1: {mem[addr+1], mem[addr]} <= data[15:0];  //SH
      default: {mem[addr+3], mem[addr+2], mem[addr+1], mem[addr]} <= data;  //SW
    endcase
  end
end


endmodule
