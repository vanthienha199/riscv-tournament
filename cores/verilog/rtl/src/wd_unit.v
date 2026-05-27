module wd_unit (
  input  wire [31:0] RD2,
  input  wire [31:0] ReadData,
  input  wire [2:0]  funct3,
  input  wire [31:0] Address,
  output reg  [31:0] DataOut
);

  always @(*) begin
    case (funct3)
      3'b000: begin
        case (Address[1:0])
          2'b00: DataOut = {ReadData[31:8],   RD2[7:0]};
          2'b01: DataOut = {ReadData[31:16],  RD2[7:0], ReadData[7:0]};
          2'b10: DataOut = {ReadData[31:24],  RD2[7:0], ReadData[15:0]};
          2'b11: DataOut = {                  RD2[7:0], ReadData[23:0]};
          default: DataOut = RD2;
        endcase
      end
      3'b001: begin
        case (Address[1])
          1'b0: DataOut = {ReadData[31:16],   RD2[15:0]};
          1'b1: DataOut = {                   RD2[15:0], ReadData[15:0]};
          default: DataOut = RD2;
        endcase
      end
      default: DataOut = RD2;
    endcase
  end

endmodule
