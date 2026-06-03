package TestsMainTest;
    import StmtFSM :: *;
    import TestHelper :: *;
    import Types :: *;

    import RV32I_PLH :: *;

    import Assert :: *;

    Bit#(5) a0Reg = 10;
    Bit#(5) a1Reg = 11;

    (* synthesize *)
    module [Module] mkTestsMainTest(TestHelper::TestHandler);

        RV32I_PLH dut <- mkRV32I_PLH("../files/text.txt", "../files/data.txt");


        function Action print_registers();
            //$display(dut.registers);
            return noAction;
        endfunction

        Reg#(Bool) dump_sig <- mkReg(False);
        Reg#(Bool) export_sig <- mkReg(False);
        Reg#(Bit#(32)) count <- mkReg(0);
        Reg#(Bit#(TLog#(DMEM_SIZE))) address <- mkReg(0);
    
        rule dump_signature if (dump_sig);
            if (address < fromInteger(valueOf(DMEM_SIZE))) begin
                File sig_file <- $fopen("DUT-bluespec.signature", address == 0 ? "w" : "a");
                if (!export_sig && dut.data(address) == 32'h6f5ca309)
                    export_sig <= True;
                else if (export_sig && dut.data(address) == 32'h6f5ca309) begin
                    $fwrite(sig_file, "%08x\n", dut.data(address));
                    Bit#(3) remain = truncate(count % 4);
                    remain = 4 - remain - 1;
                    for (Bit#(3) i = 0; i < remain; i = i + 1)
                        $fwrite(sig_file, "00000000\n");
                    export_sig <= False;
                end
                if (export_sig) begin
                    $fwrite(sig_file, "%08x\n", dut.data(address));
                    count <= count + 1;
                end
                $fclose(sig_file);
                address <= address + 1;
            end else begin
                $display("RISC-V arch test signature written.");
                $finish;
            end
        endrule

        Stmt s = {
            seq
                $dumpvars();
                dut.setActive(True);
                while(True) seq
                    $display("Starting...");
                    await(dut.g_ecall());
                    delay(2);
                    action
                        if (dut.registers(a0Reg) == 18) begin
                            dump_sig <= True;
                            dut.setActive(False);
                        end else if (dut.registers(a0Reg) == 0) begin
                            $display("Finish...");
                            $finish();
                        end else if (dut.registers(a0Reg) == 1) begin
                            $display("%0d", dut.registers(a1Reg));
                        end else if (dut.registers(a0Reg) == 4) begin
                            dynamicAssert(False, "NYI");
                            $finish();
                        end else if (dut.registers(a0Reg) == 10) begin
                            $display("Program ended");
                            print_registers();
                            $finish;
                        end else if (dut.registers(a0Reg) == 11) begin
                            $display("%c", dut.data(truncate(dut.registers(a1Reg)))[31:24]);
                        end else if (dut.registers(a0Reg) == 17) begin
                            $display("Program ended with return code %0d", dut.registers(a0Reg));
                            print_registers();
                            $finish;
                        end else begin
                            $display("Program ended with invalid ecall: A0=%08x A1=%08x",
                                    dut.registers(a0Reg), dut.registers(a1Reg));
                            print_registers();
                            $finish;
                        end
                    endaction
                endseq
            endseq
        };
        FSM testFSM <- mkFSM(s);



        method Action go();
            testFSM.start();
        endmethod

        method Bool done();
            return testFSM.done();
        endmethod
    endmodule

endpackage
