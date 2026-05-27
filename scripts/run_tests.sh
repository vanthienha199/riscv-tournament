#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CORE="${1:-all}"
JOBS="${JOBS:-4}"

discover_cores() {
  find "$ROOT/cores" -mindepth 1 -maxdepth 1 -type d ! -name '_*' -printf '%f\n' | sort
}

run_core_tests() {
  local core="$1"
  echo "=== RISCOF tests: $core ==="
  mkdir -p "$ROOT/results/$core"
  export PATH="$ROOT/framework/bin:$PATH"
  python3 "$ROOT/scripts/generate_riscof_plugins.py" --core "$core"
  cd "$ROOT/framework/tests"
  riscof run --config ./config.ini \
    --suite ./riscv-arch-test/riscv-test-suite/rv32i_m/I \
    --env ./riscv-arch-test/riscv-test-suite/env \
    --no-browser 2>&1 | tee "$ROOT/results/$core/riscof_run.log" || true
  riscof testlist --config ./config.ini 2>/dev/null | tee "$ROOT/results/$core/riscof_summary.txt" || \
    tail -30 "$ROOT/results/$core/riscof_run.log" > "$ROOT/results/$core/riscof_summary.txt"
}

if [ "$CORE" = "all" ]; then
  for c in $(discover_cores); do
    run_core_tests "$c"
  done
else
  run_core_tests "$CORE"
fi

python3 "$ROOT/scripts/generate_report.py"
