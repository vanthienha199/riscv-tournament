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

TEXT_SEGMENT_START = 0x00000000
DATA_SEGMENT_START = 0x10000000

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

sim prep_synth synth bitstream:
	@echo "$(RED)Not implemented — add sim/synth targets for your HDL in Makefile$(RESET)" >&2
	@echo "See cores/verilog/Makefile for the reference Verilog flow." >&2
	@exit 1

clean:
	rm -rf $(BUILD_DIR) $(FILE_DIR)
