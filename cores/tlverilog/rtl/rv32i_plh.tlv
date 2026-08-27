\TLV_version 1d: tl-x.org
\SV
   // RV32I core using TL-Verilog with \SV_plus memory instantiations
   
   `include "../include/riscv_pkg.vh"
   
   module rv32i_plh #(
     parameter IMEM_SIZE    = 256,
     parameter DMEM_SIZE    = 256,
     parameter TEXT_SEGMENT = "./files/text.txt",
     parameter DATA_SEGMENT = "./files/data.txt"
   ) (
     input  wire clk,
     input  wire btn,
     output wire led1,
     output wire led2,
     output wire led3,
     output wire led4,
     output wire led5,
     output wire led6,
     output wire led7,
     output wire led8
     `ifdef SIMULATION
     ,
     output wire [31:0] registers [0:`REGS_SIZE-1],
     output wire [31:0] data [0:DMEM_SIZE-1],
     output wire        g_ecall
     `endif
   );
   
   // Startup indicator for first cycle (replaces reset)
   reg startup = 1'b1;
   always @(posedge clk) startup <= 1'b0;
   
   // Reset signal for --reset0 flag  
   wire reset = startup;
   
\TLV
   
   // ==========================================
   // MYTH-Style Pipeline Architecture
   // ==========================================
   // @0: PC calculation
   // @1: IMem Fetch (address + data, combinational)
   // @2: Decode
   // @3: Register Read (address + data, combinational) + Execute
   // @4: Memory Access (address + data, combinational) + Writeback
   //
   // Key MYTH Features:
   // - Extra IMem stage (@1)
   // - Single-stage bypass (>>1 only)
   // - $valid invalidation (not PC replay)
   // - Delayed load writeback
   //
   // Array Module Timing:
   // - instruction_memory_fast: combinational read (RD=imem[A])
   // - data_memory_fast: combinational read, registered write
   // - register_file: combinational read (inverted clock), registered write
   // Therefore address and data in same stage is correct.
   // ==========================================
   
   |cpu
      
      // ==========================================
      // Stage 0: PC Calculation
      // ==========================================
      @0
         // MYTH PC Logic with startup handling
         // Startup keeps PC at 0 for first instruction
         // One shared incrementer serves both redirect-replay (load) and
         // sequential fetch; the mux selects its operand, so only a single
         // 32-bit adder is synthesized here.
         $pc_plus4_src[31:0] = >>3$valid_load ? >>3$pc : >>1$pc;
         $pc_plus4[31:0] = $pc_plus4_src + 32'd4;
         $pc[31:0] = *startup ? 32'b0 :
                     >>3$valid_taken_br ? >>3$br_tgt_pc :
                     >>3$valid_load ? $pc_plus4 :
                     (>>3$valid_jump && >>3$is_jalr) ? >>3$jump_tgt_pc :
                     $pc_plus4;
      
      // ==========================================
      // Stage 1: IMem Fetch
      // ==========================================
      @1
         // Instantiate instruction memory (combinational, use $$ in same stage)
         \SV_plus
            instruction_memory_fast #(
              .IMEM_SIZE(IMEM_SIZE),
              .TEXT_SEGMENT(TEXT_SEGMENT)
            ) imem (
              .A($pc),
              .RD($$imem_rdata[31:0])
            );
         
         // Read instruction immediately (combinational)
         $instr[31:0] = $imem_rdata;
      
      // ==========================================
      // Stage 2: Decode
      // ==========================================
      @2
         // Instruction fields
         $opcode[6:0] = $instr[6:0];
         $funct3[2:0] = $instr[14:12];
         $funct7[6:0] = $instr[31:25];
         $rd[4:0] = $instr[11:7];
         $rs1[4:0] = $instr[19:15];
         $rs2[4:0] = $instr[24:20];
         
         // Immediate decode
         $imm_i[31:0] = {{20{$instr[31]}}, $instr[31:20]};
         $imm_s[31:0] = {{20{$instr[31]}}, $instr[31:25], $instr[11:7]};
         $imm_b[31:0] = {{19{$instr[31]}}, $instr[31], $instr[7], $instr[30:25], $instr[11:8], 1'b0};
         $imm_u[31:0] = {$instr[31:12], 12'b0};
         $imm_j[31:0] = {{11{$instr[31]}}, $instr[31], $instr[19:12], $instr[20], $instr[30:21], 1'b0};
         
         // Instruction type decode
         $is_r_type = ($opcode == 7'b0110011);
         $is_i_type = ($opcode == 7'b0010011) || ($opcode == 7'b0000011) || ($opcode == 7'b1100111);
         $is_s_type = ($opcode == 7'b0100011);
         $is_b_type = ($opcode == 7'b1100011);
         $is_u_type = ($opcode == 7'b0110111) || ($opcode == 7'b0010111);
         $is_j_type = ($opcode == 7'b1101111);
         
         // Immediate selection
         $imm[31:0] = $is_i_type ? $imm_i :
                      $is_s_type ? $imm_s :
                      $is_b_type ? $imm_b :
                      $is_u_type ? $imm_u :
                      $is_j_type ? $imm_j : 32'b0;
         
         // R-type instructions
         $is_add  = $is_r_type && ($funct3 == 3'b000) && ($funct7 == 7'b0000000);
         $is_sub  = $is_r_type && ($funct3 == 3'b000) && ($funct7 == 7'b0100000);
         $is_sll  = $is_r_type && ($funct3 == 3'b001) && ($funct7 == 7'b0000000);
         $is_slt  = $is_r_type && ($funct3 == 3'b010) && ($funct7 == 7'b0000000);
         $is_sltu = $is_r_type && ($funct3 == 3'b011) && ($funct7 == 7'b0000000);
         $is_xor  = $is_r_type && ($funct3 == 3'b100) && ($funct7 == 7'b0000000);
         $is_srl  = $is_r_type && ($funct3 == 3'b101) && ($funct7 == 7'b0000000);
         $is_sra  = $is_r_type && ($funct3 == 3'b101) && ($funct7 == 7'b0100000);
         $is_or   = $is_r_type && ($funct3 == 3'b110) && ($funct7 == 7'b0000000);
         $is_and  = $is_r_type && ($funct3 == 3'b111) && ($funct7 == 7'b0000000);
         
         // I-type ALU
         $is_addi  = ($opcode == 7'b0010011) && ($funct3 == 3'b000);
         $is_slti  = ($opcode == 7'b0010011) && ($funct3 == 3'b010);
         $is_sltiu = ($opcode == 7'b0010011) && ($funct3 == 3'b011);
         $is_xori  = ($opcode == 7'b0010011) && ($funct3 == 3'b100);
         $is_ori   = ($opcode == 7'b0010011) && ($funct3 == 3'b110);
         $is_andi  = ($opcode == 7'b0010011) && ($funct3 == 3'b111);
         $is_slli  = ($opcode == 7'b0010011) && ($funct3 == 3'b001) && ($funct7 == 7'b0000000);
         $is_srli  = ($opcode == 7'b0010011) && ($funct3 == 3'b101) && ($funct7 == 7'b0000000);
         $is_srai  = ($opcode == 7'b0010011) && ($funct3 == 3'b101) && ($funct7 == 7'b0100000);
         
         // U-type
         $is_lui   = ($opcode == 7'b0110111);
         $is_auipc = ($opcode == 7'b0010111);
         
         // Jumps
         $is_jal   = ($opcode == 7'b1101111);
         $is_jalr  = ($opcode == 7'b1100111) && ($funct3 == 3'b000);
         
         // Branches
         $is_beq  = ($opcode == 7'b1100011) && ($funct3 == 3'b000);
         $is_bne  = ($opcode == 7'b1100011) && ($funct3 == 3'b001);
         $is_blt  = ($opcode == 7'b1100011) && ($funct3 == 3'b100);
         $is_bge  = ($opcode == 7'b1100011) && ($funct3 == 3'b101);
         $is_bltu = ($opcode == 7'b1100011) && ($funct3 == 3'b110);
         $is_bgeu = ($opcode == 7'b1100011) && ($funct3 == 3'b111);
         
         // Memory
         $is_load  = ($opcode == 7'b0000011);
         $is_store = ($opcode == 7'b0100011);
         
         // Load types (funct3)
         $is_lb  = $is_load && ($funct3 == 3'b000);
         $is_lh  = $is_load && ($funct3 == 3'b001);
         $is_lw  = $is_load && ($funct3 == 3'b010);
         $is_lbu = $is_load && ($funct3 == 3'b100);
         $is_lhu = $is_load && ($funct3 == 3'b101);
         
         // Store types (funct3)
         $is_sb = $is_store && ($funct3 == 3'b000);
         $is_sh = $is_store && ($funct3 == 3'b001);
         $is_sw = $is_store && ($funct3 == 3'b010);
         
         // FENCE (treated as NOP for single-core)
         $is_fence = ($opcode == 7'b0001111);
         
         // ECALL
         $is_ecall = ($opcode == 7'b1110011) && ($funct3 == 3'b000) && ($imm_i == 32'h0);
         
      // ==========================================
      // Stage 3: Register Read + Execute
      // ==========================================
      @3
         // Register file. Ports name pipesignals directly: reads are this
         // instruction's, in-stage; the write ports belong to the instruction
         // currently in @4, hence one extra level of >>n alignment relative to
         // the @4 expressions they replace. Posedge write; half-cycle
         // visibility of the old ~clk write is covered by the >>2 bypass term.
         \SV_plus
            register_file regfile (
              .clk(*clk),
              .A1($rs1),
              .A2($rs2),
              .A3(>>3$valid_load ? >>3$rd : >>1$rd),
              .WE3(>>1$rf_wr_en),
              .WD3(>>1$result),
              .RD1($$rd1_raw[31:0]),
              .RD2($$rd2_raw[31:0])
              `ifdef SIMULATION
              ,
              .registers(*registers)
              `endif
            );
         // Bypass: >>1 previous instr, >>2 covers the posedge RF write latency.
         $src1_value[31:0] =
            ((>>1$rd == $rs1) && >>1$rf_wr_en && ($rs1 != 5'b0)) ? >>1$result :
            ((>>2$rd == $rs1) && >>2$rf_wr_en && ($rs1 != 5'b0)) ? >>2$result :
                                                                   $rd1_raw;
         $src2_value[31:0] =
            ((>>1$rd == $rs2) && >>1$rf_wr_en && ($rs2 != 5'b0)) ? >>1$result :
            ((>>2$rd == $rs2) && >>2$rf_wr_en && ($rs2 != 5'b0)) ? >>2$result :
                                                                   $rd2_raw;
         
         // ALU operations
         $sltu_result = ($src1_value < $src2_value);
         $sltiu_result = ($src1_value < $imm);
         
         $sra_result[31:0] = \$signed($src1_value) >>> $src2_value[4:0];
         $srai_result[31:0] = \$signed($src1_value) >>> $imm[4:0];
         
         // One shared adder serves ADD, ADDI, and the load/store address
         // (matching the Verilog core's main ALU). The operand mux selects
         // rs2 only for ADD; every other user wants the immediate.
         $alu_op2[31:0] = $is_add ? $src2_value : $imm;
         $src1_plus_op2[31:0] = $src1_value + $alu_op2;

         $alu_result[31:0] =
            $is_add   ? $src1_plus_op2 :
            $is_sub   ? ($src1_value - $src2_value) :
            $is_sll   ? ($src1_value << $src2_value[4:0]) :
            $is_slt   ? {{31{1'b0}}, \$signed($src1_value) < \$signed($src2_value)} :
            $is_sltu  ? {{31{1'b0}}, $sltu_result} :
            $is_xor   ? ($src1_value ^ $src2_value) :
            $is_srl   ? ($src1_value >> $src2_value[4:0]) :
            $is_sra   ? $sra_result :
            $is_or    ? ($src1_value | $src2_value) :
            $is_and   ? ($src1_value & $src2_value) :
            $is_addi  ? $src1_plus_op2 :
            $is_slti  ? {{31{1'b0}}, \$signed($src1_value) < \$signed($imm)} :
            $is_sltiu ? {{31{1'b0}}, $sltiu_result} :
            $is_xori  ? ($src1_value ^ $imm) :
            $is_ori   ? ($src1_value | $imm) :
            $is_andi  ? ($src1_value & $imm) :
            $is_slli  ? ($src1_value << $imm[4:0]) :
            $is_srli  ? ($src1_value >> $imm[4:0]) :
            $is_srai  ? $srai_result : 32'b0;
         
         // Branch/jump targets and decisions.
         // One target adder serves branches, JAL, and JALR: the operand mux
         // picks rs1 for JALR and the PC for everything else. Awkwardness:
         // for a JALR instruction $br_tgt_pc therefore holds rs1+imm, not
         // pc+imm, but no path consumes $br_tgt_pc for JALR (the redirect
         // in @0 uses $jump_tgt_pc for JALR and $br_tgt_pc only for
         // branches and JAL, which are mutually exclusive with JALR).
         $tgt_op1[31:0] = $is_jalr ? $src1_value : $pc;
         $br_tgt_pc[31:0] = $tgt_op1 + $imm;
         $jump_tgt_pc[31:0] = $is_jalr ? ($br_tgt_pc & ~32'h1) : $br_tgt_pc;
         
         $taken_br = $is_beq  ? ($src1_value == $src2_value) :
                     $is_bne  ? ($src1_value != $src2_value) :
                     $is_blt  ? (\$signed($src1_value) < \$signed($src2_value)) :
                     $is_bge  ? (\$signed($src1_value) >= \$signed($src2_value)) :
                     $is_bltu ? ($src1_value < $src2_value) :
                     $is_bgeu ? ($src1_value >= $src2_value) : 1'b0;
         
         // MYTH: $valid invalidation logic (squashes dependent instructions)
         // Don't execute if previous cycles had taken branches, loads, or jumps
         $valid = !(>>1$valid_taken_br || >>2$valid_taken_br ||
                    >>1$valid_load || >>2$valid_load ||
                    >>1$valid_jump || >>2$valid_jump);
         
         // Branch taken includes unconditional JAL
         $valid_taken_br = $valid && (($is_b_type && $taken_br) || $is_jal);
         $valid_load = $valid && $is_load;
         $valid_jump = $valid && $is_jalr;
         
         // Memory address comes from the shared ALU adder. For non-memory
         // instructions this carries whatever the adder computed (e.g.
         // rs1+rs2 for ADD); that is fine because every consumer of
         // $mem_addr is gated by $is_load/$is_store.
         $mem_addr[31:0] = $src1_plus_op2;
         $byte_offset[1:0] = $mem_addr[1:0];
         
         // MMIO routing and control signals
         $dmem_store = $is_store && $valid;
         $sel_dmem = ($mem_addr[31:28] == 4'h1);
         $sel_gpio = ($mem_addr[31:28] == 4'h2);
         $dmem_we = $dmem_store && $sel_dmem;
         $gpio_we = $dmem_store && $sel_gpio;
         
         // Instantiate data memory and GPIO  
         \SV_plus
            data_memory_fast #(
              .DMEM_SIZE(DMEM_SIZE),
              .DATA_SEGMENT(DATA_SEGMENT)
            ) dmem (
              .clk(*clk),
              .A(($is_store || $is_load) ? $mem_addr : 32'b0),
              .WD($dmem_wr_data),
              .WE($dmem_we),
              .RD($$dmem_rdata[31:0])
              `ifdef SIMULATION
              ,
              .data(*data)
              `endif
            );
            
            gpio_mem gpio (
              .clk(*clk),
              .A($mem_addr[`IOMEM_LEN-1:0]),
              .WD($src2_value),
              .WE($gpio_we),
              .RD($$gpio_rdata[31:0]),
              .btn(*btn),
              .led1(*led1),
              .led2(*led2),
              .led3(*led3),
              .led4(*led4),
              .led5(*led5),
              .led6(*led6),
              .led7(*led7),
              .led8(*led8)
            );
         
         // Capture memory read data immediately (outputs from \SV_plus modules)
         $dmem_rdata_stg[31:0] = $dmem_rdata;
         $gpio_rdata_stg[31:0] = $gpio_rdata;
         
         // WD_UNIT: Write data merge for sub-word stores (matches Verilog wd_unit.v)
         // Memory has combinational read, so captured rdata is current memory contents
         // Merge new store data with existing memory based on funct3 and byte offset
         $dmem_wr_data[31:0] = 
            $is_sb ? (
               ($byte_offset == 2'b00) ? {$dmem_rdata_stg[31:8],   $src2_value[7:0]} :
               ($byte_offset == 2'b01) ? {$dmem_rdata_stg[31:16],  $src2_value[7:0], $dmem_rdata_stg[7:0]} :
               ($byte_offset == 2'b10) ? {$dmem_rdata_stg[31:24],  $src2_value[7:0], $dmem_rdata_stg[15:0]} :
                                         {                         $src2_value[7:0], $dmem_rdata_stg[23:0]}
            ) :
            $is_sh ? (
               ($byte_offset[1] == 1'b0) ? {$dmem_rdata_stg[31:16], $src2_value[15:0]} :
                                           {                        $src2_value[15:0], $dmem_rdata_stg[15:0]}
            ) :
            $src2_value;  // SW or default
      
      // ==========================================
      // Stage 4: Writeback
      // ==========================================
      @4
         // RD_UNIT: Extract load data from memory (matches Verilog rd_unit.v)
         // Memory read data from @3 (same cycle, previous stage)
         $mem_rdata_raw[31:0] = $sel_dmem ? $dmem_rdata_stg :
                                $sel_gpio ? $gpio_rdata_stg : 32'b0;
         
         // Sub-word load data extraction based on byte offset and size
         $byte_data[7:0] = ($byte_offset == 2'b00) ? $mem_rdata_raw[7:0]   :
                           ($byte_offset == 2'b01) ? $mem_rdata_raw[15:8]  :
                           ($byte_offset == 2'b10) ? $mem_rdata_raw[23:16] :
                                                     $mem_rdata_raw[31:24];
         
         $half_data[15:0] = ($byte_offset[1] == 1'b0) ? $mem_rdata_raw[15:0] :
                                                         $mem_rdata_raw[31:16];
         
         // Load data with proper sign/zero extension
         $ld_data[31:0] = $is_lw  ? $mem_rdata_raw :
                          $is_lh  ? {{16{$half_data[15]}}, $half_data} :
                          $is_lhu ? {16'b0, $half_data} :
                          $is_lb  ? {{24{$byte_data[7]}}, $byte_data} :
                          $is_lbu ? {24'b0, $byte_data} : 32'b0;
         
         // Result selection.
         // One late-stage adder serves both AUIPC (pc+imm) and the JAL/JALR
         // link value (pc+4); the operand mux picks between them. Both $pc
         // and $imm are already staged to @4 for other users, so this costs
         // no extra pipeline flops.
         $late_op2[31:0] = $is_auipc ? $imm : 32'd4;
         $pc_plus_late[31:0] = $pc + $late_op2;

         $result[31:0] = $is_lui   ? $imm :
                         $is_auipc ? $pc_plus_late :
                         $is_jal   ? $pc_plus_late :
                         $is_jalr  ? $pc_plus_late :
                         >>2$valid_load ? >>2$ld_data :
                         $alu_result;
         
         // Register writeback (connects to global register file)
         // Note: FENCE doesn't write to registers
         $rf_wr_en = (($rd != 5'b0) && $valid &&
                      ($is_r_type || $is_i_type || $is_u_type || $is_j_type) &&
                      !$is_load && !$is_fence) ||
                     >>2$valid_load;

         // Pipeline ecall signal to @4 to sync with register writeback
         // This ensures register values are updated before testbench samples them
         $ecall_signal = >>2$is_ecall && >>2$valid;
         
\SV
   `ifdef SIMULATION
      assign g_ecall = CPU_ecall_signal_a4;
   `endif
   
   endmodule

