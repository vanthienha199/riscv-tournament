RED     = $(shell printf "\033[31m")
GREEN   = $(shell printf "\033[32m")
YELLOW  = $(shell printf "\033[33m")
RESET   = $(shell printf "\033[0m")

PROGRAM ?=
_require_program = program sim all prep_synth synth bitstream
ifneq ($(filter $(_require_program),$(MAKECMDGOALS)),)
ifeq ($(PROGRAM),)
$(error $(RED)Usage: make PROGRAM=<program.s|program.c> [target]$(RESET))
endif
endif

include ../../framework/make/toolchain_check.mk

TEXT_SEGMENT_START      = 0x00000000
TEXT_SEGMENT_SIM_SIZE   = 8192
TEXT_SEGMENT_SYNTH_SIZE = 1024
DATA_SEGMENT_START      = 0x10000000
DATA_SEGMENT_SIM_SIZE   = 65540
DATA_SEGMENT_SYNTH_SIZE = 256

BUILD_DIR   = ./build
SRC_DIR     = ./programs
FILE_DIR    = ./files
TEXT_FILE   = $(FILE_DIR)/text.txt
DATA_FILE   = $(FILE_DIR)/data.txt

RTL_DIR     = ./rtl
TLV_SRC     = $(RTL_DIR)/rv32i_plh.tlv
VERILOG_SRC = $(BUILD_DIR)/gen/rv32i_plh.v

# Copy Verilog support files from reference implementation
VERILOG_REF = ../verilog/rtl
RTL_SUPPORT = $(BUILD_DIR)/gen/support
RTL_INC     = -I$(abspath $(RTL_SUPPORT))/include -y$(abspath $(RTL_SUPPORT))/peripherals -y$(abspath $(RTL_SUPPORT))/src

FILENAME := $(notdir $(PROGRAM))
EXT      := $(suffix $(FILENAME))
NAME     := $(basename $(FILENAME))
PROGRAM_DIR = $(BUILD_DIR)/program
PROGRAM_OBJ = $(PROGRAM_DIR)/$(NAME).o
PROGRAM_ELF = $(PROGRAM_DIR)/$(NAME)

SIM_DIR   = $(BUILD_DIR)/sim
SYNTH_DIR = $(BUILD_DIR)/synth
SYNTH_CCF    = ./synth/gatemate_eval.ccf
SYNTH_DEVICE = CCGM1A1
OFL_BOARD    = gatemate_evb_jtag

IVERILOG_FLAGS = -g2012 -DSIMULATION $(RTL_INC)
VVP            = vvp

GCC_FLAGS = $(GCC_FLAGS_ARCH) -ffreestanding -nostdlib -Os -nostartfiles

# Sandpiper-SaaS settings
SANDPIPER = sandpiper-saas
# Use --reset0 for simulation to initialize all flip-flops
# For synthesis, omit --reset0 to avoid unnecessary reset network
# --clkAlways: avoid clock gating logic
# --inlineGen: inline generated code (no separate _gen.v file)
ifdef SIMULATION
SANDPIPER_FLAGS = -i $(TLV_SRC) -o rv32i_plh.v --outdir $(BUILD_DIR)/gen --reset0 --clkAlways --inlineGen --noline
else
SANDPIPER_FLAGS = -i $(TLV_SRC) -o rv32i_plh.v --outdir $(BUILD_DIR)/gen --clkAlways --inlineGen --noline
endif

.PHONY: all prepare program tlv sim prep_synth synth bitstream clean
.PHONY: riscof-setup riscof-test riscof-test-one riscof-clean riscof-debug

all: sim

prepare: clean
	@mkdir -p $(BUILD_DIR) $(PROGRAM_DIR) $(SIM_DIR) $(SYNTH_DIR) $(BUILD_DIR)/gen
	@echo "$(GREEN)Build directories created$(RESET)"

program: prepare $(PROGRAM_OBJ)
	@mkdir -p $(FILE_DIR)
	@$(GCC_C) $(GCC_FLAGS) -o $(PROGRAM_ELF) $(PROGRAM_OBJ) -Wl,-Ttext=$(TEXT_SEGMENT_START) -Wl,-Tdata=$(DATA_SEGMENT_START)
	@$(GCC_OBJCPY) -O binary -j .text $(PROGRAM_ELF) $(PROGRAM_ELF).text.bin --strip-debug
	@od -t x4 -An -w4 -v $(PROGRAM_ELF).text.bin | tr -d " " > $(TEXT_FILE)
	@$(GCC_OBJCPY) -O binary -j .data $(PROGRAM_ELF) $(PROGRAM_ELF).data.bin --strip-debug
	@od -t x4 -An -w4 -v $(PROGRAM_ELF).data.bin | tr -d " " > $(PROGRAM_ELF).data.hex
	@awk 'BEGIN { addr=0x10000000; } { printf("%08x %s\n", addr, $$0); addr += 4; }' $(PROGRAM_ELF).data.hex > $(DATA_FILE)

ifeq ($(EXT),.s)
$(PROGRAM_OBJ): $(SRC_DIR)/$(FILENAME)
	@mkdir -p $(dir $@)
	@$(GCC_C) $(GCC_FLAGS) -c $< -o $@
endif

# Compile TL-Verilog to Verilog using sandpiper-saas
tlv: prepare
	@echo "$(YELLOW)Compiling TL-Verilog with sandpiper-saas...$(RESET)"
	@mkdir -p $(RTL_SUPPORT)/src $(RTL_SUPPORT)/include $(RTL_SUPPORT)/peripherals
	@cp $(VERILOG_REF)/src/register_file.v $(RTL_SUPPORT)/src/
	@cp -r $(VERILOG_REF)/include/*.vh $(RTL_SUPPORT)/include/ 2>/dev/null || true
	@cp -r $(VERILOG_REF)/peripherals/*.v $(RTL_SUPPORT)/peripherals/ 2>/dev/null || true
	@$(SANDPIPER) $(SANDPIPER_FLAGS) || (test -f $(VERILOG_SRC) && echo "$(YELLOW)Warning: sandpiper-saas returned error but output exists$(RESET)" || exit 1)
	@test -f $(VERILOG_SRC) && echo "$(GREEN)TL-Verilog compiled to $(VERILOG_SRC)$(RESET)" || (echo "$(RED)Failed to generate Verilog$(RESET)" && exit 1)

sim: program 
	@echo "$(YELLOW)Compiling TL-Verilog with sandpiper-saas (simulation mode)...$(RESET)"
	@mkdir -p $(BUILD_DIR)/gen $(RTL_SUPPORT)/src $(RTL_SUPPORT)/include $(RTL_SUPPORT)/peripherals $(RTL_SUPPORT)/tb
	@cp $(VERILOG_REF)/src/register_file.v $(RTL_SUPPORT)/src/
	@cp -r $(VERILOG_REF)/include/*.vh $(RTL_SUPPORT)/include/ 2>/dev/null || true
	@cp -r $(VERILOG_REF)/peripherals/*.v $(RTL_SUPPORT)/peripherals/ 2>/dev/null || true
	@$(SANDPIPER) -i $(TLV_SRC) -o rv32i_plh.v --outdir $(BUILD_DIR)/gen --reset0 --clkAlways --bestsv --fmtInlineGen || (test -f $(VERILOG_SRC) && echo "$(YELLOW)Warning: sandpiper-saas returned error but output exists$(RESET)" || exit 1)
	@test -f $(VERILOG_SRC) && echo "$(GREEN)TL-Verilog compiled to $(VERILOG_SRC)$(RESET)" || (echo "$(RED)Failed to generate Verilog$(RESET)" && exit 1)
	@cp -r $(VERILOG_REF)/tb/*.v $(RTL_SUPPORT)/tb/ 2>/dev/null || true
	@cp $(RTL_DIR)/tb/testbench_debug.v $(RTL_SUPPORT)/tb/testbench.v 2>/dev/null || true
	@IMEM_WORDS=$$(wc -l < $(TEXT_FILE)); \
	IMEM_SIZE=1; \
	while [ $$IMEM_SIZE -lt $$IMEM_WORDS ]; do IMEM_SIZE=$$((IMEM_SIZE * 2)); done; \
	if [ $$IMEM_SIZE -lt $(TEXT_SEGMENT_SIM_SIZE) ]; then IMEM_SIZE=$(TEXT_SEGMENT_SIM_SIZE); fi; \
	while [ $$(wc -l < $(TEXT_FILE)) -lt $$IMEM_SIZE ]; do echo 00000000 >> $(TEXT_FILE); done; \
	VVP_FLAGS=""; \
	if [ "$$DEBUG_VCD" = "1" ]; then VVP_FLAGS="+debug"; fi; \
	$(IVERILOG) $(IVERILOG_FLAGS) -I$(abspath $(BUILD_DIR)/gen) -y$(abspath $(RTL_DIR)) \
		-Ptestbench.IMEM_SIZE=$$IMEM_SIZE -Ptestbench.DMEM_SIZE=$(DATA_SEGMENT_SIM_SIZE) \
		$(VERILOG_SRC) $(wildcard $(RTL_SUPPORT)/src/*.v) $(wildcard $(RTL_SUPPORT)/tb/*.v) \
		$(RTL_DIR)/instruction_memory_fast.v $(RTL_DIR)/data_memory_fast.v \
		-o $(SIM_DIR)/sim.vvp
	@$(VVP) $(SIM_DIR)/sim.vvp $$VVP_FLAGS
	@echo "$(GREEN)Simulation finished$(RESET)"

prep_synth: program tlv
	@while [ $$(wc -l < $(TEXT_FILE)) -lt $(TEXT_SEGMENT_SYNTH_SIZE) ]; do echo 00000000 >> $(TEXT_FILE); done
	@cat $(RTL_SUPPORT)/include/riscv_pkg.vh $(VERILOG_SRC) $(wildcard $(RTL_SUPPORT)/src/*.v) $(wildcard $(RTL_SUPPORT)/peripherals/*.v) > $(SYNTH_DIR)/bundle.v
	@sed -i 's/parameter IMEM_SIZE    = 256/parameter IMEM_SIZE    = $(TEXT_SEGMENT_SYNTH_SIZE)/g' $(SYNTH_DIR)/bundle.v
	@sed -i 's/parameter DMEM_SIZE    = 256/parameter DMEM_SIZE    = $(DATA_SEGMENT_SYNTH_SIZE)/g' $(SYNTH_DIR)/bundle.v
	@echo "$(GREEN)Bundled Verilog for synthesis$(RESET)"

synth: prep_synth
	@yosys -p 'read_verilog -DSYNTHESIS -I$(abspath $(RTL_SUPPORT)/include) $(SYNTH_DIR)/bundle.v; hierarchy -top rv32i_plh; synth_gatemate -top rv32i_plh -luttree -nomx8 -json $(SYNTH_DIR)/bundle.json' 2>&1 | tee $(SYNTH_DIR)/yosys.log
	@nextpnr-himbaechel --json $(SYNTH_DIR)/bundle.json \
		--device $(SYNTH_DEVICE) -o ccf=$(SYNTH_CCF) -o out=$(SYNTH_DIR)/impl.txt \
		--router router2 --log $(SYNTH_DIR)/pnr.log --report $(SYNTH_DIR)/pnr_report.json
	@gmpack $(SYNTH_DIR)/impl.txt $(SYNTH_DIR)/pack.bit
	@echo "$(GREEN)Synthesis and P&R complete$(RESET)"

bitstream: synth
	@test -n "$$SKIP_PROGRAM_FPGA" || openFPGALoader -b $(OFL_BOARD) $(SYNTH_DIR)/pack.bit

clean:
	rm -rf $(BUILD_DIR) $(FILE_DIR)

# RISCOF testing targets
RISCOF_DIR = ../../framework/tests
RISCOF_WORK = $(RISCOF_DIR)/riscof_work
TEST ?= add-01
NUM_TESTS ?= 3

riscof-setup:
	@echo "$(YELLOW)Regenerating RISCOF plugins and test list...$(RESET)"
	@cd ../.. && python3 scripts/generate_riscof_plugins.py --core tlverilog
	@cd $(RISCOF_DIR) && rm -rf riscof_work
	@cd $(RISCOF_DIR) && PATH="../../framework/bin:$$PATH" riscof testlist \
		--config=config.ini \
		--suite=riscv-arch-test/riscv-test-suite/ \
		--env=riscv-arch-test/riscv-test-suite/env \
		--work-dir=riscof_work
	@echo "$(GREEN)RISCOF setup complete$(RESET)"

riscof-test: riscof-setup
	@echo "$(YELLOW)Running $(NUM_TESTS) RISCOF tests...$(RESET)"
	@cd $(RISCOF_WORK) && python3 -c "import yaml; tests=yaml.safe_load(open('test_list.yaml')); \
		keys=list(tests.keys())[:$(NUM_TESTS)]; \
		yaml.dump({k:tests[k] for k in keys}, open('test_list_small.yaml','w'), default_flow_style=False)"
	@cd $(RISCOF_DIR) && PATH="../../framework/bin:$$PATH" riscof run \
		--config=config.ini \
		--suite=riscv-arch-test/riscv-test-suite/ \
		--env=riscv-arch-test/riscv-test-suite/env \
		--work-dir=riscof_work \
		--no-browser \
		--testfile=riscof_work/test_list_small.yaml

riscof-test-one: riscof-setup
	@echo "$(YELLOW)Running single test: $(TEST)$(RESET)"
	@cd $(RISCOF_DIR) && find riscof_work -type d -name "$(TEST).S" | head -1 | xargs -I {} bash -c \
		'cd {}/dut && echo "Building..." && bash -c "$$(grep "cd {}/dut" ../Makefile.tlverilog | sed "s|cd {}/dut; ||")"'

riscof-debug: riscof-setup
	@echo "$(YELLOW)Running test $(TEST) with VCD dump...$(RESET)"
	@export DEBUG_VCD=1 && $(MAKE) riscof-test-one TEST=$(TEST)
	@cd $(RISCOF_DIR) && find riscof_work -type d -name "$(TEST).S" -exec ls -lh {}/dut/*.vcd \; 2>/dev/null || echo "No VCD found"

riscof-clean:
	@rm -rf $(RISCOF_DIR)/riscof_work $(RISCOF_DIR)/tlverilog
	@echo "$(GREEN)RISCOF work directory cleaned$(RESET)"
