`include "riscv_pkg.vh"

module instr_decoder (
  input  wire [6:0] op,
  output reg  [`IMM_SRC_SIZE-1:0] ImmSrc
);

  always @(*) begin
    case (op)
      7'b0000011, 7'b0010011: ImmSrc = `EXT_I_TYPE;
      7'b0100011:             ImmSrc = `EXT_S_TYPE;
      7'b1100011:             ImmSrc = `EXT_B_TYPE;
      7'b1101111:             ImmSrc = `EXT_J_TYPE;
      7'b1100111:             ImmSrc = `EXT_I_TYPE;
      7'b0110111, 7'b0010111: ImmSrc = `EXT_U_TYPE;
      default:                ImmSrc = {`IMM_SRC_SIZE{1'b0}};
    endcase
  end

endmodule
