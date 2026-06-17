`include "../include/riscv_pkg.vh"

module instruction_memory_fast #(
  parameter IMEM_SIZE    = 256,
  parameter TEXT_SEGMENT = "./files/text.txt"
) (
  input  wire [31:0] A,
  output wire [31:0] RD
);

  localparam integer IDX_MSB = $clog2(IMEM_SIZE) + 2;

  reg [31:0] imem [0:IMEM_SIZE-1];

  initial begin
`ifndef SYNTHESIS
    $readmemh(TEXT_SEGMENT, imem);
`endif
  end

  assign RD = imem[A[IDX_MSB:2]];

endmodule
