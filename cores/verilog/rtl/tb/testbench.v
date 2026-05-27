`timescale 1ns / 1ps
`include "../include/riscv_pkg.vh"

module testbench;

  parameter IMEM_SIZE = 8192;
  parameter DMEM_SIZE = 65540;
  parameter SIM_TIMEOUT = 0;

  reg clk = 0;
  reg btn = 0;
  wire led1, led2, led3, led4, led5, led6, led7, led8;
  wire [31:0] registers [0:31];
  wire [31:0] data [0:DMEM_SIZE-1];
  wire g_ecall;

  rv32i_plh #(
    .IMEM_SIZE(IMEM_SIZE),
    .DMEM_SIZE(DMEM_SIZE)
  ) dut (
    .clk(clk),
    .btn(btn),
    .led1(led1),
    .led2(led2),
    .led3(led3),
    .led4(led4),
    .led5(led5),
    .led6(led6),
    .led7(led7),
    .led8(led8),
    .registers(registers),
    .data(data),
    .g_ecall(g_ecall)
  );

  always #5 clk = ~clk;

  integer sig_file;
  integer export_sig;
  integer count;
  integer remain;
  integer address;
  integer string_index;
  integer i;
  integer j;
  reg [7:0] byte_value;
  reg string_end;
  reg [8*128-1:0] output_string;

  always @(negedge g_ecall) begin
    if (registers[`A0_REG] == 32'd18) begin
      export_sig = 0;
      count = 0;
      sig_file = $fopen("DUT-verilog.signature", "w");
      for (address = 0; address < DMEM_SIZE; address = address + 1) begin
        if (!export_sig && data[address] == 32'h6f5ca309)
          export_sig = 1;
        else if (export_sig && data[address] == 32'h6f5ca309) begin
          $fwrite(sig_file, "%08x\n", data[address]);
          remain = count % 4;
          remain = 4 - remain - 1;
          for (i = 0; i < remain; i = i + 1)
            $fwrite(sig_file, "00000000\n");
          export_sig = 0;
        end
        if (export_sig) begin
          $fwrite(sig_file, "%08x\n", data[address]);
          count = count + 1;
        end
      end
      $fclose(sig_file);
      $display("RISC-V arch test signature written.");
      $finish;
    end

    $write("RISC-V Terminal:> ");
    case (registers[`A0_REG])
      32'd0: ;
      32'd1: $display("%0d", registers[`A1_REG]);
      32'd4: begin
        string_end = 0;
        string_index = 0;
        output_string = {128{8'h20}};
        for (i = registers[`A1_REG][27:2]; i < DMEM_SIZE; i = i + 1) begin
          for (j = 0; j < 4; j = j + 1) begin
            if (!string_end) begin
              byte_value = data[i][j*8 +: 8];
              output_string[string_index*8 +: 8] = byte_value;
              string_index = string_index + 1;
              if (byte_value == 8'h00) begin
                string_end = 1;
                $display("%s", output_string);
              end
            end
          end
        end
      end
      32'd10: begin
        $display("Program ended");
        print_registers();
        $finish;
      end
      32'd11: $display("%c", data[registers[`A1_REG]][31:24]);
      32'd17: begin
        $display("Program ended with return code %0d", registers[`A1_REG]);
        print_registers();
        $finish;
      end
      default: begin
        $display("Program ended with invalid ecall: A0=%08x A1=%08x",
                 registers[`A0_REG], registers[`A1_REG]);
        print_registers();
        $finish;
      end
    endcase
  end

  generate
    if (SIM_TIMEOUT > 0) begin : gen_timeout
      initial begin
        #SIM_TIMEOUT;
        $display("Simulation timeout");
        $finish;
      end
    end
  endgenerate

  task print_registers;
    integer r;
    begin
      $display("   Registers");
      $display("   =========");
      for (r = 0; r < 32; r = r + 1)
        $display("      x%0d = 0x%08x", r, registers[r]);
    end
  endtask

endmodule
