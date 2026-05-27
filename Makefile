.PHONY: setup test synth all report clean help

CORE ?= all
PROGRAM ?= led_binary_counter.s
JOBS ?= 4

help:
	@echo "RV Tournament — Makefile targets"
	@echo ""
	@echo "  make setup          Install deps and clone riscv-arch-test"
	@echo "  make test           Run RISCOF arch tests for all cores"
	@echo "  make synth          Synthesize all cores for Tec0117"
	@echo "  make all            test + synth + report"
	@echo "  make report         Regenerate README results section"
	@echo "  make sim CORE=verilog PROGRAM=hello_world.s"
	@echo "  make clean"

setup:
	@bash scripts/setup.sh

test:
	@JOBS=$(JOBS) bash scripts/run_tests.sh $(CORE)

synth:
	@PROGRAM=$(PROGRAM) bash scripts/run_synth.sh $(CORE)

all: test synth report

report:
	@python3 scripts/generate_report.py

sim:
	@$(MAKE) -C cores/$(CORE) PROGRAM=$(PROGRAM) sim

clean:
	@for d in cores/*/; do $(MAKE) -C "$$d" clean 2>/dev/null || true; done
	@rm -rf results framework/tests/riscof_work
