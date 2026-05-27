`include "riscv_pkg.vh"

module wallMtoW (
  input  wire        clk,
  input  wire        RegWriteM,
  input  wire [1:0]  ResultSrcM,
  input  wire [31:0] ALUResultM,
  input  wire [31:0] ReadDataM,
  input  wire [4:0]  RdM,
  input  wire [31:0] PCTargetM,
  input  wire [31:0] PCPlus4M,
  output reg         RegWriteW = 1'b0,
  output reg  [1:0]  ResultSrcW = 2'b0,
  output reg  [31:0] ALUResultW = 32'b0,
  output reg  [31:0] ReadDataW = 32'b0,
  output reg  [4:0]  RdW = 5'b0,
  output reg  [31:0] PCTargetW = 32'b0,
  output reg  [31:0] PCPlus4W = 32'b0
);

  always @(posedge clk) begin
    RegWriteW  <= RegWriteM;
    ResultSrcW <= ResultSrcM;
    ALUResultW <= ALUResultM;
    ReadDataW  <= ReadDataM;
    RdW        <= RdM;
    PCPlus4W   <= PCPlus4M;
    PCTargetW  <= PCTargetM;
  end

endmodule
