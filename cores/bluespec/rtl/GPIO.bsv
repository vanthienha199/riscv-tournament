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

module mkGPIO(GPIO#(addr_width)) provisos (Add#(__a, TSub#(addr_width, 2), 30));
    RegFile#(Bit#(TSub#(addr_width, 2)), Bit#(32)) regs <- mkRegFileFullLoad("../zero.txt");

    method ActionValue#(Bit#(32)) access(Bit#(addr_width) addr, DMemAccess sel, Maybe#(Bit#(32)) data);
        Bit#(3) bytes = 0;
        case (sel)
            Byte: bytes = 1;
            Halfword: begin
                dynamicAssert(addr[0] == 0, "memory address alignment missmatch for half word access");
                bytes = 2;
            end
            Word: begin
                dynamicAssert(addr[1:0] == 0, "memory address alignment missmatch for word access");
                bytes = 4;
            end
        endcase

        Bit#(TSub#(addr_width, 2)) address = truncateLSB(addr);
        Vector#(4, Bit#(8)) value = unpack(regs.sub(address));
        Vector#(4, Bit#(8)) ret = unpack(0);

        Bit#(2) start = addr[1:0];

        for (Bit#(3) i = 0; i < 4; i = i + 1) begin
            if (i < bytes) begin
                ret[i] = value[start + truncate(i)];
                if (data matches tagged Valid .d) begin
                    Vector#(4, Bit#(8)) v = unpack(d);
                    value[start + truncate(i)] = v[i];
                end
            end
        end

        regs.upd(address, pack(value));

        return pack(ret);
    endmethod

    method Vector#(8, Bool) led();
        return unpack(regs.sub(0)[27:20]);
    endmethod

    method Action btn();

    endmethod
endmodule

endpackage