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

  // Only word 0 is a real register (it drives the LEDs). The other words in
  // the GPIO window used to be a scratch array that nothing observes; they
  // now read as zero, which keeps the address decode and the word 0 behavior
  // unchanged while dropping the unobservable storage.
  reg [31:0] regs0;

  wire [`IOMEM_LEN-1:0] word_index = A[`IOMEM_LEN-1:2];
  wire                  sel0       = (word_index == {`IOMEM_LEN{1'b0}});

  always @(posedge clk) begin
    if (WE && sel0)
      regs0 <= WD;
    RD <= sel0 ? regs0 : 32'b0;
  end

  /* LEDs tap GPIO word [27:20]: counter runs from bit 0, visible once carries reach bit 20. */
`ifdef SYNTHESIS
  assign led1 = ~regs0[15];
  assign led2 = ~regs0[16];
  assign led3 = ~regs0[17];
  assign led4 = ~regs0[18];
  assign led5 = ~regs0[19];
  assign led6 = ~regs0[20];
  assign led7 = ~regs0[21];
  assign led8 = ~regs0[22];
`else
  assign led1 = regs0[15];
  assign led2 = regs0[16];
  assign led3 = regs0[17];
  assign led4 = regs0[18];
  assign led5 = regs0[19];
  assign led6 = regs0[20];
  assign led7 = regs0[21];
  assign led8 = regs0[22];
`endif

endmodule
