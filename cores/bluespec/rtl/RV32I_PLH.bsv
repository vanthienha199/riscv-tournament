package RV32I_PLH;

import IMem :: *;
import RegisterFile :: *;
import MemoryRouter :: *;
import ALU :: *;
import ControlUnit :: *;
import Types :: *;
import HazardUnit  :: *;
import PipelineReg :: *;

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
    method Bit#(WIDTH) registers(Bit#(TLog#(32)) index);
    method Bool g_ecall();
    (*always_ready*)
    method Bit#(32) data(Bit#(TLog#(DMEM_SIZE)) address);
    method Action setActive(Bool active);
    `endif
endinterface

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
    Wire#(Bool) stallF <- mkBypassWire;
    Wire#(Bool) stallD <- mkBypassWire;
    Wire#(Bool) flushD <- mkBypassWire;
    Wire#(Bool) flushE <- mkBypassWire;
    Reg#(Bit#(WIDTH)) reg_PC <- mkPipelineReg(stallF, False);
    Reg#(DecodeInfo) reg_decode <- mkPipelineReg(stallD, flushD);
    Reg#(ExecuteInfo) reg_execute <- mkPipelineReg(False, flushE);
    Reg#(MemoryInfo) reg_memory <- mkPipelineReg(False, False);
    Reg#(WritebackInfo) reg_writeback <- mkPipelineReg(False, False);

    IMem#(WIDTH, WIDTH) imem <- mkIMem(valueOf(IMEM_SIZE), imem_file);
    RegisterFile#(32, WIDTH) regfile <- mkRegisterFile();

    ControlUnit ctrlUnit <- mkControlUnit;

    HazardUnit hazard <- mkHazardUnit(regToReadOnly(reg_decode), regToReadOnly(reg_execute), regToReadOnly(reg_memory), regToReadOnly(reg_writeback));

    (*fire_when_enabled, no_implicit_conditions*)
    rule setWires;
        stallF <= hazard.stallF;
        stallD <= hazard.stallD;
        flushD <= hazard.flushD;
        flushE <= hazard.flushE;
    endrule

    `ifdef SIMULATION
    Reg#(Bool) activeReg[2] <- mkCReg(2, False);
    Bool active = activeReg[1];
    `else
    Bool active = True;
    `endif

    Wire#(Bit#(WIDTH)) updatePC <- mkWire;
    Wire#(Bit#(WIDTH)) newPC <- mkWire;

    rule jumpOrBranch if (active);
        reg_PC <= updatePC;
        hazard.jumpOrBranch();
    endrule
    
    (*preempts="jumpOrBranch,nextPC"*)
    rule nextPC if (active);
        reg_PC <= reg_PC + 4;
    endrule

    rule fetch if (active);
        reg_decode <= DecodeInfo {
            instr: imem.read(reg_PC),
            pc: reg_PC,
            pcPlus4: reg_PC + 4
        };
    endrule

    function Bit#(width) duplicate(Bit#(1) i);
        return pack(replicate(i));
    endfunction

    rule decode if (active);
        let info = reg_decode;
        Bit#(WIDTH) i = info.instr;
        Instr instr = unpack(info.instr);
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

        reg_execute <= ExecuteInfo {
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
    endrule

    ALU#(WIDTH) alu <- mkALU;

    Wire#(Bit#(WIDTH)) resultW <- mkDWire(0);
    Wire#(Bit#(WIDTH)) aluResultM <- mkDWire(0);

    rule execute if (active);
        let info = reg_execute;

        let opA = case (hazard.forwardA)
            None: info.rs1Val;
            Writeback: resultW;
            Memory: aluResultM;
        endcase;
        let opB = case (hazard.forwardB)
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

        reg_memory <= MemoryInfo {
            ctrl: info.ctrl.m,
            aluResult: result.result,
            writeData: opB,
            rd: info.rd,
            pcTarget: pcTarget,
            pcPlus4: info.pcPlus4
        };
    endrule

    MemoryRouter#(DMEM_SIZE) memory_router <- mkMemoryRouter(dmem_file);

    rule memory if (active);
        let info = reg_memory;
        let wData = (info.ctrl.memWrite) ? tagged Valid info.writeData : tagged Invalid;

        let rData <- memory_router.access(truncate(info.aluResult), info.ctrl.wb.memSel, wData);

        reg_writeback <= WritebackInfo {
            ctrl: info.ctrl.wb,
            aluResult: info.aluResult,
            readData: rData,
            rd: info.rd,
            pcTarget: info.pcTarget,
            pcPlus4: info.pcPlus4
        };

        aluResultM <= info.aluResult;
    endrule

    Wire#(Tuple2#(Bit#(REGW), Bit#(WIDTH))) writeRegfile <- mkWire;

    rule updateRegfile;
        match {.addr, .data} = writeRegfile;
        regfile.writeA3(addr, data);
    endrule

    rule writeback if (active);
        let info = reg_writeback;
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

    endrule

    method led = memory_router.led;
    method btn = memory_router.btn;

    `ifdef SIMULATION
    method data = memory_router.data;
    method Bool g_ecall();
        Instr instr = unpack(reg_decode.instr);
        return instr.op == ECALL;
    endmethod
    method registers = regfile.registers;

    method Action setActive(Bool a);
        activeReg[0] <= a;
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
