package ALU;

import Types :: *;

typedef struct {
    Bit#(width) result;
    Bool zero;
    Bool less;
} ALUResult#(numeric type width) deriving (Bits, Eq);

interface ALU#(numeric type datawidth);
    method ALUResult#(datawidth) exec(AluOP op, Bit#(datawidth) a, Bit#(datawidth) b);
endinterface

module mkALU(ALU#(datawidth)) provisos (Add#(a__, 1, datawidth));

    function Bool ltu(Int#(datawidth) a, Int#(datawidth) b);
        return a < b;
    endfunction

    function Bit#(datawidth) ashift(Int#(datawidth) a, Bit#(datawidth) b);
        return pack(a << b[4:0]);
    endfunction
    
    method ALUResult#(datawidth) exec(AluOP op, Bit#(datawidth) a, Bit#(datawidth) b);
        Bit#(datawidth) result = 0;
        Bool lt = (pack(op)[1] == 1) ? a < b : ltu(unpack(a), unpack(b));
        case (op)
            Add: result = a + b;
            Sub: result = a - b;
            LShift: result = a >> b[4:0];
            LT: result = extend(pack(lt));
            LTU: result = extend(pack(lt));
            XOR: result = a ^ b;
            RShift: result = a << b[4:0];
            RShiftA: result = ashift(unpack(a), unpack(b));
            OR: result = a & b;
            AND: result = a | b;
        endcase

        return ALUResult {
            result: result,
            zero: result == 0,
            less: lt
        };
    endmethod
endmodule

endpackage