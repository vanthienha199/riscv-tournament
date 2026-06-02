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
RTL_SRC     = $(RTL_DIR)/src/*.v
RTL_PERIPH  = $(RTL_DIR)/peripherals/*.v
RTL_TB      = $(RTL_DIR)/tb/*.v
RTL_INC     = -I$(abspath .)/$(RTL_DIR)/include -y$(abspath .)/$(RTL_DIR)/peripherals

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

.PHONY: all prepare program sim prep_synth synth bitstream clean

all: sim

prepare: clean
	@mkdir -p $(BUILD_DIR) $(PROGRAM_DIR) $(SIM_DIR) $(SYNTH_DIR)
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

sim: program
	@IMEM_WORDS=$$(wc -l < $(TEXT_FILE)); \
	IMEM_SIZE=1; \
	while [ $$IMEM_SIZE -lt $$IMEM_WORDS ]; do IMEM_SIZE=$$((IMEM_SIZE * 2)); done; \
	if [ $$IMEM_SIZE -lt $(TEXT_SEGMENT_SIM_SIZE) ]; then IMEM_SIZE=$(TEXT_SEGMENT_SIM_SIZE); fi; \
	while [ $$(wc -l < $(TEXT_FILE)) -lt $$IMEM_SIZE ]; do echo 00000000 >> $(TEXT_FILE); done; \
	$(IVERILOG) $(IVERILOG_FLAGS) \
		-Ptestbench.IMEM_SIZE=$$IMEM_SIZE -Ptestbench.DMEM_SIZE=$(DATA_SEGMENT_SIM_SIZE) \
		$(wildcard $(RTL_DIR)/src/*.v) $(wildcard $(RTL_DIR)/tb/*.v) \
		-o $(SIM_DIR)/sim.vvp
	@$(VVP) $(SIM_DIR)/sim.vvp
	@echo "$(GREEN)Simulation finished$(RESET)"

prep_synth: program
	@while [ $$(wc -l < $(TEXT_FILE)) -lt $(TEXT_SEGMENT_SYNTH_SIZE) ]; do echo 00000000 >> $(TEXT_FILE); done
	@cat $(RTL_DIR)/include/riscv_pkg.vh $(wildcard $(RTL_DIR)/src/*.v) $(wildcard $(RTL_DIR)/peripherals/*.v) > $(SYNTH_DIR)/bundle.v
	@sed -i 's/parameter IMEM_SIZE    = 256/parameter IMEM_SIZE    = $(TEXT_SEGMENT_SYNTH_SIZE)/g' $(SYNTH_DIR)/bundle.v
	@sed -i 's/parameter DMEM_SIZE    = 256/parameter DMEM_SIZE    = $(DATA_SEGMENT_SYNTH_SIZE)/g' $(SYNTH_DIR)/bundle.v
	@echo "$(GREEN)Bundled Verilog for synthesis$(RESET)"

synth: prep_synth
	@yosys -p 'read_verilog -DSYNTHESIS -I$(abspath $(RTL_DIR)/include) $(SYNTH_DIR)/bundle.v; hierarchy -top rv32i_plh; synth_gatemate -top rv32i_plh -luttree -nomx8 -json $(SYNTH_DIR)/bundle.json' 2>&1 | tee $(SYNTH_DIR)/yosys.log
	@nextpnr-himbaechel --json $(SYNTH_DIR)/bundle.json \
		--device $(SYNTH_DEVICE) -o ccf=$(SYNTH_CCF) -o out=$(SYNTH_DIR)/impl.txt \
		--router router2 --log $(SYNTH_DIR)/pnr.log --report $(SYNTH_DIR)/pnr_report.json
	@gmpack $(SYNTH_DIR)/impl.txt $(SYNTH_DIR)/pack.bit
	@echo "$(GREEN)Synthesis and P&R complete$(RESET)"

bitstream: synth
	@test -n "$$SKIP_PROGRAM_FPGA" || openFPGALoader -b $(OFL_BOARD) $(SYNTH_DIR)/pack.bit

clean:
	rm -rf $(BUILD_DIR)
