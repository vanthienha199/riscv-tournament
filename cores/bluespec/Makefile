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

FILENAME := $(notdir $(PROGRAM))
EXT      := $(suffix $(FILENAME))
NAME     := $(basename $(FILENAME))
PROGRAM_DIR = $(BUILD_DIR)/program
PROGRAM_OBJ = $(PROGRAM_DIR)/$(NAME).o
PROGRAM_ELF = $(PROGRAM_DIR)/$(NAME)

SYNTH_DIR = $(BUILD_DIR)/synth
SYNTH_CCF    = ./synth/gatemate_eval.ccf
SYNTH_DEVICE = CCGM1A1
OFL_BOARD    = gatemate_evb_jtag

GCC_FLAGS = $(GCC_FLAGS_ARCH) -ffreestanding -nostdlib -Os -nostartfiles

.PHONY: all prepare program sim prep_synth synth bitstream clean

all: sim

program: $(PROGRAM_OBJ)
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

include ../../framework/make/docker.mk

DOCKER_IMAGE ?= wirthjohannes/bsv:riscv-tournament

DOCKER_CMD = $(DOCKER_RUN) make $(DOCKER_MAKE_OPTIONS) -C $(MOUNT_DIR) -f $(MOUNT_DIR)/docker.mk

prep_synth: program check_docker
	@while [ $$(wc -l < $(TEXT_FILE)) -lt $(TEXT_SEGMENT_SYNTH_SIZE) ]; do echo 00000000 >> $(TEXT_FILE); done
	mkdir -p $(SYNTH_DIR) $(BUILD_DIR)
	$(DOCKER_CMD) prep_synth SIM_TYPE=VERILOG NOLOG=1 TEXT_SEGMENT_SIM_SIZE=$(TEXT_SEGMENT_SYNTH_SIZE) DATA_SEGMENT_SIM_SIZE=$(DATA_SEGMENT_SYNTH_SIZE)

TOP_MODULE=mkTop

synth: prep_synth
	@yosys -p 'read_verilog -defer -DSYNTHESIS $(filter-out $(BUILD_DIR)/bsvVerilog/main.v $(BUILD_DIR)/bsvVerilog/ProbeHook.v $(BUILD_DIR)/bsvVerilog/InoutConnect.v, $(wildcard $(BUILD_DIR)/bsvVerilog/*.v)) $(BUILD_DIR)/verilog/$(TOP_MODULE).v; chparam -set imem_file "./files/text.txt" $(TOP_MODULE); chparam -set dmem_file "./files/data.txt" $(TOP_MODULE); hierarchy -top $(TOP_MODULE); synth_gatemate -luttree -nomx8 -top $(TOP_MODULE) -json $(SYNTH_DIR)/bundle.json' 2>&1 | tee $(SYNTH_DIR)/yosys.log
	@nextpnr-himbaechel --json $(SYNTH_DIR)/bundle.json --write $(SYNTH_DIR)/pnrbundle.json \
		--device $(SYNTH_DEVICE) -o ccf=$(SYNTH_CCF) -o out=$(SYNTH_DIR)/impl.txt \
		--router router2 --log $(SYNTH_DIR)/pnr.log --report $(SYNTH_DIR)/pnr_report.json
	@gmpack $(SYNTH_DIR)/impl.txt $(SYNTH_DIR)/pack.bit
	@echo "$(GREEN)Synthesis and P&R complete$(RESET)"

bitstream: synth
	@test -n "$$SKIP_PROGRAM_FPGA" || openFPGALoader -b $(OFL_BOARD) $(SYNTH_DIR)/pack.bit

sim: program check_docker
	mkdir -p $(MOUNT_BUILD_DIR)
	cp ./zero.txt $(MOUNT_BUILD_DIR)/
	$(DOCKER_CMD) sim BUILDDIR=$(BASE_MOUNT_DIR)/build FILE_DIR=$(BASE_MOUNT_DIR)/files SIM_TYPE=$(SIM_TYPE) VSIM=$(VSIM) LOG=$(LOG) SIMULATION=1 TEXT_SEGMENT_SIM_SIZE=$(TEXT_SEGMENT_SIM_SIZE) DATA_SEGMENT_SIM_SIZE=$(DATA_SEGMENT_SIM_SIZE)

clean:
	rm -rf $(BUILD_DIR) $(FILE_DIR)
