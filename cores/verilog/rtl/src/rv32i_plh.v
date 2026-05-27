`include "../include/riscv_pkg.vh"

module rv32i_plh #(
  parameter IMEM_SIZE    = 256,
  parameter DMEM_SIZE    = 256,
  parameter TEXT_SEGMENT = "./files/text.txt",
  parameter DATA_SEGMENT = "./files/data.txt"
) (
  input  wire clk,
  input  wire btn,
  output wire led1,
  output wire led2,
  output wire led3,
  output wire led4,
  output wire led5,
  output wire led6,
  output wire led7,
  output wire led8
  `ifdef SIMULATION
  ,
  output wire [31:0] registers [0:`REGS_SIZE-1],
  output wire [31:0] data [0:DMEM_SIZE-1],
  output wire        g_ecall
  `endif
);

  wire        RegWrite;
  wire [1:0]  ResultSrc;
  wire        MemWrite;
  wire        Branch;
  wire        Jump;
  wire        ALUSrcA;
  wire        ALUSrcB;
  wire        PCTargetSrc;
  wire [2:0]  ImmSrc;
  wire [3:0]  ALUControl;
  wire [31:0] Instr;
  wire        g_ecallD;
  wire [31:0] InstrE;

  control_unit c (
    .op          (Instr[6:0]),
    .funct3      (Instr[14:12]),
    .funct7_5    (Instr[30]),
    .Branch      (Branch),
    .Jump        (Jump),
    .ResultSrc   (ResultSrc),
    .MemWrite    (MemWrite),
    .ALUSrcA     (ALUSrcA),
    .ALUSrcB     (ALUSrcB),
    .PCTargetSrc (PCTargetSrc),
    .RegWrite    (RegWrite),
    .ImmSrc      (ImmSrc),
    .ALUControl  (ALUControl),
    .g_ecall     (g_ecallD)
  );

`ifdef SIMULATION
  assign g_ecall = g_ecallD;
`endif

  datapath #(
    .IMEM_SIZE(IMEM_SIZE),
    .DMEM_SIZE(DMEM_SIZE),
    .TEXT_SEGMENT(TEXT_SEGMENT),
    .DATA_SEGMENT(DATA_SEGMENT)
  ) dp (
    .clk          (clk),
    .RegWriteD    (RegWrite),
    .ResultSrcD   (ResultSrc),
    .MemWriteD    (MemWrite),
    .JumpD        (Jump),
    .BranchD      (Branch),
    .ALUControlD  (ALUControl),
    .ALUSrcAD     (ALUSrcA),
    .ALUSrcBD     (ALUSrcB),
    .PCTargetSrcD (PCTargetSrc),
    .ImmSrcD      (ImmSrc),
    .g_ecall      (g_ecallD),
    .InstrE       (InstrE),
    .InstrD       (Instr),
    .btn          (btn),
    .led1         (led1),
    .led2         (led2),
    .led3         (led3),
    .led4         (led4),
    .led5         (led5),
    .led6         (led6),
    .led7         (led7),
    .led8         (led8)
    `ifdef SIMULATION
    ,
    .registers (registers),
    .data      (data)
    `endif
  );

endmodule
