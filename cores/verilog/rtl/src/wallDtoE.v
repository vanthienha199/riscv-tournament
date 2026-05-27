`include "riscv_pkg.vh"

module wallDtoE (
  input  wire        clk,
  input  wire        clr,
  input  wire        JumpD,
  input  wire        BranchD,
  input  wire        RegWriteD,
  input  wire [1:0]  ResultSrcD,
  input  wire        MemWriteD,
  input  wire [`ALU_CTRL_SIZE-1:0] ALUControlD,
  input  wire        ALUSrcAD,
  input  wire        ALUSrcBD,
  input  wire        PCTargetSrcD,
  input  wire [31:0] InstrD,
  input  wire [31:0] RD1D,
  input  wire [31:0] RD2D,
  input  wire [4:0]  RdD,
  input  wire [31:0] PCD,
  input  wire [4:0]  Rs1D,
  input  wire [4:0]  Rs2D,
  input  wire [31:0] ImmExtD,
  input  wire [31:0] PCPlus4D,
  output reg         JumpE = 1'b0,
  output reg         BranchE = 1'b0,
  output reg         RegWriteE = 1'b0,
  output reg  [1:0]  ResultSrcE = 2'b0,
  output reg         MemWriteE = 1'b0,
  output reg  [`ALU_CTRL_SIZE-1:0] ALUControlE = {`ALU_CTRL_SIZE{1'b0}},
  output reg         ALUSrcAE = 1'b0,
  output reg         ALUSrcBE = 1'b0,
  output reg         PCTargetSrcE = 1'b0,
  output reg  [31:0] InstrE = 32'b0,
  output reg  [31:0] RD1E = 32'b0,
  output reg  [31:0] RD2E = 32'b0,
  output reg  [4:0]  RdE = 5'b0,
  output reg  [31:0] PCE = 32'b0,
  output reg  [4:0]  Rs1E = 5'b0,
  output reg  [4:0]  Rs2E = 5'b0,
  output reg  [31:0] ImmExtE = 32'b0,
  output reg  [31:0] PCPlus4E = 32'b0
);

  always @(posedge clk) begin
    if (clr) begin
      JumpE        <= 1'b0;
      BranchE      <= 1'b0;
      RegWriteE    <= 1'b0;
      ResultSrcE   <= 2'b0;
      MemWriteE    <= 1'b0;
      ALUControlE  <= {`ALU_CTRL_SIZE{1'b0}};
      ALUSrcAE     <= 1'b0;
      ALUSrcBE     <= 1'b0;
      PCTargetSrcE <= 1'b0;
      InstrE       <= 32'b0;
      RD1E         <= 32'b0;
      RD2E         <= 32'b0;
      RdE          <= 5'b0;
      PCE          <= 32'b0;
      Rs1E         <= 5'b0;
      Rs2E         <= 5'b0;
      ImmExtE      <= 32'b0;
      PCPlus4E     <= 32'b0;
    end else begin
      JumpE        <= JumpD;
      BranchE      <= BranchD;
      RegWriteE    <= RegWriteD;
      ResultSrcE   <= ResultSrcD;
      MemWriteE    <= MemWriteD;
      ALUControlE  <= ALUControlD;
      ALUSrcAE     <= ALUSrcAD;
      ALUSrcBE     <= ALUSrcBD;
      PCTargetSrcE <= PCTargetSrcD;
      InstrE       <= InstrD;
      RD1E         <= RD1D;
      RD2E         <= RD2D;
      RdE          <= RdD;
      PCE          <= PCD;
      Rs1E         <= Rs1D;
      Rs2E         <= Rs2D;
      ImmExtE      <= ImmExtD;
      PCPlus4E     <= PCPlus4D;
    end
  end

endmodule
