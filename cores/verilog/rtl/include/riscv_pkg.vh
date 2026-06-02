`ifndef RISCV_PKG_VH
`define RISCV_PKG_VH

`define REGS_SIZE 32
`define IOMEM_SIZE 64
`define IOMEM_LEN 6

`define CTRL_SIZE 11
`define CTRL_I_TYPE_LOAD   11'b10100010000
`define CTRL_I_TYPE        11'b10100000100
`define CTRL_S_TYPE        11'b00101000000
`define CTRL_R_TYPE        11'b10000000100
`define CTRL_B_TYPE        11'b00000001010
`define CTRL_J_TYPE        11'b10000100001
`define CTRL_U_TYPE_LUI    11'b11100000000
`define CTRL_U_TYPE_AUIPC  11'b10000110000
`define CTRL_I_TYPE_JALR   11'b10110100001
`define CTRL_I_TYPE_ECALL  11'b00000000000
`define CTRL_UNKNOWN       11'b00000000000

`define ALU_CTRL_SIZE 4
`define ALU_CTRL_ADD   4'b0000
`define ALU_CTRL_SUB   4'b0001
`define ALU_CTRL_AND   4'b0010
`define ALU_CTRL_OR    4'b0011
`define ALU_CTRL_XOR   4'b0100
`define ALU_CTRL_SLT   4'b0101
`define ALU_CTRL_SLL   4'b0110
`define ALU_CTRL_SRL   4'b0111
`define ALU_CTRL_SRA   4'b1000
`define ALU_CTRL_SLTU  4'b1001
`define ALU_CTRL_UKNWN 4'b1111

`define ALU_FLAGS_SIZE 4
`define ALU_FLAG_N 3
`define ALU_FLAG_Z 2
`define ALU_FLAG_C 1
`define ALU_FLAG_V 0

`define IMM_SRC_SIZE 3
`define EXT_I_TYPE 3'b000
`define EXT_S_TYPE 3'b001
`define EXT_B_TYPE 3'b010
`define EXT_J_TYPE 3'b011
`define EXT_U_TYPE 3'b100

`ifdef SIMULATION
`define A0_REG 10
`define A1_REG 11
`endif

`endif
