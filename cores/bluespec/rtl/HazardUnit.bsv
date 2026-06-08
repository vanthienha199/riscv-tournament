package HazardUnit;

import Types :: *;

typedef enum {
    None = 'b00,
    Writeback = 'b01,
    Memory = 'b10
} Forward deriving (Bits,Eq,FShow);

interface HazardUnit;
    method Bool stallF;
    method Bool stallD;
    method Bool flushD;
    method Bool flushE;
    method Forward forwardA;
    method Forward forwardB;
    method Action jumpOrBranch();
endinterface

module mkHazardUnit#(
    ReadOnly#(DecodeInfo) decode,
    ReadOnly#(ExecuteInfo) execute,
    ReadOnly#(MemoryInfo) memory,
    ReadOnly#(WritebackInfo) writeback
)(HazardUnit);
    PulseWire pcSrc <- mkPulseWire;
    Instr instrD = unpack(decode.instr);
    Bit#(REGW) rs1D = instrD.rs1;
    Bit#(REGW) rs2D = instrD.rs2;
    Bool resultSrcE0 = pack(execute.ctrl.m.wb.resultSrc)[0] == 1;
    Bit#(REGW) rdE = execute.rd;
    Bit#(REGW) rdM = memory.rd;
    Bit#(REGW) rdW = writeback.rd;
    Bool regWriteM = memory.ctrl.wb.regWrite;
    Bool regWriteW = writeback.ctrl.regWrite;
    
    function Forward forward(Bit#(REGW) rs);
        if (rs == rdM && regWriteM && rs != 0)
            return Memory;
        else if (rs == rdW && regWriteW && rs != 0)
            return Writeback;
        else
            return None;
    endfunction

    method Bool stallF;
        return (resultSrcE0 && (rs1D == rdE || rs2D == rdE));
    endmethod
    method Bool stallD;
        return (resultSrcE0 && (rs1D == rdE || rs2D == rdE));
    endmethod
    method Bool flushD;
        return pcSrc;
    endmethod
    method Bool flushE;
        return pcSrc || (resultSrcE0 && (rs1D == rdE || rs2D == rdE));
    endmethod

    method Forward forwardA;
        return forward(execute.rs1);
    endmethod

    method Forward forwardB;
        return forward(execute.rs2);
    endmethod

    method Action jumpOrBranch();
        pcSrc.send();
    endmethod
endmodule

endpackage