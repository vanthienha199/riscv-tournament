`include "riscv_pkg.vh"

module mux_3 (
  input  wire [31:0] d0,
  input  wire [31:0] d1,
  input  wire [31:0] d2,
  input  wire [1:0]  s,
  output reg  [31:0] y
);

  always @(*) begin
    case (s)
      2'b00: y = d0;
      2'b01: y = d1;
      2'b10: y = d2;
      default: y = 32'b0;
    endcase
  end

endmodule
