package MemoryRouter;

import DMem :: *;
import GPIO :: *;
import Types :: *;

import Vector :: *;

interface MemoryRouter#(numeric type dmem_size);
    method ActionValue#(Bit#(32)) access(Bit#(32) addr, DMemAccess sel, Maybe#(Bit#(32)) data);
    method Vector#(8, Bool) led();
    (*always_ready*)
    method Action btn();
    `ifdef SIMULATION
    method Bit#(32) data(Bit#(TLog#(dmem_size)) address);
    `endif
endinterface

module mkMemoryRouter#(String dmem_file)(MemoryRouter#(dmem_size)) provisos (Add#(__a, TLog#(dmem_size), 30));
    DMem#(dmem_size) dmem <- mkDMem(dmem_file);
    GPIO#(8) gpio <- mkGPIO();

    method ActionValue#(Bit#(32)) access(Bit#(32) addr, DMemAccess sel, Maybe#(Bit#(32)) data);
        if (addr[31:28] == 4'h1) begin
            let ret <- dmem.access(addr, sel, data);
            return ret;
        end else if (addr[31:28] == 4'h2) begin
            let ret <- gpio.access(truncate(addr), sel, data);
            return ret;
        end else begin
            return 0;
        end
    endmethod

    method led = gpio.led;
    method btn = gpio.btn;

    `ifdef SIMULATION
    method data = dmem.data;
    `endif
endmodule

endpackage