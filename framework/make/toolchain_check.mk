##################################################################################################################
## Toolchain detection for RV Tournament cores
##################################################################################################################

$(info )
$(info --- Checking toolchain)

GCC_TOOLCHAIN := $(shell which riscv32-unknown-elf-gcc 2>/dev/null || which riscv64-unknown-elf-gcc 2>/dev/null)
ifeq ($(GCC_TOOLCHAIN),)
$(error Neither riscv32-unknown-elf-gcc nor riscv64-unknown-elf-gcc found in PATH)
endif
$(info $(GREEN)RISC-V GCC found$(RESET))
GCC_TOOLCHAIN_PREFIX := $(patsubst %-gcc,%,$(notdir $(GCC_TOOLCHAIN)))
ifeq ($(findstring riscv32,$(GCC_TOOLCHAIN_PREFIX)),)
  GCC_FLAGS_ARCH = -march=rv32i -mabi=ilp32
else
  GCC_FLAGS_ARCH = -march=rv32i -mabi=ilp32
endif
GCC_AS     := $(GCC_TOOLCHAIN_PREFIX)-as
GCC_C      := $(GCC_TOOLCHAIN_PREFIX)-gcc
GCC_LD     := $(GCC_TOOLCHAIN_PREFIX)-ld
GCC_OBJCPY := $(GCC_TOOLCHAIN_PREFIX)-objcopy

IVERILOG := $(shell which iverilog 2>/dev/null)
ifeq ($(IVERILOG),)
$(error iverilog not found in PATH)
endif
$(info $(GREEN)Icarus Verilog found$(RESET))

YOSYS := $(shell which yosys 2>/dev/null)
NEXTPNR_HIMBAECHEL := $(shell which nextpnr-himbaechel 2>/dev/null)
GMPACK := $(shell which gmpack 2>/dev/null)

RED   = $(shell printf "\033[31m")
GREEN = $(shell printf "\033[32m")
YELLOW= $(shell printf "\033[33m")
RESET = $(shell printf "\033[0m")
