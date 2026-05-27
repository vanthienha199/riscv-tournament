`include "riscv_pkg.vh"

module hazard_unit (
  input  wire [4:0] Rs1D,
  input  wire [4:0] Rs2D,
  input  wire [4:0] Rs1E,
  input  wire [4:0] Rs2E,
  input  wire [4:0] RdE,
  input  wire       RegWriteE,
  input  wire       PCSrcE,
  input  wire [1:0] ResultSrcE,
  input  wire [4:0] RdM,
  input  wire       RegWriteM,
  input  wire [4:0] RdW,
  input  wire       RegWriteW,
  output wire [1:0] ForwardAE,
  output wire [1:0] ForwardBE,
  output wire       StallF,
  output wire       StallD,
  output wire       FlushD,
  output wire       FlushE
`ifdef SIMULATION
  , input wire g_ecall
`endif
);

  wire load_use_hazard;
  wire ecall_stall;
  wire ecall_arg_pending;

  assign load_use_hazard = (ResultSrcE[0] == 1'b1) &&
                           ((Rs1D == RdE) || (Rs2D == RdE));

`ifdef SIMULATION
  /* Wait for in-flight writes to a0/a1 before ecall in decode retires (match VHDL). */
  assign ecall_arg_pending =
      (RdE == `A0_REG) || (RdM == `A0_REG) || (RdW == `A0_REG) ||
      (RdE == `A1_REG) || (RdM == `A1_REG) || (RdW == `A1_REG);

  assign ecall_stall = (g_ecall == 1'b1) && ecall_arg_pending;
`else
  assign ecall_stall = 1'b0;
`endif

  wire [1:0] forward_ae;
  wire [1:0] forward_be;

  assign forward_ae =
    ((Rs1E == RdM) && RegWriteM && (Rs1E != 5'd0)) ? 2'b10 :
    ((Rs1E == RdW) && RegWriteW && (Rs1E != 5'd0)) ? 2'b01 : 2'b00;

  assign forward_be =
    ((Rs2E == RdM) && RegWriteM && (Rs2E != 5'd0)) ? 2'b10 :
    ((Rs2E == RdW) && RegWriteW && (Rs2E != 5'd0)) ? 2'b01 : 2'b00;

  assign ForwardAE = forward_ae;
  assign ForwardBE = forward_be;
  assign StallF = load_use_hazard || ecall_stall;
  assign StallD = load_use_hazard || ecall_stall;
  assign FlushD = PCSrcE;
  assign FlushE = load_use_hazard || PCSrcE;

endmodule
