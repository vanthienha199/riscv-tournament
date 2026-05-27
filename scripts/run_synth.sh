#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CORE="${1:-all}"
PROGRAM="${PROGRAM:-led_binary_counter.s}"

discover_cores() {
  find "$ROOT/cores" -mindepth 1 -maxdepth 1 -type d ! -name '_*' -printf '%f\n' | sort
}

run_core_synth() {
  local core="$1"
  echo "=== Synthesis: $core ==="
  cd "$ROOT/cores/$core"
  SKIP_PROGRAM_FPGA=1 make PROGRAM="$PROGRAM" synth
}

if [ "$CORE" = "all" ]; then
  for c in $(discover_cores); do
    run_core_synth "$c"
  done
else
  run_core_synth "$CORE"
fi

python3 "$ROOT/scripts/generate_report.py"
