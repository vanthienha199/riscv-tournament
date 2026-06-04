package RegisterFile;

import RegFile :: *;
import Types :: *;

interface RegisterFile#(numeric type words, numeric type datawidth);
    method Bit#(datawidth) readA1(Bit#(TLog#(words)) addr);
    method Bit#(datawidth) readA2(Bit#(TLog#(words)) addr);
    method Action writeA3(Bit#(TLog#(words)) addr, Bit#(datawidth) data);
    `ifdef SIMULATION
    method Bit#(datawidth) registers(Bit#(TLog#(words)) index);
    `endif
endinterface

module mkRegisterFile(RegisterFile#(words, datawidth)) provisos (Log#(words, addrwidth));
    RegFile#(Bit#(addrwidth), Bit#(datawidth)) regfile <- mkRegFileLoad(zeroFile, 0, fromInteger(valueOf(words) - 1));
    RWire#(Tuple2#(Bit#(addrwidth), Bit#(datawidth))) forward <- mkRWire;

    rule update if (forward.wget() matches tagged Valid .tpl);
        match {.addr,.data} = tpl;
        regfile.upd(addr, data);
    endrule

    method Bit#(datawidth) readA1(Bit#(addrwidth) addr);
        if (forward.wget() matches tagged Valid .tpl &&& tpl_1(tpl) == addr)
            return tpl_2(tpl);
        else
            return regfile.sub(addr);
    endmethod
    method Bit#(datawidth) readA2(Bit#(addrwidth) addr);
        if (forward.wget() matches tagged Valid .tpl &&& tpl_1(tpl) == addr)
            return tpl_2(tpl);
        else
            return regfile.sub(addr);
    endmethod
    method Action writeA3(Bit#(addrwidth) addr, Bit#(datawidth) data);
        forward.wset(tuple2(addr, data));
    endmethod
    
    `ifdef SIMULATION
    method Bit#(datawidth) registers(Bit#(TLog#(words)) index);
        return regfile.sub(index);
    endmethod
    `endif
endmodule

endpackage