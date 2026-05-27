`include "riscv_pkg.vh"

module alu_decoder (
  input  wire       op_5,
  input  wire [2:0] funct3,
  input  wire       funct7_5,
  input  wire [1:0] ALUOp,
  output reg  [`ALU_CTRL_SIZE-1:0] ALUControl
);

  always @(*) begin
    case (ALUOp)
      2'b00:
        ALUControl = `ALU_CTRL_ADD;
      2'b01:
        ALUControl = `ALU_CTRL_SUB;
      2'b10:
        case (funct3)
          3'b000:
            if ((funct7_5 & op_5) == 1'b1)
              ALUControl = `ALU_CTRL_SUB;
            else
              ALUControl = `ALU_CTRL_ADD;
          3'b001: ALUControl = `ALU_CTRL_SLL;
          3'b010: ALUControl = `ALU_CTRL_SLT;
          3'b011: ALUControl = `ALU_CTRL_SLTU;
          3'b100: ALUControl = `ALU_CTRL_XOR;
          3'b101:
            if (funct7_5 == 1'b1)
              ALUControl = `ALU_CTRL_SRA;
            else
              ALUControl = `ALU_CTRL_SRL;
          3'b110: ALUControl = `ALU_CTRL_OR;
          3'b111: ALUControl = `ALU_CTRL_AND;
          default: ALUControl = `ALU_CTRL_UKNWN;
        endcase
      default:
        ALUControl = `ALU_CTRL_UKNWN;
    endcase
  end

endmodule
