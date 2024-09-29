module imemory(
  input wire [31:0] addr,
  output wire [31:0] inst
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
  assign inst = {mem[addr+3], mem[addr+2], mem[addr+1], mem[addr]};

endmodule
