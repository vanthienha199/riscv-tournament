package RegisterFile;

import Vector :: *;
import RegFile :: *;

interface RegisterFile#(numeric type words, numeric type datawidth);
    method Bit#(datawidth) readA1(Bit#(TLog#(words)) addr);
    method Bit#(datawidth) readA2(Bit#(TLog#(words)) addr);
    method Action writeA3(Bit#(TLog#(words)) addr, Bit#(datawidth) data);
    `ifdef SIMULATION
    method Bit#(datawidth) registers(Bit#(TLog#(words)) index);
    `endif
endinterface

module mkRegisterFile(RegisterFile#(words, datawidth)) provisos (Log#(words, addrwidth));
    RegFile#(Bit#(addrwidth), Bit#(datawidth)) regfile <- mkRegFileLoad("zero.txt", 0, fromInteger(valueOf(words) - 1));
    //Vector#(words, Array#(Reg#(Bit#(datawidth)))) regfile <- replicateM(mkCReg(2,0));


    method Bit#(datawidth) readA1(Bit#(addrwidth) addr);
        return regfile.sub(addr);
        //return regfile[addr][1];
    endmethod
    method Bit#(datawidth) readA2(Bit#(addrwidth) addr);
        return regfile.sub(addr);
        //return regfile[addr][1];
    endmethod
    method Action writeA3(Bit#(addrwidth) addr, Bit#(datawidth) data);
        regfile.upd(addr, data);
        //regfile[addr][0] <= data;
    endmethod
    
    `ifdef SIMULATION
    method Bit#(datawidth) registers(Bit#(TLog#(words)) index);
        return regfile.sub(index);
        //return regfile[index];
    endmethod
    `endif
endmodule

endpackage