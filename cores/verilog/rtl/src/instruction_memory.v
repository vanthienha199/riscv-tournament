`include "../include/riscv_pkg.vh"

module instruction_memory #(
  parameter IMEM_SIZE    = 256,
  parameter TEXT_SEGMENT = "./files/text.txt"
) (
  input  wire [31:0] A,
  output wire [31:0] RD
);

  localparam integer WORD_IDX_MSB = $clog2(IMEM_SIZE) + 2;

  reg [31:0] imem [0:IMEM_SIZE-1];

  initial begin
    $readmemh(TEXT_SEGMENT, imem);
  end

  assign RD = imem[A[WORD_IDX_MSB:2]];

endmodule
