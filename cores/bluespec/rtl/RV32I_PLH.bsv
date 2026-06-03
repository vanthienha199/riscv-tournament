package RV32I_PLH;

// Add imports
import IMem :: *;
import RegisterFile :: *;
import MemoryRouter :: *;
import ALU :: *;
import ControlUnit :: *;
import Types :: *;
import HazardUnit  :: *;

import Vector :: *;

interface Top;
    (*always_ready*)
    method Vector#(8, Bool) led();
    (*always_ready, enable="btn"*)
    method Action btn();
endinterface

interface RV32I_PLH;
    (*always_ready*)
    method Vector#(8, Bool) led();
    (*always_ready*)
    method Action btn();
    `ifdef SIMULATION
    (*always_ready*)
    method Bit#(datawidth) registers(Bit#(TLog#(words)) index);
    method Bool g_ecall();
    (*always_ready*)
    method Bit#(32) data(Bit#(TLog#(DMEM_SIZE)) address);
    method Action start();
    `endif
endinterface

typedef struct {
    WritebackCtrl ctrl;
    Bit#(WIDTH) aluResult;
    Bit#(WIDTH) readData;
    Bit#(REGW) rd;
    Bit#(WIDTH) pcTarget;
    Bit#(WIDTH) pcPlus4;
} WritebackInfo deriving (Bits,Eq);

typedef struct {
    MemoryCtrl ctrl;
    Bit#(WIDTH) aluResult;
    Bit#(WIDTH) writeData;
    Bit#(REGW) rd;
    Bit#(WIDTH) pcTarget;
    Bit#(WIDTH) pcPlus4;
} MemoryInfo deriving (Bits, Eq);

typedef struct {
    ExecuteCtrl ctrl;
    Bit#(WIDTH) rs1Val;
    Bit#(WIDTH) rs2Val;
    Bit#(REGW) rd;
    Bit#(WIDTH) pc;
    Bit#(REGW) rs1;
    Bit#(REGW) rs2;
    Bit#(WIDTH) immExt;
    Bit#(WIDTH) pcPlus4;
} ExecuteInfo deriving (Bits, Eq);

typedef struct {
    Bit#(WIDTH) instr;
    Bit#(WIDTH) pc;
    Bit#(WIDTH) pcPlus4;
} DecodeInfo deriving (Bits, Eq);

(*no_default_reset*)
module mkTop#(parameter String imem_file, parameter String dmem_file)(Top);
    Reset usr_rst <- mkGateMateUserReset();

    (*hide*) let _core <- mkRV32I_PLH(imem_file, dmem_file, reset_by usr_rst);
    
    method Vector#(8, Bool) led();
        return map(\not , _core.led());
    endmethod
    method Action btn = _core.btn;
endmodule

module mkRV32I_PLH#(parameter String imem_file, parameter String dmem_file)(RV32I_PLH);
    Reg#(Bit#(WIDTH)) reg_PC[2] <- mkCReg(2, 0);
    Reg#(Maybe#(DecodeInfo)) reg_decode <- mkReg(tagged Invalid);
    Reg#(Maybe#(ExecuteInfo)) reg_execute[2] <- mkCReg(2, tagged Invalid);
    Reg#(Maybe#(MemoryInfo)) reg_memory <- mkReg(tagged Invalid);
    Reg#(Maybe#(WritebackInfo)) reg_writeback <- mkReg(tagged Invalid);

    IMem#(WIDTH, WIDTH) imem <- mkIMem(valueOf(IMEM_SIZE), imem_file);
    RegisterFile#(32, WIDTH) regfile <- mkRegisterFile();

    ControlUnit ctrlUnit <- mkControlUnit;

    HazardUnit hazard <- mkHazardUnit;

    `ifdef SIMULATION
    Reg#(Bool) active <- mkReg(False);
    `else
    Bool active = True;
    `endif

    rule fetch if (active && !hazard.stallD && !hazard.flushD && !hazard.stallF);
        reg_decode <= tagged Valid DecodeInfo {
            instr: imem.read(reg_PC[0]),
            pc: reg_PC[0],
            pcPlus4: reg_PC[0] + 4
        };
        reg_PC[0] <= reg_PC[0] + 4;
    endrule

    rule flushD if (hazard.flushD);
        reg_decode <= tagged Invalid;
    endrule

    function Bit#(width) duplicate(Bit#(1) i);
        return pack(replicate(i));
    endfunction

    rule flushE if (hazard.flushE);
        reg_execute[1] <= tagged Invalid;
    endrule

    rule decode if (reg_decode matches tagged Valid .info);
        Bit#(WIDTH) i = info.instr;
        Instr instr = unpack(info.instr);
        $display("%x", instr);
        $display(fshow(instr));
        let rs1 = regfile.readA1(instr.rs1);
        let rs2 = regfile.readA1(instr.rs2);
        Bit#(WIDTH) imm = 0;

        match {.ctrl,.immSrc} = ctrlUnit.handle(instr.op, instr.func3, instr.func75);
        case (immSrc)
            I: imm = signExtend(i[31:20]);
            S: imm = signExtend({i[31:25],i[11:7]});
            B: imm = {duplicate(i[31]),i[7],i[30:25],i[11:8],1'b0};
            J: imm = {duplicate(i[31]),i[19:12],i[20],i[30:21],1'b0};
            U: imm = {i[31:12],12'b0};
            IShift: imm = zeroExtend(i[24:20]);
        endcase

        reg_execute[0] <= tagged Valid ExecuteInfo {
            ctrl: ctrl,
            rs1Val: rs1,
            rs2Val: rs2,
            rd: instr.rd,
            rs1: instr.rs1,
            rs2: instr.rs2,
            pc: info.pc,
            pcPlus4: info.pcPlus4,
            immExt: imm
        };

        hazard.decode(instr.rs1, instr.rs2);
    endrule

    ALU#(WIDTH) alu <- mkALU;

    Wire#(Bit#(WIDTH)) updatePC <- mkWire;

    rule jumpOrBranch;
        reg_PC[1] <= updatePC;
        hazard.jumpOrBranch();
    endrule

    Wire#(Bit#(WIDTH)) resultW <- mkDWire(0);
    Wire#(Bit#(WIDTH)) aluResultM <- mkDWire(0);

    rule execute if (reg_execute[0] matches tagged Valid .info);

        match {.forwardA,.forwardB} <- hazard.execute(pack(info.ctrl.m.wb.resultSrc)[0] == 1, info.rd, info.rs1, info.rs2);

        // Todo
        let opA = case (forwardA)
            None: info.rs1Val;
            Writeback: resultW;
            Memory: aluResultM;
        endcase;
        let opB = case (forwardB)
            None: info.rs2Val;
            Writeback: resultW;
            Memory: aluResultM;
        endcase;
        let srcB = (info.ctrl.aluSrc) ? info.immExt : opB;

        let result = alu.exec(info.ctrl.aluControl, opA, srcB);


        let pcTarget = case(info.ctrl.pcTargetSel)
            Default: info.pc;
            Jalr: opA;
            Lui: 0;
        endcase;

        pcTarget = pcTarget + info.immExt;

        if (info.ctrl.pcSrc == Jump || (info.ctrl.pcSrc == BranchLess && result.less) || (info.ctrl.pcSrc == BranchZero && result.zero))
            updatePC <= pcTarget;

        reg_memory <= tagged Valid MemoryInfo {
            ctrl: info.ctrl.m,
            aluResult: result.result,
            writeData: opB,
            rd: info.rd,
            pcTarget: pcTarget,
            pcPlus4: info.pcPlus4
        };
    endrule

    MemoryRouter#(DMEM_SIZE) memory_router <- mkMemoryRouter(dmem_file);

    rule memory if (reg_memory matches tagged Valid .info);
        let wData = (info.ctrl.memWrite) ? tagged Valid info.writeData : tagged Invalid;

        let rData <- memory_router.access(truncate(info.aluResult), info.ctrl.wb.memSel, wData);

        reg_writeback <= tagged Valid WritebackInfo {
            ctrl: info.ctrl.wb,
            aluResult: info.aluResult,
            readData: rData,
            rd: info.rd,
            pcTarget: info.pcTarget,
            pcPlus4: info.pcPlus4
        };

        aluResultM <= info.aluResult;

        hazard.memory(info.ctrl.wb.regWrite, info.rd);
    endrule

    Wire#(Tuple2#(Bit#(REGW), Bit#(WIDTH))) writeRegfile <- mkWire;

    rule updateRegfile;
        match {.addr, .data} = writeRegfile;
        regfile.writeA3(addr, data);
    endrule

    rule writeback if (reg_writeback matches tagged Valid .info);
        let dataSgnExt = case(info.ctrl.memSel)
            Byte: signExtend(info.readData[7:0]);
            Halfword: signExtend(info.readData[15:0]);
            Word: info.readData;
        endcase;

        let result = case(info.ctrl.resultSrc)
            ALU: info.aluResult;
            Mem: ((info.ctrl.signExtEn) ? dataSgnExt : info.readData);
            PCPlus4: info.pcPlus4;
            PCTarget: info.pcTarget;
        endcase;

        resultW <= result;

        if (info.ctrl.regWrite && info.rd != 0) writeRegfile <= tuple2(info.rd, result);

        hazard.writeback(info.ctrl.regWrite, info.rd);
    endrule

    method led = memory_router.led;
    method btn = memory_router.btn;

    `ifdef SIMULATION
    method data = memory_router.data;
    method Bool g_ecall() if (reg_decode matches tagged Valid .info);
        Instr instr = unpack(info.instr);
        return instr.op == ECALL;
    endmethod
    method registers = regfile.registers;

    method Action start();
        active <= True;
    endmethod
    `endif

endmodule

interface UserReset;
    interface Reset reset_out;
endinterface

import "BVI" CC_USR_RSTN =
module vGateMateUserReset(UserReset);
    no_reset;

    default_clock no_clock;

    output_reset reset_out(USR_RSTN);
endmodule

module mkGateMateUserReset(Reset);
   (* hide *)
   UserReset _r <- vGateMateUserReset();
   return _r.reset_out;
endmodule

endpackage
