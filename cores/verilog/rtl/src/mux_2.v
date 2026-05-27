`include "riscv_pkg.vh"

module mux_2 (
  input  wire [31:0] d0,
  input  wire [31:0] d1,
  input  wire        s,
  output reg  [31:0] y
);

  always @(*) begin
    if (s == 1'b1)
      y = d1;
    else if (s == 1'b0)
      y = d0;
    else
      y = 32'b0;
  end

endmodule
