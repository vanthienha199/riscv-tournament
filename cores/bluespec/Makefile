RED     = $(shell printf "\033[31m")
GREEN   = $(shell printf "\033[32m")
RESET   = $(shell printf "\033[0m")

PROGRAM ?=
_require_program = program
ifneq ($(filter $(_require_program),$(MAKECMDGOALS)),)
ifeq ($(PROGRAM),)
$(error $(RED)Usage: make PROGRAM=<program.s|program.c> [target]$(RESET))
endif
endif

BUILD_DIR   = ./build
SRC_DIR     = ./programs
FILE_DIR    = ./files
TEXT_FILE   = $(FILE_DIR)/text.txt
DATA_FILE   = $(FILE_DIR)/data.txt

FILENAME := $(notdir $(PROGRAM))
EXT      := $(suffix $(FILENAME))
NAME     := $(basename $(FILENAME))
PROGRAM_DIR = $(BUILD_DIR)/program
PROGRAM_OBJ = $(PROGRAM_DIR)/$(NAME).o
PROGRAM_ELF = $(PROGRAM_DIR)/$(NAME)

SYNTH_DIR = $(BUILD_DIR)/synth
SYNTH_CCF = ./synth/gatemate_eval.ccf
SYNTH_DEVICE = CCGM1A1
OFL_BOARD    = gatemate_evb_jtag

GCC_TOOLCHAIN := $(shell which riscv32-unknown-elf-gcc 2>/dev/null || which riscv64-unknown-elf-gcc 2>/dev/null)
ifeq ($(GCC_TOOLCHAIN),)
$(error riscv32-unknown-elf-gcc or riscv64-unknown-elf-gcc not found in PATH)
endif
GCC_PREFIX := $(patsubst %-gcc,%,$(notdir $(GCC_TOOLCHAIN)))
GCC_C      := $(GCC_PREFIX)-gcc
GCC_OBJCPY := $(GCC_PREFIX)-objcopy
GCC_FLAGS  := -march=rv32i -mabi=ilp32 -ffreestanding -nostdlib -Os -nostartfiles

.PHONY: all program sim prep_synth synth bitstream clean help

help:
	@echo "Targets: program (build memory init files), sim, synth — implement sim/synth for your HDL"

all: help

program: $(PROGRAM_OBJ)
	@mkdir -p $(FILE_DIR)
	@$(GCC_C) $(GCC_FLAGS) -o $(PROGRAM_ELF) $(PROGRAM_OBJ) \
		-Wl,-Ttext=$(TEXT_SEGMENT_START) -Wl,-Tdata=$(DATA_SEGMENT_START)
	@$(GCC_OBJCPY) -O binary -j .text $(PROGRAM_ELF) $(PROGRAM_ELF).text.bin --strip-debug
	@od -t x4 -An -w4 -v $(PROGRAM_ELF).text.bin | tr -d " " > $(TEXT_FILE)
	@$(GCC_OBJCPY) -O binary -j .data $(PROGRAM_ELF) $(PROGRAM_ELF).data.bin --strip-debug
	@od -t x4 -An -w4 -v $(PROGRAM_ELF).data.bin | tr -d " " > $(PROGRAM_ELF).data.hex
	@awk 'BEGIN { addr=0x10000000; } { printf("%08x %s\n", addr, $$0); addr += 4; }' $(PROGRAM_ELF).data.hex > $(DATA_FILE)
	@echo "$(GREEN)Wrote $(TEXT_FILE) and $(DATA_FILE)$(RESET)"

ifeq ($(EXT),.s)
$(PROGRAM_OBJ): $(SRC_DIR)/$(FILENAME)
	@mkdir -p $(dir $@)
	@$(GCC_C) $(GCC_FLAGS) -c $< -o $@
else
$(error Only .s assembly programs are supported in the template Makefile)
endif

TOP_MODULE=mkTop
TESTBENCH_MODULE=mkTestbench
IGNORE_MODULES=mkTestbench mkTestsMainTest
MAIN_MODULE=RV32I_PLH
TESTBENCH_FILE=rtl/Testbench.bsv
SRCDIR=$(PWD)/rtl

# Initialize
ifndef BSV_TOOLS
$(error BSV_TOOLS is not set (Check .bsv_tools or specify it through the command line))
endif
VIVADO_ADD_PARAMS := ''
CONSTRAINT_FILES := ''
EXTRA_BSV_LIBS:=
EXTRA_LIBRARIES:=
RUN_FLAGS:=

PROJECT_NAME=SonicRV_BSV

ifeq ($(RUN_TEST),)
RUN_TEST=TestsMainTest
endif

IMEM_SIZE=8192
DMEM_SIZE=65540

# Default flags
EXTRA_FLAGS=-D "RUN_TEST=$(RUN_TEST)" -D "TESTNAME=mk$(RUN_TEST)"
EXTRA_FLAGS+=-show-schedule -D "BSV_TIMESCALE=1ns/1ps" -aggressive-conditions +RTS -Ksize -RTS
EXTRA_FLAGS+=-keep-inlined-boundaries
EXTRA_FLAGS+=-opt-undetermined-vals
#EXTRA_FLAGS+=-keep-fires 
#EXTRA_FLAGS+=-remove-dollar
#EXTRA_FLAGS+=-remove-empty-rules
#EXTRA_FLAGS+=-remove-false-rules
#EXTRA_FLAGS+=-remove-starved-rules
#EXTRA_FLAGS+=-remove-unused-modules
#EXTRA_FLAGS+=-resource-simple
#EXTRA_FLAGS+=-sat-stp
#EXTRA_FLAGS+=-sat-yices
#EXTRA_FLAGS+=-split-if
EXTRA_FLAGS+=$(CLI_FLAGS)

###
# User configuration
###

# Comment the following line if -O3 should be used during compilation
# Keep uncommented for short running simulations
CXX_NO_OPT := 1

# Any additional files added during compilation
# For instance for BDPI or Verilog/VHDL files for simulation
# CPP_FILES += $(current_dir)/src/mem_sim.cpp

# Custom defines added to compile steps
# EXTRA_FLAGS+=-D "BENCHMARK=1"

# Flags added to simulator execution
RUN_FLAGS+=-V dump.vcd

clean:
	rm -rf $(BUILD_DIR) $(FILE_DIR)

BSV_VERILOG_MODULES := $(wildcard $(BSVDIR)/Verilog/*.v)

BSV_VERILOG_MODULES := $(filter-out \
  $(BSVDIR)/Verilog/main.v \
  $(BSVDIR)/Verilog/ProbeHook.v \
  $(BSVDIR)/Verilog/InoutConnect.v, \
  $(BSV_VERILOG_MODULES))


IMEM_FILE := ./files/text.txt
DMEM_FILE := ./files/data.txt

TEXT_SEGMENT_START      = 0x00000000
TEXT_SEGMENT_SIM_SIZE   = 8192
TEXT_SEGMENT_SYNTH_SIZE = 1024
DATA_SEGMENT_START      = 0x10000000
DATA_SEGMENT_SIM_SIZE   = 65540
DATA_SEGMENT_SYNTH_SIZE = 256

include $(BSV_TOOLS)/scripts/rules.mk

prep_synth: program
	@while [ $$(wc -l < $(TEXT_FILE)) -lt $(TEXT_SEGMENT_SYNTH_SIZE) ]; do echo 00000000 >> $(TEXT_FILE); done
	mkdir -p $(SYNTH_DIR)
	make compile_top SIM_TYPE=VERILOG CLI_FLAGS='-D "IMEM_SIZE=$(TEXT_SEGMENT_SYNTH_SIZE)" -D "DMEM_SIZE=$(DATA_SEGMENT_SYNTH_SIZE)"'

synth: prep_synth
	@yosys -p 'read_verilog -defer -DSYNTHESIS $(BSV_VERILOG_MODULES) $(BUILDDIR)/verilog/$(TOP_MODULE).v; chparam -set imem_file "./files/text.txt" $(TOP_MODULE); chparam -set dmem_file "./files/data.txt" $(TOP_MODULE); hierarchy -top $(TOP_MODULE); synth_gatemate -luttree -nomx8 -top $(TOP_MODULE) -json $(SYNTH_DIR)/bundle.json' 2>&1 | tee $(SYNTH_DIR)/yosys.log
	@nextpnr-himbaechel --json $(SYNTH_DIR)/bundle.json --write $(SYNTH_DIR)/pnrbundle.json \
		--device $(SYNTH_DEVICE) -o ccf=$(SYNTH_CCF) -o out=$(SYNTH_DIR)/impl.txt \
		--router router2 --log $(SYNTH_DIR)/pnr.log --report $(SYNTH_DIR)/pnr_report.json
	@gmpack $(SYNTH_DIR)/impl.txt $(SYNTH_DIR)/pack.bit
	@echo "$(GREEN)Synthesis and P&R complete$(RESET)"

bitstream: synth
	@test -n "$$SKIP_PROGRAM_FPGA" || openFPGALoader -b $(OFL_BOARD) $(SYNTH_DIR)/pack.bit