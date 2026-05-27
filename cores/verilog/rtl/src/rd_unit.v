module rd_unit (
  input  wire [31:0] DataIn,
  input  wire [2:0]  funct3,
  input  wire [31:0] Address,
  output reg  [31:0] DataOut
);

  always @(*) begin
    case (funct3)
      3'b000: begin
        case (Address[1:0])
          2'b00: DataOut = {{24{DataIn[7]}},  DataIn[7:0]};
          2'b01: DataOut = {{24{DataIn[15]}}, DataIn[15:8]};
          2'b10: DataOut = {{24{DataIn[23]}}, DataIn[23:16]};
          2'b11: DataOut = {{24{DataIn[31]}}, DataIn[31:24]};
          default: DataOut = DataIn;
        endcase
      end
      3'b001: begin
        case (Address[1])
          1'b0: DataOut = {{16{DataIn[15]}}, DataIn[15:0]};
          1'b1: DataOut = {{16{DataIn[31]}}, DataIn[31:16]};
          default: DataOut = DataIn;
        endcase
      end
      3'b100: begin
        case (Address[1:0])
          2'b00: DataOut = {24'b0, DataIn[7:0]};
          2'b01: DataOut = {24'b0, DataIn[15:8]};
          2'b10: DataOut = {24'b0, DataIn[23:16]};
          2'b11: DataOut = {24'b0, DataIn[31:24]};
          default: DataOut = DataIn;
        endcase
      end
      3'b101: begin
        case (Address[1])
          1'b0: DataOut = {16'b0, DataIn[15:0]};
          1'b1: DataOut = {16'b0, DataIn[31:16]};
          default: DataOut = DataIn;
        endcase
      end
      default: DataOut = DataIn;
    endcase
  end

endmodule
