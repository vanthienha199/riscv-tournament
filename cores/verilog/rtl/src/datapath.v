`include "../include/riscv_pkg.vh"

module datapath #(
  parameter IMEM_SIZE    = 256,
  parameter DMEM_SIZE    = 256,
  parameter TEXT_SEGMENT = "./files/text.txt",
  parameter DATA_SEGMENT = "./files/data.txt"
) (
  input  wire        clk,
  input  wire        RegWriteD,
  input  wire [1:0]  ResultSrcD,
  input  wire        MemWriteD,
  input  wire        JumpD,
  input  wire        BranchD,
  input  wire [3:0]  ALUControlD,
  input  wire        ALUSrcAD,
  input  wire        ALUSrcBD,
  input  wire        PCTargetSrcD,
  input  wire [2:0]  ImmSrcD,
  input  wire        g_ecall,
  output wire [31:0] InstrE,
  output wire [31:0] InstrD,
  input  wire        btn,
  output wire        led1,
  output wire        led2,
  output wire        led3,
  output wire        led4,
  output wire        led5,
  output wire        led6,
  output wire        led7,
  output wire        led8
  `ifdef SIMULATION
  ,
  output wire [31:0] registers [0:`REGS_SIZE-1],
  output wire [31:0] data [0:DMEM_SIZE-1]
  `endif
);

  wire [31:0] PCFtick;
  wire [31:0] PCF;
  wire [31:0] InstrF;
  wire [31:0] PCPlus4F;

  wire [31:0] PCD;
  wire [31:0] PCPlus4D;
  wire [31:0] RD1D;
  wire [31:0] RD2D;
  wire [31:0] ImmExtD;

  wire        RegWriteE;
  wire [1:0]  ResultSrcE;
  wire        MemWriteE;
  wire        JumpE;
  wire        BranchE;
  wire [3:0]  ALUControlE;
  wire        ALUSrcAE;
  wire        ALUSrcBE;
  wire        PCTargetSrcE;
  wire [31:0] PCPlus4E;
  wire [31:0] RD1E;
  wire [31:0] PCE;
  wire [31:0] RD2E;
  wire [4:0]  RdE;
  wire [4:0]  Rs1E;
  wire [4:0]  Rs2E;
  wire [31:0] ImmExtE;

  wire [3:0]  FlagsE;
  wire [31:0] PCSelE;
  wire        PCSrcE;
  wire [31:0] PCTargetE;
  wire [31:0] AE;
  wire [31:0] BE;
  wire [31:0] SrcAE;
  wire [31:0] SrcBE;
  wire [31:0] ALUResultE;

  wire        RegWriteM;
  wire [1:0]  ResultSrcM;
  wire        MemWriteM;
  wire [31:0] ALUResultM;
  wire [31:0] WriteDataM;
  wire [4:0]  RdM;
  wire [31:0] PCPlus4M;
  wire [31:0] ReadDataM;
  wire [31:0] PCTargetM;
  wire [31:0] InstrM;
  wire [31:0] DataWriteM;
  wire [31:0] ResultMuxData;

  wire        RegWriteW;
  wire [1:0]  ResultSrcW;
  wire [31:0] ALUResultW;
  wire [31:0] ReadDataW;
  wire [4:0]  RdW;
  wire [31:0] PCPlus4W;
  wire [31:0] ResultW;
  wire [31:0] PCTargetW;

  wire        StallF;
  wire        StallD;
  wire        FlushD;
  wire        FlushE;
  wire [1:0]  ForwardAE;
  wire [1:0]  ForwardBE;

  wire rf_clk = ~clk;

  mux_2 pcmux (
    .d0 (PCPlus4F),
    .d1 (PCSelE),
    .s  (PCSrcE),
    .y  (PCFtick)
  );

  d_ff_en pcreg (
    .clk (clk),
    .en  (~StallF),
    .d   (PCFtick),
    .q   (PCF)
  );

  adder pcadd4 (
    .a (PCF),
    .b (32'd4),
    .y (PCPlus4F)
  );

  instruction_memory #(
    .IMEM_SIZE(IMEM_SIZE),
    .TEXT_SEGMENT(TEXT_SEGMENT)
  ) imem (
    .A  (PCF),
    .RD (InstrF)
  );

  wallFtoD wfd (
    .clk      (clk),
    .en       (~StallD),
    .clr      (FlushD),
    .InstrF   (InstrF),
    .PCF      (PCF),
    .PCPlus4F (PCPlus4F),
    .InstrD   (InstrD),
    .PCD      (PCD),
    .PCPlus4D (PCPlus4D)
  );

  extend ext (
    .instr  (InstrD[31:7]),
    .immsrc (ImmSrcD),
    .immext (ImmExtD)
  );

  register_file rf (
    .clk (rf_clk),
    .A1  (InstrD[19:15]),
    .A2  (InstrD[24:20]),
    .A3  (RdW),
    .WE3 (RegWriteW),
    .WD3 (ResultW),
    .RD1 (RD1D),
    .RD2 (RD2D)
    `ifdef SIMULATION
    ,
    .registers (registers)
    `endif
  );

  wallDtoE wde (
    .clk          (clk),
    .clr          (FlushE),
    .JumpD        (JumpD),
    .BranchD      (BranchD),
    .RegWriteD    (RegWriteD),
    .ResultSrcD   (ResultSrcD),
    .MemWriteD    (MemWriteD),
    .ALUControlD  (ALUControlD),
    .ALUSrcAD     (ALUSrcAD),
    .ALUSrcBD     (ALUSrcBD),
    .PCTargetSrcD (PCTargetSrcD),
    .InstrD       (InstrD),
    .RD1D         (RD1D),
    .RD2D         (RD2D),
    .RdD          (InstrD[11:7]),
    .PCD          (PCD),
    .Rs1D         (InstrD[19:15]),
    .Rs2D         (InstrD[24:20]),
    .ImmExtD      (ImmExtD),
    .PCPlus4D     (PCPlus4D),
    .JumpE        (JumpE),
    .BranchE      (BranchE),
    .RegWriteE    (RegWriteE),
    .ResultSrcE   (ResultSrcE),
    .MemWriteE    (MemWriteE),
    .ALUControlE  (ALUControlE),
    .ALUSrcAE     (ALUSrcAE),
    .ALUSrcBE     (ALUSrcBE),
    .PCTargetSrcE (PCTargetSrcE),
    .InstrE       (InstrE),
    .RD1E         (RD1E),
    .RD2E         (RD2E),
    .RdE          (RdE),
    .PCE          (PCE),
    .Rs1E         (Rs1E),
    .Rs2E         (Rs2E),
    .ImmExtE      (ImmExtE),
    .PCPlus4E     (PCPlus4E)
  );

  mux_3 fwdA (
    .d0 (RD1E),
    .d1 (ResultW),
    .d2 (ALUResultM),
    .s  (ForwardAE),
    .y  (AE)
  );

  mux_3 fwdB (
    .d0 (RD2E),
    .d1 (ResultW),
    .d2 (ALUResultM),
    .s  (ForwardBE),
    .y  (BE)
  );

  mux_2 srcamux (
    .d0 (AE),
    .d1 (32'd0),
    .s  (ALUSrcAE),
    .y  (SrcAE)
  );

  mux_2 srcbmux (
    .d0 (BE),
    .d1 (ImmExtE),
    .s  (ALUSrcBE),
    .y  (SrcBE)
  );

  alu mainalu (
    .a          (SrcAE),
    .b          (SrcBE),
    .ALUControl (ALUControlE),
    .ALUResult  (ALUResultE),
    .Flags      (FlagsE)
  );

  branch_unit bu (
    .Flags  (FlagsE),
    .Branch (BranchE),
    .Jump   (JumpE),
    .funct3 (InstrE[14:12]),
    .PCSrc  (PCSrcE)
  );

  adder pcaddbranch (
    .a (PCE),
    .b (ImmExtE),
    .y (PCTargetE)
  );

  mux_2 pct (
    .d0 (PCTargetE),
    .d1 (ALUResultE),
    .s  (PCTargetSrcE),
    .y  (PCSelE)
  );

  wallEtoM wem (
    .clk         (clk),
    .RegWriteE   (RegWriteE),
    .ResultSrcE  (ResultSrcE),
    .MemWriteE   (MemWriteE),
    .ALUResultE  (ALUResultE),
    .WriteDataE  (BE),
    .RdE         (RdE),
    .InstrE      (InstrE),
    .PCTargetE   (PCTargetE),
    .PCPlus4E    (PCPlus4E),
    .RegWriteM   (RegWriteM),
    .ResultSrcM  (ResultSrcM),
    .MemWriteM   (MemWriteM),
    .ALUResultM  (ALUResultM),
    .WriteDataM  (WriteDataM),
    .RdM         (RdM),
    .InstrM      (InstrM),
    .PCTargetM   (PCTargetM),
    .PCPlus4M    (PCPlus4M)
  );

  memory_router #(
    .DMEM_SIZE(DMEM_SIZE),
    .DATA_SEGMENT(DATA_SEGMENT)
  ) mmio (
    .clk  (clk),
    .WE   (MemWriteM),
    .A    (ALUResultM),
    .WD   (DataWriteM),
    .btn  (btn),
    .RD   (ReadDataM),
    .led1 (led1),
    .led2 (led2),
    .led3 (led3),
    .led4 (led4),
    .led5 (led5),
    .led6 (led6),
    .led7 (led7),
    .led8 (led8)
    `ifdef SIMULATION
    ,
    .data (data)
    `endif
  );

  rd_unit rd (
    .DataIn  (ReadDataM),
    .funct3  (InstrM[14:12]),
    .Address (ALUResultM),
    .DataOut (ResultMuxData)
  );

  wd_unit wd (
    .RD2      (WriteDataM),
    .ReadData (ReadDataM),
    .funct3   (InstrM[14:12]),
    .Address  (ALUResultM),
    .DataOut  (DataWriteM)
  );

  wallMtoW wmw (
    .clk         (clk),
    .RegWriteM   (RegWriteM),
    .ResultSrcM  (ResultSrcM),
    .ALUResultM  (ALUResultM),
    .ReadDataM   (ResultMuxData),
    .RdM         (RdM),
    .PCTargetM   (PCTargetM),
    .PCPlus4M    (PCPlus4M),
    .RegWriteW   (RegWriteW),
    .ResultSrcW  (ResultSrcW),
    .ALUResultW  (ALUResultW),
    .ReadDataW   (ReadDataW),
    .RdW         (RdW),
    .PCTargetW   (PCTargetW),
    .PCPlus4W    (PCPlus4W)
  );

  mux_4 resultmux (
    .d0 (ALUResultW),
    .d1 (ReadDataW),
    .d2 (PCPlus4W),
    .d3 (PCTargetW),
    .s  (ResultSrcW),
    .y  (ResultW)
  );

`ifdef SIMULATION
  hazard_unit hu (
    .Rs1D       (InstrD[19:15]),
    .Rs2D       (InstrD[24:20]),
    .Rs1E       (Rs1E),
    .Rs2E       (Rs2E),
    .RdE        (RdE),
    .RegWriteE  (RegWriteE),
    .PCSrcE     (PCSrcE),
    .ResultSrcE (ResultSrcE),
    .RdM        (RdM),
    .RegWriteM  (RegWriteM),
    .RdW        (RdW),
    .RegWriteW  (RegWriteW),
    .g_ecall    (g_ecall),
    .StallF     (StallF),
    .StallD     (StallD),
    .FlushD     (FlushD),
    .FlushE     (FlushE),
    .ForwardAE  (ForwardAE),
    .ForwardBE  (ForwardBE)
  );
`else
  hazard_unit hu (
    .Rs1D       (InstrD[19:15]),
    .Rs2D       (InstrD[24:20]),
    .Rs1E       (Rs1E),
    .Rs2E       (Rs2E),
    .RdE        (RdE),
    .RegWriteE  (RegWriteE),
    .PCSrcE     (PCSrcE),
    .ResultSrcE (ResultSrcE),
    .RdM        (RdM),
    .RegWriteM  (RegWriteM),
    .RdW        (RdW),
    .RegWriteW  (RegWriteW),
    .StallF     (StallF),
    .StallD     (StallD),
    .FlushD     (FlushD),
    .FlushE     (FlushE),
    .ForwardAE  (ForwardAE),
    .ForwardBE  (ForwardBE)
  );
`endif

endmodule
