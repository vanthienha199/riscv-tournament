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

    method Action decode(Bit#(REGW) rs1, Bit#(REGW) rs2);
    method Action jumpOrBranch();
    method ActionValue#(Tuple2#(Forward,Forward)) execute(Bool resultSrc0, Bit#(REGW) rd, Bit#(REGW) rs1, Bit#(REGW) rs2);
    method Action memory(Bool regWrite, Bit#(REGW) rd);
    method Action writeback(Bool regWrite, Bit#(REGW) rd);
endinterface

module mkHazardUnit(HazardUnit);
    PulseWire pcSrc <- mkPulseWire;
    Wire#(Bit#(REGW)) rs1D <- mkDWire(0);
    Wire#(Bit#(REGW)) rs2D <- mkDWire(0);
    //Wire#(Bit#(REGW)) rs1E <- mkBypassWire;
    //Wire#(Bit#(REGW)) rs2E <- mkBypassWire;
    Wire#(Bit#(REGW)) rdE <- mkDWire(0);
    Wire#(Bit#(REGW)) rdM <- mkDWire(0);
    Wire#(Bit#(REGW)) rdW <- mkDWire(0);
    Wire#(Bool) resultSrcE0 <- mkDWire(False);
    Wire#(Bool) regWriteM <- mkDWire(False);
    Wire#(Bool) regWriteW <- mkDWire(False);

    
    function Forward forward(Bit#(REGW) rs);
        if (rs == rdM && regWriteM && rs != 0)
            return Memory;
        else if (rs == rdW && regWriteW && rs != 0)
            return Writeback;
        else
            return None;
    endfunction

    method Action jumpOrBranch();
        pcSrc.send();
    endmethod

    method Action decode(Bit#(REGW) rs1, Bit#(REGW) rs2);
        rs1D <= rs1;
        rs2D <= rs2;
    endmethod
    method ActionValue#(Tuple2#(Forward, Forward)) execute(Bool resultSrc0, Bit#(REGW) rd, Bit#(REGW) rs1, Bit#(REGW) rs2);
        resultSrcE0 <= resultSrc0;
        rdE <= rd;
        //rs1E <= rs1;
        //rs2E <= rs2;
        return tuple2(forward(rs1), forward(rs2));
    endmethod
    method Action memory(Bool regWrite, Bit#(REGW) rd);
        regWriteM <= regWrite;
        rdM <= rd;
    endmethod
    method Action writeback(Bool regWrite, Bit#(REGW) rd);
        regWriteW <= regWrite;
        rdW <= rd;
    endmethod

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
endmodule

endpackage