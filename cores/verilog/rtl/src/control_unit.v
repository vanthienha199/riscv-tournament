`include "riscv_pkg.vh"

module control_unit (
  input  wire [6:0] op,
  input  wire [2:0] funct3,
  input  wire       funct7_5,
  output wire       Branch,
  output wire       Jump,
  output wire [1:0] ResultSrc,
  output wire       MemWrite,
  output wire       ALUSrcA,
  output wire       ALUSrcB,
  output wire       PCTargetSrc,
  output wire       RegWrite,
  output wire [`IMM_SRC_SIZE-1:0] ImmSrc,
  output wire [`ALU_CTRL_SIZE-1:0] ALUControl,
  output wire       g_ecall
);

  wire [1:0] ALUOp;

  main_decoder md (
    .op(op),
    .ResultSrc(ResultSrc),
    .MemWrite(MemWrite),
    .Branch(Branch),
    .ALUSrcA(ALUSrcA),
    .ALUSrcB(ALUSrcB),
    .PCTargetSrc(PCTargetSrc),
    .RegWrite(RegWrite),
    .Jump(Jump),
    .ALUOp(ALUOp),
    .g_ecall(g_ecall)
  );

  alu_decoder ad (
    .op_5(op[5]),
    .funct3(funct3),
    .funct7_5(funct7_5),
    .ALUOp(ALUOp),
    .ALUControl(ALUControl)
  );

  instr_decoder id (
    .op(op),
    .ImmSrc(ImmSrc)
  );

endmodule
