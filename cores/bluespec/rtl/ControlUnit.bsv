package ControlUnit;

import Types :: *;

interface ControlUnit;
    method Tuple2#(ExecuteCtrl, ImmSrc) handle(Opcode op, Bit#(3) func3, Bit#(1) func75);
endinterface

module mkControlUnit(ControlUnit);
    function ResultSrc decResultSrc(Opcode op);
        return case(op)
            LUI: PCTarget;
            AUIPC: PCTarget;
            JType: PCPlus4;
            JALR: PCPlus4;
            Load: Mem;
            default ALU;
        endcase;
    endfunction

    function DMemAccess decDMemAccess(Opcode op, Bit#(3) func3);
        if (op == Store || op == Load)
            return unpack(func3[1:0]);
        else
            return Byte;
    endfunction

    function PCSrc decPCSrc(Opcode op, Bit#(3) func3);
        if (op == JType || op == JALR) return Jump;
        else if (op == BType && (func3 == 'b000 || func3 == 'b101 || func3 == 'b111)) return BranchZero;
        else if (op == BType) return BranchLess;
        else return None; 
    endfunction

    function PCTargetSel decPCTargetSel(Opcode op);
        if (op == JALR) return Jalr;
        else if (op == LUI) return Lui;
        else return Default;
    endfunction

    function AluOP decAluOPIRType(Bit#(3) func3, Bit#(1) func75, Bool rType);
        case (func3)
            'b000: return ((func75 == 1 && rType) ? Sub : Add);
            'b001: return LShift;
            'b010: return LT;
            'b011: return LTU;
            'b100: return XOR;
            'b101: return ((func75 == 1) ? RShiftA : RShift);
            'b110: return OR;
            'b111: return AND;
        endcase
    endfunction

    function AluOP decAluOP(Opcode op, Bit#(3) func3, Bit#(1) func75);
        case (op)
            RType: return decAluOPIRType(func3, func75, op == RType);
            IType: return decAluOPIRType(func3, func75, op == RType);
            BType: begin
                case (func3)
                    'b000: return Sub;
                    'b001: return Sub;
                    'b100: return LT;
                    'b101: return LT;
                    'b110: return LTU;
                    'b111: return LTU;
                endcase
            end
            default return Add;
        endcase
    endfunction

    method Tuple2#(ExecuteCtrl, ImmSrc) handle(Opcode op, Bit#(3) func3, Bit#(1) func75);
        let jump = op == JType || (op == JALR && func3 == 'b000);
        let branch = op == BType;

        let wb = WritebackCtrl {
            regWrite: op != BType && op != Store,
            resultSrc: decResultSrc(op),
            signExtEn: op == Load && (func3 == 'b000 || func3 == 'b001),
            memSel: decDMemAccess(op, func3)
        };
        let m = MemoryCtrl {
            wb: wb,
            memWrite: op == Store
        };
        let e = ExecuteCtrl {
            m: m,
            aluSrc: op == IType || op == Load || op == Store,
            pcSrc: decPCSrc(op, func3),
            pcTargetSel: decPCTargetSel(op),
            aluControl: decAluOP(op, func3, func75)
        };
        let immSrc = case (op)
            Load: I;
            Store: S;
            IType: I;
            BType: B;
            IType: ((func3 == 'b001 || func3 == 'b101) ? IShift : I);
            JType: J;
            JALR: ((func3 == 'b000) ? I : I);
            LUI: U;
            AUIPC: U;
        endcase;
        return tuple2(e, immSrc);
    endmethod
endmodule

endpackage