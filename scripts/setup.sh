#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TESTS_DIR="$ROOT/framework/tests"
ARCH_TEST_DIR="$TESTS_DIR/riscv-arch-test"

echo "=== RV Tournament setup ==="

if ! command -v riscof >/dev/null 2>&1; then
  echo "ERROR: riscof not found. Install OSS CAD Suite or pip install riscof." >&2
  exit 1
fi

if ! command -v riscv32-unknown-elf-gcc >/dev/null 2>&1; then
  echo "Creating riscv32 toolchain wrappers (using riscv64-unknown-elf)..."
  bash "$ROOT/scripts/create_toolchain_wrappers.sh"
  export PATH="$ROOT/framework/bin:$PATH"
fi

if ! command -v riscv32-unknown-elf-gcc >/dev/null 2>&1 && ! command -v riscv64-unknown-elf-gcc >/dev/null 2>&1; then
  echo "ERROR: RISC-V GCC toolchain not found." >&2
  exit 1
fi

export PATH="$ROOT/framework/bin:$PATH"

if ! command -v riscv_sim_rv32d >/dev/null 2>&1; then
  echo "Installing SAIL reference simulator (required for make test)..."
  bash "$ROOT/scripts/install_sail.sh"
fi

if [ ! -d "$ARCH_TEST_DIR/.git" ]; then
  echo "Cloning RISC-V architectural test suite..."
  rm -rf "$ARCH_TEST_DIR"
  mkdir -p "$TESTS_DIR"
  cd "$TESTS_DIR"
  riscof arch-test --clone
else
  echo "riscv-arch-test already present."
fi

python3 "$ROOT/scripts/generate_riscof_plugins.py"
echo "Setup complete."
