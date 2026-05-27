`include "../include/riscv_pkg.vh"

module gpio_mem (
  input  wire        clk,
  input  wire        WE,
  input  wire [`IOMEM_LEN-1:0] A,
  input  wire [31:0] WD,
  input  wire        btn,
  output reg  [31:0] RD,
  output wire        led1,
  output wire        led2,
  output wire        led3,
  output wire        led4,
  output wire        led5,
  output wire        led6,
  output wire        led7,
  output wire        led8
);

  reg [31:0] regs [0:`IOMEM_SIZE-1];

  wire [`IOMEM_LEN-1:0] word_index = A[`IOMEM_LEN-1:2];

  always @(posedge clk) begin
    if (WE)
      regs[word_index] <= WD;
    RD <= regs[word_index];
  end

  assign led1 = regs[0][0];
  assign led2 = regs[0][1];
  assign led3 = regs[0][2];
  assign led4 = regs[0][3];
  assign led5 = regs[0][4];
  assign led6 = regs[0][5];
  assign led7 = regs[0][6];
  assign led8 = regs[0][7];

endmodule
