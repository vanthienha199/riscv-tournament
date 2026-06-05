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

# Default flags
EXTRA_FLAGS=-D "RUN_TEST=$(RUN_TEST)" -D "TESTNAME=mk$(RUN_TEST)" -check-assert
EXTRA_FLAGS+=-show-schedule -D "BSV_TIMESCALE=1ns/1ps" -aggressive-conditions +RTS -Ksize -RTS
#EXTRA_FLAGS+=-keep-inlined-boundaries
EXTRA_FLAGS+=-opt-undetermined-vals
EXTRA_FLAGS+=-keep-fires 
#EXTRA_FLAGS+=-remove-dollar
#EXTRA_FLAGS+=-remove-empty-rules
#EXTRA_FLAGS+=-remove-false-rules
#EXTRA_FLAGS+=-remove-starved-rules
#EXTRA_FLAGS+=-remove-unused-modules
#EXTRA_FLAGS+=-resource-simple
#EXTRA_FLAGS+=-sat-stp
#EXTRA_FLAGS+=-sat-yices
#EXTRA_FLAGS+=-split-if
EXTRA_FLAGS+=-D "IMEM_SIZE=$(TEXT_SEGMENT_SIM_SIZE)" -D "DMEM_SIZE=$(DATA_SEGMENT_SIM_SIZE)"
#EXTRA_FLAGS+=$(CLI_FLAGS)

ifdef SIMULATION
	EXTRA_FLAGS+=-D "SIMULATION=1"
endif

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
#RUN_FLAGS+=-V dump.vcd

MAKE = make -f docker.mk

IMEM_FILE := ./files/text.txt
DMEM_FILE := ./files/data.txt

include $(BSV_LIBS)/bluelib/*.mk

include $(BSV_TOOLS)/scripts/rules.mk

prep_synth: compile_top
	cp -r $(BSVDIR)/Verilog $(BUILDDIR)/bsvVerilog