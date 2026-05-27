`include "riscv_pkg.vh"

module branch_unit (
  input  wire [3:0] Flags,
  input  wire       Branch,
  input  wire       Jump,
  input  wire [2:0] funct3,
  output wire       PCSrc
);

  reg BranchType;

  always @(*) begin
    case (funct3)
      3'b000: BranchType = Flags[`ALU_FLAG_Z];
      3'b001: BranchType = ~Flags[`ALU_FLAG_Z];
      3'b100: BranchType = Flags[`ALU_FLAG_N] ^ Flags[`ALU_FLAG_V];
      3'b101: BranchType = ~(Flags[`ALU_FLAG_N] ^ Flags[`ALU_FLAG_V]);
      3'b110: BranchType = ~Flags[`ALU_FLAG_C];
      3'b111: BranchType = Flags[`ALU_FLAG_C];
      default: BranchType = 1'b0;
    endcase
  end

  assign PCSrc = (Branch & BranchType) | Jump;

endmodule
