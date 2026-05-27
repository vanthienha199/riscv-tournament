`include "../include/riscv_pkg.vh"

module memory_router #(
  parameter DMEM_SIZE    = 256,
  parameter DATA_SEGMENT = "./files/data.txt"
) (
  input  wire        clk,
  input  wire        WE,
  input  wire [31:0] A,
  input  wire [31:0] WD,
  input  wire        btn,
  output wire [31:0] RD,
  output wire        led1,
  output wire        led2,
  output wire        led3,
  output wire        led4,
  output wire        led5,
  output wire        led6,
  output wire        led7,
  output wire        led8
  `ifdef SIMULATION
  ,
  output wire [31:0] data [0:DMEM_SIZE-1]
  `endif
);

  wire        sel_dmem = (A[31:28] == 4'h1);
  wire        sel_gpio = (A[31:28] == 4'h2);
  wire        dmem_we  = WE && sel_dmem;
  wire        gpio_we  = WE && sel_gpio;
  wire [31:0] dmem_rd;
  wire [31:0] gpio_rd;

  data_memory #(
    .DMEM_SIZE(DMEM_SIZE),
    .DATA_SEGMENT(DATA_SEGMENT)
  ) dmem (
    .clk (clk),
    .WE  (dmem_we),
    .A   (A),
    .WD  (WD),
    .RD  (dmem_rd)
    `ifdef SIMULATION
    ,
    .data(data)
    `endif
  );

  gpio_mem gpio (
    .clk  (clk),
    .WE   (gpio_we),
    .A    (A[`IOMEM_LEN-1:0]),
    .WD   (WD),
    .btn  (btn),
    .RD   (gpio_rd),
    .led1 (led1),
    .led2 (led2),
    .led3 (led3),
    .led4 (led4),
    .led5 (led5),
    .led6 (led6),
    .led7 (led7),
    .led8 (led8)
  );

  assign RD = sel_dmem ? dmem_rd :
              sel_gpio ? gpio_rd : 32'b0;

endmodule
