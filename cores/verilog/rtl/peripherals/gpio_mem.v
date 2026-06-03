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

  /* LEDs tap GPIO word [27:20]: counter runs from bit 0, visible once carries reach bit 20. */
`ifdef SYNTHESIS
  assign led1 = ~regs[0][15];
  assign led2 = ~regs[0][16];
  assign led3 = ~regs[0][17];
  assign led4 = ~regs[0][18];
  assign led5 = ~regs[0][19];
  assign led6 = ~regs[0][20];
  assign led7 = ~regs[0][21];
  assign led8 = ~regs[0][22];
`else
  assign led1 = regs[0][15];
  assign led2 = regs[0][16];
  assign led3 = regs[0][17];
  assign led4 = regs[0][18];
  assign led5 = regs[0][19];
  assign led6 = regs[0][20];
  assign led7 = regs[0][21];
  assign led8 = regs[0][22];
`endif

endmodule
