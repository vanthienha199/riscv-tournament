`include "../include/riscv_pkg.vh"

module register_file (
  input  wire        clk,
  input  wire [4:0]  A1,
  input  wire [4:0]  A2,
  input  wire [4:0]  A3,
  input  wire        WE3,
  input  wire [31:0] WD3,
  output wire [31:0] RD1,
  output wire [31:0] RD2
  `ifdef SIMULATION
  ,
  output wire [31:0] registers [0:`REGS_SIZE-1]
  `endif
);

  reg [31:0] regs [0:`REGS_SIZE-1];

  integer ri;
  initial begin
    for (ri = 0; ri < `REGS_SIZE; ri = ri + 1)
      regs[ri] = 32'h0;
  end

  `ifdef SIMULATION
  genvar gi;
  generate
    for (gi = 0; gi < `REGS_SIZE; gi = gi + 1) begin : gen_reg_probe
      assign registers[gi] = regs[gi];
    end
  endgenerate
  `endif

  always @(posedge clk) begin
    if (WE3)
      regs[A3] <= WD3;
  end

  assign RD1 = (A1 == 5'd0) ? 32'h00000000 : regs[A1];
  assign RD2 = (A2 == 5'd0) ? 32'h00000000 : regs[A2];

endmodule
