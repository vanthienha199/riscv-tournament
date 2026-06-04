package DMem;

import Types :: *;

import Assert :: *;
import Vector :: *;
import RegFile :: *;

interface DMem#(numeric type dmem_size);
    method ActionValue#(Bit#(32)) access(Bit#(32) addr, DMemAccess sel, Maybe#(Bit#(32)) data);
    `ifdef SIMULATION
    method Bit#(32) data(Bit#(TLog#(dmem_size)) address);
    `endif
endinterface

module mkDMem#(String data_file)(DMem#(dmem_size)) provisos (Add#(__a, TLog#(dmem_size), 30));
    RegFile#(Bit#(TLog#(dmem_size)), Bit#(32)) mem <- mkRegFileLoad(data_file, 0, fromInteger(valueOf(dmem_size)-1));

    method ActionValue#(Bit#(32)) access(Bit#(32) addr, DMemAccess sel, Maybe#(Bit#(32)) data);
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

        Bit#(TLog#(dmem_size)) address = truncate(addr[31:2]);
        Vector#(4, Bit#(8)) value = unpack(mem.sub(address));
        //Vector#(4, Bit#(8)) value = unpack(mem[address]);
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
        if (data matches tagged Valid .d) begin
            mem.upd(address, pack(value));
        end

        return pack(ret);
    endmethod
    
    `ifdef SIMULATION
    method Bit#(32) data(Bit#(TLog#(dmem_size)) index);
        return mem.sub(index);
    endmethod
    `endif
endmodule

endpackage