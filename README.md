# RISC-V Tournament: Battle of HDLs

**This repository is hacked up for exploration and discovery. Do not build on this AI mess.**


A community-driven, reproducible comparison framework for RISC-V microarchitecture implementations across HDL paradigms.

Modern HDLs span traditional RTL, HLS, and generative approaches — yet directly comparable evaluations under identical conditions remain rare. This repository provides a standardized GitHub-based tournament: contributors implement the same RV32I pipelined core (with hazard unit), and the framework runs architectural compliance tests (RISCOF) and FPGA synthesis (Cologne Chip GateMate Evaluation Board) under uniform conditions.

All results are public, reproducible, and automatically summarized below.

<!-- TOURNAMENT_REPORT_START -->

## Tournament Results

*Last updated: 2026-07-16 15:45 UTC*

### Architecture Test Compliance (RISCOF / RV32I)

| Core | HDL | Tests Passed | Tests Failed | Pass Rate |
|------|-----|--------------|--------------|-----------|
| tlverilog | TL-Verilog | 38 | 0 | 100.0% |
| verilog | Verilog | 38 | 0 | 100.0% |

### FPGA Synthesis (Cologne Chip GateMate Evaluation Board / CCGM1A1)

| Core | CPE_LT | CPE_FF | RAM_HALF | Max Freq (MHz) | Bitstream |
|------|--------|--------|----------|----------------|-----------|
| tlverilog | - | - | - | - | no |
| verilog | - | - | - | - | no |

<!-- TOURNAMENT_REPORT_END -->

## Quick start

```bash
git clone <this-repo> rv_tournament && cd rv_tournament

source .venv/bin/activate

# One-time setup (clones riscv-arch-test, generates RISCOF plugins)
make setup

# Smoke-test the reference Verilog core
make sim CORE=verilog PROGRAM=hello_world.s

# Run full RV32I arch tests (requires SAIL reference simulator — see below)
make test

# Synthesize all cores for GateMate eval board
make synth

# Run everything and refresh the results table in this README
make all
```

## Project layout

```
rv_tournament/
├── cores/
│   ├── verilog/          # Reference implementation (PLH RV32I in Verilog)
│   └── _template/        # Copy-paste starting point for new HDLs
├── framework/
│   ├── tests/            # RISCOF config, plugins, vendored riscv-arch-test
│   ├── bin/              # Toolchain wrappers (riscv32 → riscv64)
│   └── make/             # Shared Makefile fragments
├── scripts/              # setup, test runner, synthesis runner, report generator
├── results/              # Per-core logs and RISCOF output
└── Makefile              # Top-level tournament commands
```

## Adding a new core

1. Copy the template: `cp -r cores/_template cores/myhdl`
2. Edit `cores/myhdl/core.yaml` (HDL name, simulator, description)
3. Implement the same microarchitecture under `cores/myhdl/rtl/`
4. Ensure `make -C cores/myhdl PROGRAM=hello_world.s sim` passes
5. Regenerate plugins: `python3 scripts/generate_riscof_plugins.py --core myhdl`
6. Run: `make test CORE=myhdl && make synth CORE=myhdl`

See `cores/_template/README.md` for details.

## Reference core: `cores/verilog`

5-stage pipelined RV32I with hazard unit, full instruction set, MMIO LED block, and GateMate eval board pinout.

| Property | Value |
|----------|-------|
| Top module | `rv32i_plh` |
| Simulator | Icarus Verilog |
| Arch tests | RISCOF + sail_cSim reference |
| FPGA | Cologne Chip GateMate Evaluation Board (CCGM1A1) |
| Demo bitstream | `led_binary_counter.s` |

## Toolchain setup

### Ubuntu (22.04 / 24.04)

From this repo clone:

```bash
sudo apt update
sudo apt install -y git make python3 python3-pip gcc g++ flex bison \
  libfl-dev libreadline-dev gawk tcl-dev libffi-dev git \
  graphviz xdot pkg-config libboost-all-dev

# RISC-V toolchain (64-bit multilib covers RV32 via -march=rv32i)
sudo apt install -y gcc-riscv64-unknown-elf binutils-riscv64-unknown-elf

# OSS CAD Suite (iverilog, yosys, nextpnr-himbaechel, gmpack)
# Download from https://github.com/YosysHQ/oss-cad-suite/releases
wget https://github.com/YosysHQ/oss-cad-suite-build/releases/download/2026-05-29/oss-cad-suite-linux-x64-20260529.tgz
tar xzf oss-cad-suite-linux-x64-*.tgz
grep -qxF 'source ~/oss-cad-suite/environment' ~/.bashrc || \
  echo 'source ~/oss-cad-suite/environment' >> ~/.bashrcsource ~/oss-cad-suite/environment

# Python environment
python3 -m venv .venv
source .venv/bin/activate
pip install -U pip

# RISCOF
pip install riscof

# SAIL C reference simulator (required for arch tests)
# Downloads a prebuilt sail-riscv release and installs riscv_sim_rv32d wrappers.
bash scripts/install_sail.sh

# FPGA programming (optional)
sudo apt install -y openfpgaloader

# Tournament setup
make setup
```

### Fedora (40+)

```bash
sudo dnf install -y git make python3 gcc gcc-c++ flex bison readline-devel \
  gawk tcl-devel libffi-devel boost-devel graphviz

# RISC-V cross toolchain from source or prebuilt:
# https://github.com/riscv-collab/riscv-gnu-toolchain

# OSS CAD Suite — same tarball as Ubuntu
# RISCOF: pip install riscof
# openFPGALoader: sudo dnf install openfpgaloader

make setup
```

### Arch Linux

```bash
sudo pacman -S git make python python-pip riscv64-unknown-elf-gcc riscv64-unknown-elf-binutils
# OSS CAD Suite + pip install riscof + SAIL (as above)
make setup
```

If only `riscv64-unknown-elf-*` tools are installed, `make setup` creates `riscv32-unknown-elf-*` wrappers in `framework/bin/`. Add to your shell:

```bash
export PATH="$(pwd)/framework/bin:$PATH"
```

## Makefile targets

| Target | Description |
|--------|-------------|
| `make setup` | Clone `riscv-arch-test`, create toolchain wrappers, generate RISCOF plugins |
| `make test [CORE=name]` | Run RISCOF RV32I compliance tests |
| `make synth [CORE=name]` | Yosys + nextpnr + gmpack for GateMate eval board |
| `make all` | `test` + `synth` + update README report |
| `make report` | Regenerate results section in README only |
| `make sim CORE=verilog PROGRAM=hello_world.s` | Single-core simulation smoke test |
| `make clean` | Remove build artifacts |

Environment variables:

- `PROGRAM` — assembly program for sim/synth (default: `led_binary_counter.s`)
- `JOBS` — parallel RISCOF jobs (default: 4)
- `SKIP_PROGRAM_FPGA=1` — synthesize without programming the board

## RISCOF architectural tests

Tests are vendored via `riscof arch-test --clone` into `framework/tests/riscv-arch-test/`. The suite used is `rv32i_m/I` only (38 RV32I base instruction tests; hints and privilege suites are excluded).

Each core gets an auto-generated Python plugin under `framework/tests/<core>/` that:

1. Compiles the arch-test `.S` file with the RISC-V GCC toolchain
2. Loads `.text`/`.data` into `./files/` for the core's memory models
3. Runs cycle simulation (Icarus Verilog for the reference core)
4. Dumps signatures on `ecall` with `a0=18` for comparison against the SAIL reference

Configure the active DUT in `framework/tests/config.ini` (regenerated by `scripts/generate_riscof_plugins.py`).

## FPGA synthesis (Cologne Chip GateMate Evaluation Board)

Target device: **CCGM1A1** (GateMate A1 on the Cologne Chip evaluation board).

Flow per core:

1. `make PROGRAM=led_binary_counter.s prep_synth` — compile demo program, bundle RTL
2. Yosys `synth_gatemate` → nextpnr-himbaechel → `gmpack` → `build/synth/pack.bit`
3. Program: `openFPGALoader -b gatemate_evb_jtag cores/<core>/build/synth/pack.bit`

Pin constraints: `cores/<core>/synth/gatemate_eval.ccf` (10 MHz clk on `IO_SB_A8`, btn on `IO_EB_B0`, led1–led8 on `IO_EB_B1`–`IO_EB_B8`).

Board notes:

- Close jumper **JP4** to route the onboard LEDs to GPIO bank EB.
- Onboard clock is **10 MHz** (vs. the Tec0117’s different oscillator).
- LEDs are **active-low**; synthesis inverts GPIO outputs so the demo counter displays correctly.

The demo program writes a binary counter to MMIO `0x20000000`, driving the board LEDs.

## Contributing

1. Fork the repository
2. Add your implementation under `cores/<hdl-name>/`
3. Ensure `make test CORE=<hdl-name>` and `make synth CORE=<hdl-name>` pass
4. Open a pull request — CI (when enabled) will run the same flow

## License

Tournament framework and reference Verilog core: MIT.  
`riscv-arch-test` retains its upstream license (see `framework/tests/riscv-arch-test/`).

