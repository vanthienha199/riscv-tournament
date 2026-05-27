#!/usr/bin/env bash
# Toolchain wrappers when only riscv64-unknown-elf-* is installed.
# Add to PATH: export PATH="$RV_TOURNAMENT_ROOT/framework/bin:$PATH"

set -euo pipefail

BIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../framework/bin" && pwd)"
mkdir -p "$BIN_DIR"

for tool in gcc g++ as ld objcopy objdump ar nm strip; do
  cat > "$BIN_DIR/riscv32-unknown-elf-$tool" << EOF
#!/usr/bin/env bash
exec \$(which riscv64-unknown-elf-$tool) "\$@"
EOF
  chmod +x "$BIN_DIR/riscv32-unknown-elf-$tool"
done

echo "Created riscv32-unknown-elf-* wrappers in $BIN_DIR"
