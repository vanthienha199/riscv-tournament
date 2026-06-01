package GPIO;

import Types :: *;

import Assert :: *;
import Vector :: *;
import RegFile :: *;

interface GPIO#(numeric type addr_width);
    method ActionValue#(Bit#(32)) access(Bit#(addr_width) addr, DMemAccess sel, Maybe#(Bit#(32)) data);
    method Vector#(8, Bool) led();
    (*always_ready*)
    method Action btn();
endinterface

module mkGPIO(GPIO#(addr_width));
    RegFile#(Bit#(TSub#(addr_width, 2)), Bit#(32)) regs <- mkRegFileFullLoad("zero.txt");
    //Vector#(TExp#(TSub#(addr_width, 2)), Reg#(Bit#(32))) regs <- replicateM(mkReg(0));

    method ActionValue#(Bit#(32)) access(Bit#(addr_width) addr, DMemAccess sel, Maybe#(Bit#(32)) data);
        dynamicAssert(sel == Word, "GPIO only supports word access");
        Bit#(TSub#(addr_width, 2)) address = truncateLSB(addr);
        if (data matches tagged Valid .d) begin
            //regs[address] <= d;
            regs.upd(address, d);
        end
        return regs.sub(address);
        //return regs[address];
    endmethod

    method Vector#(8, Bool) led();
        return unpack(truncate(regs.sub(0)));
        //return unpack(truncate(regs[0]));
    endmethod

    method Action btn();

    endmethod
endmodule

endpackage