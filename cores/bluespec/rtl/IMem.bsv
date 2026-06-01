package IMem;

import RegFile :: *;

interface IMem#(numeric type addrwidth, numeric type datawidth);
    method Bit#(datawidth) read(Bit#(addrwidth) addr);
endinterface

module mkIMem#(Integer words, String init_file)(IMem#(addrwidth, datawidth)) provisos (Add#(word_addrwidth, 2, addrwidth));
    RegFile#(Bit#(word_addrwidth), Bit#(datawidth)) rom <- mkRegFileLoadHex(init_file, 0, fromInteger(words-1));

    method Bit#(datawidth) read(Bit#(addrwidth) addr);
        return rom.sub(truncateLSB(addr));
    endmethod
endmodule

endpackage