`include "../include/riscv_pkg.vh"

module data_memory #(
  parameter DMEM_SIZE    = 256,
  parameter DATA_SEGMENT = "./files/data.txt"
) (
  input  wire        clk,
  input  wire        WE,
  input  wire [31:0] A,
  input  wire [31:0] WD,
  output wire [31:0] RD
  `ifdef SIMULATION
  ,
  output wire [31:0] data [0:DMEM_SIZE-1]
  `endif
);

  localparam integer IDX_MSB = $clog2(DMEM_SIZE) + 2;

  reg [31:0] dmem [0:DMEM_SIZE-1];

  initial begin
`ifndef SYNTHESIS
    integer file;
    integer i;
    reg [31:0] address;
    reg [31:0] value;
    for (i = 0; i < DMEM_SIZE; i = i + 1)
      dmem[i] = 32'b0;
    file = $fopen(DATA_SEGMENT, "r");
    if (file != 0) begin
      while (!$feof(file)) begin
        if ($fscanf(file, "%h %h", address, value) == 2)
          dmem[address[IDX_MSB:2]] = value;
      end
      $fclose(file);
    end
`endif
  end

  `ifdef SIMULATION
  genvar gi;
  generate
    for (gi = 0; gi < DMEM_SIZE; gi = gi + 1) begin : gen_dmem_probe
      assign data[gi] = dmem[gi];
    end
  endgenerate
  `endif

  assign RD = dmem[A[IDX_MSB:2]];

  always @(posedge clk) begin
    if (WE)
      dmem[A[IDX_MSB:2]] <= WD;
  end

endmodule
