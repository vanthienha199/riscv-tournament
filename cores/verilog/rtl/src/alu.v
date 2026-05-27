`include "riscv_pkg.vh"

module alu (
  input  wire [31:0] a,
  input  wire [31:0] b,
  input  wire [`ALU_CTRL_SIZE-1:0] ALUControl,
  output reg  [31:0] ALUResult,
  output wire [3:0] Flags
);

  wire [32:0] sum;

  assign sum = (ALUControl[0] == 1'b0) ?
                 ({1'b0, a} + {1'b0, b}) :
                 ({1'b0, a} + {1'b0, ~b} + 33'd1);

  assign Flags[`ALU_FLAG_N] = ALUResult[31];
  assign Flags[`ALU_FLAG_Z] = (ALUResult == 32'h00000000) ? 1'b1 : 1'b0;
  assign Flags[`ALU_FLAG_C] = (~ALUControl[1]) & sum[32];
  assign Flags[`ALU_FLAG_V] = (~(ALUControl[0] ^ a[31] ^ b[31])) &
                               (a[31] ^ sum[31]) &
                               (~ALUControl[1]);

  always @(*) begin
    case (ALUControl)
      `ALU_CTRL_ADD, `ALU_CTRL_SUB:
        ALUResult = sum[31:0];
      `ALU_CTRL_AND:
        ALUResult = a & b;
      `ALU_CTRL_OR:
        ALUResult = a | b;
      `ALU_CTRL_SLT:
        ALUResult = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
      `ALU_CTRL_SLTU:
        ALUResult = (a < b) ? 32'd1 : 32'd0;
      `ALU_CTRL_XOR:
        ALUResult = a ^ b;
      `ALU_CTRL_SLL:
        ALUResult = a << b[4:0];
      `ALU_CTRL_SRL:
        ALUResult = a >> b[4:0];
      `ALU_CTRL_SRA:
        ALUResult = $signed(a) >>> b[4:0];
      default:
        ALUResult = 32'bX;
    endcase
  end

endmodule
