`include "riscv_pkg.vh"

module extend (
  input  wire [31:7] instr,
  input  wire [`IMM_SRC_SIZE-1:0] immsrc,
  output reg  [31:0] immext
);

  always @(*) begin
    case (immsrc)
      `EXT_I_TYPE:
        immext = {{20{instr[31]}}, instr[31:20]};
      `EXT_S_TYPE:
        immext = {{20{instr[31]}}, instr[31:25], instr[11:7]};
      `EXT_B_TYPE:
        immext = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
      `EXT_J_TYPE:
        immext = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};
      `EXT_U_TYPE:
        immext = {instr[31:12], 12'b0};
      default:
        immext = 32'bX;
    endcase
  end

endmodule
