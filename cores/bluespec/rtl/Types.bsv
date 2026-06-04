package Types;

import Reserved :: *;

typedef `DMEM_SIZE DMEM_SIZE;
typedef `IMEM_SIZE IMEM_SIZE;

typedef 32 WIDTH;
typedef 32 NumRegisters;
typedef TLog#(NumRegisters) REGW;

typedef struct {
    Reserved#(1) u2;
    Bit#(1) func75;
    Reserved#(5) u1;
    Bit#(5) rs2;
    Bit#(5) rs1;
    Bit#(3) func3;
    Bit#(5) rd;
    Opcode op;
} Instr deriving (Bits,Eq,FShow);

typedef enum {
    Load = 7'b0000011,
    Store = 7'b0100011,
    RType = 7'b0110011,
    BType = 7'b1100011,
    IType = 7'b0010011,
    JType = 7'b1101111,
    JALR = 7'b1100111,
    LUI = 7'b0110111,
    AUIPC = 7'b0010111,
    ECALL = 7'b1110011
} Opcode deriving (Bits,Eq,FShow);

typedef enum {
    None = 'b00,
    BranchZero = 'b10,
    BranchLess = 'b01,
    Jump = 'b11,
    BranchNonZero = 'b100,
    BranchGreaterEqual = 'b101
} PCSrc deriving (Bits,Eq,FShow);

typedef enum {
    Byte = 'b0,
    Halfword = 'b1,
    Word = 'b10
} DMemAccess deriving (Bits,Eq,FShow);

typedef enum {
    Default = 'b00,
    Jalr = 'b01,
    Lui = 'b10
} PCTargetSel deriving (Bits,Eq,FShow);

typedef enum {
    I = 'b000,
    S = 'b001,
    B = 'b010,
    J = 'b011,
    U = 'b100,
    IShift = 'b101
} ImmSrc deriving (Bits,Eq,FShow);

typedef enum {
    ALU = 'b00,
    Mem = 'b01,
    PCPlus4 = 'b10,
    PCTarget = 'b11
} ResultSrc deriving (Bits,Eq,FShow);


typedef enum {
    Add = 0000,
    Sub = 0001,
    LShift = 0010,
    LT = 0101,
    LTU = 0111,
    XOR = 1000,
    RShift = 1010,
    RShiftA = 1011,
    OR = 1100,
    AND = 1110
} AluOP deriving (Bits, Eq,FShow);



typedef struct {
    Bool regWrite;
    ResultSrc resultSrc;
    Bool signExtEn;
    DMemAccess memSel;
} WritebackCtrl deriving (Bits,Eq,FShow);

typedef struct {
    WritebackCtrl wb;
    Bool memWrite;
} MemoryCtrl deriving (Bits, Eq,FShow);

typedef struct {
    MemoryCtrl m;
    AluOP aluControl;
    PCTargetSel pcTargetSel;
    Bool aluSrc;
    PCSrc pcSrc;
} ExecuteCtrl deriving (Bits,Eq,FShow);

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
} MemoryInfo deriving (Bits, Eq,FShow);

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

endpackage