package PipelineReg;

module mkPipelineReg#(Bool stall, Bool clear)(Reg#(data)) provisos (Bits#(data, size));
    Wire#(data) newval <- mkWire;
    Reg#(data) register <- mkReg(unpack(0));

    rule clearReg if (clear);
        register <= unpack(0);
    endrule

    rule update if (!clear && !stall);
        register <= newval;
    endrule

    method Action _write(data data);
        newval <= data;
    endmethod
    method data _read();
        return register;
    endmethod
endmodule

endpackage