`include "riscv_pkg.vh"

module d_ff_en (
  input  wire        clk,
  input  wire        en,
  input  wire [31:0] d,
  output wire [31:0] q
);

  reg [31:0] q_tmp = 32'h0;

  assign q = q_tmp;

  always @(posedge clk) begin
    if (en)
      q_tmp <= d;
  end

endmodule
