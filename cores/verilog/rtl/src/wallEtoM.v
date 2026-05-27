`include "riscv_pkg.vh"

module wallEtoM (
  input  wire        clk,
  input  wire        RegWriteE,
  input  wire [1:0]  ResultSrcE,
  input  wire        MemWriteE,
  input  wire [31:0] ALUResultE,
  input  wire [31:0] WriteDataE,
  input  wire [4:0]  RdE,
  input  wire [31:0] InstrE,
  input  wire [31:0] PCTargetE,
  input  wire [31:0] PCPlus4E,
  output reg         RegWriteM = 1'b0,
  output reg  [1:0]  ResultSrcM = 2'b0,
  output reg         MemWriteM = 1'b0,
  output reg  [31:0] ALUResultM = 32'b0,
  output reg  [31:0] WriteDataM = 32'b0,
  output reg  [4:0]  RdM = 5'b0,
  output reg  [31:0] InstrM = 32'b0,
  output reg  [31:0] PCTargetM = 32'b0,
  output reg  [31:0] PCPlus4M = 32'b0
);

  always @(posedge clk) begin
    RegWriteM  <= RegWriteE;
    ResultSrcM <= ResultSrcE;
    MemWriteM  <= MemWriteE;
    ALUResultM <= ALUResultE;
    WriteDataM <= WriteDataE;
    RdM        <= RdE;
    InstrM     <= InstrE;
    PCTargetM  <= PCTargetE;
    PCPlus4M   <= PCPlus4E;
  end

endmodule
