`include "../include/riscv_pkg.vh"

// Data memory with per-byte write enables.
//
// The read stays combinational here on purpose. The core reads it in @3 and
// consumes it in @4, so the TL-Verilog pipeline already places a register on
// the read data; synthesis merges that register into the memory read port and
// infers block RAM. Sub-word stores therefore must not read this memory
// combinationally (a read-modify-write in the same cycle would keep that
// register from merging), which is why the byte enables exist.
module data_memory_fast #(
  parameter DMEM_SIZE    = 256,
  parameter DATA_SEGMENT = "./files/data.txt"
) (
  input  wire        clk,
  input  wire [3:0]  WE,
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
  // Fast probe: use direct array assignment instead of generate loop
  assign data = dmem;
  `endif

  assign RD = dmem[A[IDX_MSB:2]];

  always @(posedge clk) begin
    if (WE[0]) dmem[A[IDX_MSB:2]][7:0]   <= WD[7:0];
    if (WE[1]) dmem[A[IDX_MSB:2]][15:8]  <= WD[15:8];
    if (WE[2]) dmem[A[IDX_MSB:2]][23:16] <= WD[23:16];
    if (WE[3]) dmem[A[IDX_MSB:2]][31:24] <= WD[31:24];
  end

endmodule
