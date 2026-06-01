package TestsMainTest;
    import StmtFSM :: *;
    import TestHelper :: *;
    import Types :: *;

    import RV32I_PLH :: *;

    import Assert :: *;

    Integer a0Reg = 10;
    Integer a1Reg = 11;

    (* synthesize *)
    module [Module] mkTestsMainTest(TestHelper::TestHandler);

        RV32I_PLH dut <- mkRV32I_PLH("../files/text.txt", "../files/data.txt");


        function Action print_registers();
            $display(dut.registers);
        endfunction

        Reg#(Bool) export_sig <- mkReg(False);
        Reg#(Bit#(32)) count <- mkReg(0);
        Reg#(Bit#(TLog#(DMEM_SIZE))) address <- mkReg(0);
    

        Stmt s = {
            seq
                $dumpvars();
                dut.start();
                while(True) seq
                    await(dut.g_ecall());
                    $display("ECALL...");
                    if (dut.registers[a0Reg] == 18) seq
                        for (address <= 0; address < fromInteger(valueOf(DMEM_SIZE)); address <= address + 1) action
                            File sig_file <- $fopen("DUT-verilog.signature", address == 0 ? "w" : "a");
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
                        endaction
                        $display("RISC-V arch test signature written.");
                        $finish;
                    endseq else if (dut.registers[a0Reg] == 0) seq
                        $finish();
                    endseq else if (dut.registers[a0Reg] == 1) seq
                        $display("%0d", dut.registers[a1Reg]);
                    endseq else if (dut.registers[a0Reg] == 4) seq
                        dynamicAssert(False, "NYI");
                    endseq else if (dut.registers[a0Reg] == 10) seq
                        $display("Program ended");
                        print_registers();
                        $finish;
                    endseq else if (dut.registers[a0Reg] == 11) seq
                        $display("%c", dut.data(truncate(dut.registers[a1Reg]))[31:24]);
                    endseq else if (dut.registers[a0Reg] == 17) seq
                        $display("Program ended with return code %0d", dut.registers[a0Reg]);
                        print_registers();
                        $finish;
                    endseq else seq
                        $display("Program ended with invalid ecall: A0=%08x A1=%08x",
                                dut.registers[a0Reg], dut.registers[a1Reg]);
                        print_registers();
                        $finish;
                    endseq
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
