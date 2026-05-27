`include "riscv_pkg.vh"

module wallFtoD (
  input  wire        clk,
  input  wire        en,
  input  wire        clr,
  input  wire [31:0] InstrF,
  input  wire [31:0] PCF,
  input  wire [31:0] PCPlus4F,
  output reg  [31:0] InstrD = 32'b0,
  output reg  [31:0] PCD = 32'b0,
  output reg  [31:0] PCPlus4D = 32'b0
);

  always @(posedge clk) begin
    if (clr) begin
      InstrD   <= 32'b0;
      PCD      <= 32'b0;
      PCPlus4D <= 32'b0;
    end else if (en) begin
      InstrD   <= InstrF;
      PCD      <= PCF;
      PCPlus4D <= PCPlus4F;
    end
  end

endmodule
