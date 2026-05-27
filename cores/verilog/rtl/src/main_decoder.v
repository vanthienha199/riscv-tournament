`include "riscv_pkg.vh"

module main_decoder (
  input  wire [6:0] op,
  output wire [1:0] ResultSrc,
  output wire       MemWrite,
  output wire       Branch,
  output wire       ALUSrcA,
  output wire       ALUSrcB,
  output wire       PCTargetSrc,
  output wire       RegWrite,
  output wire       Jump,
  output wire [1:0] ALUOp,
  output wire       g_ecall
);

  reg [`CTRL_SIZE-1:0] controls;
  reg                  g_ecall_r;

  assign {RegWrite, ALUSrcA, ALUSrcB, PCTargetSrc, MemWrite,
          ResultSrc[1], ResultSrc[0], Branch, ALUOp[1], ALUOp[0], Jump} = controls;

  assign g_ecall = g_ecall_r;

  always @(*) begin
    controls = `CTRL_UNKNOWN;
    g_ecall_r = 1'b0;
    case (op)
      7'b0000011: controls = `CTRL_I_TYPE_LOAD;
      7'b0010011: controls = `CTRL_I_TYPE;
      7'b0100011: controls = `CTRL_S_TYPE;
      7'b0110011: controls = `CTRL_R_TYPE;
      7'b1100011: controls = `CTRL_B_TYPE;
      7'b1101111: controls = `CTRL_J_TYPE;
      7'b0110111: controls = `CTRL_U_TYPE_LUI;
      7'b0010111: controls = `CTRL_U_TYPE_AUIPC;
      7'b1100111: controls = `CTRL_I_TYPE_JALR;
      7'b0001111: controls = `CTRL_I_TYPE;
`ifdef SIMULATION
      7'b1110011: begin
        controls = `CTRL_I_TYPE_ECALL;
        g_ecall_r = 1'b1;
      end
`endif
      default: controls = `CTRL_UNKNOWN;
    endcase
  end

endmodule
