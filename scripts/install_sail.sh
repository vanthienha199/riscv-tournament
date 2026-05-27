#!/usr/bin/env bash
# Install the SAIL C reference simulator required by RISCOF sail_cSim plugin.
#
# Downloads a prebuilt sail-riscv release and installs riscv_sim_rv32d wrappers
# that invoke sail_riscv_sim with the correct JSON configuration.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL_DIR="${SAIL_INSTALL_DIR:-$ROOT/framework/bin}"
SAIL_DIR="${SAIL_RISCV_DIR:-$ROOT/framework/sail-riscv}"
SAIL_VERSION="${SAIL_RISCV_VERSION:-0.11}"

RV32_CONFIG="${SAIL_RV32_CONFIG:-rv32d_v128_e32.json}"
RV64_CONFIG="${SAIL_RV64_CONFIG:-rv64d_v128_e64.json}"

if command -v riscv_sim_rv32d >/dev/null 2>&1; then
  existing="$(command -v riscv_sim_rv32d)"
  if [ "$existing" = "$INSTALL_DIR/riscv_sim_rv32d" ] && \
     grep -q "$SAIL_DIR/bin/sail_riscv_sim" "$INSTALL_DIR/riscv_sim_rv32d" 2>/dev/null; then
    echo "riscv_sim_rv32d already installed in $INSTALL_DIR"
    exit 0
  fi
fi

mkdir -p "$INSTALL_DIR"

install_wrappers() {
  local sim_bin="$1"
  local config_dir="$2"

  cat > "$INSTALL_DIR/riscv_sim_rv32d" <<EOF
#!/usr/bin/env bash
exec "$sim_bin" --config "$config_dir/$RV32_CONFIG" "\$@"
EOF
  cat > "$INSTALL_DIR/riscv_sim_rv64d" <<EOF
#!/usr/bin/env bash
exec "$sim_bin" --config "$config_dir/$RV64_CONFIG" "\$@"
EOF
  chmod +x "$INSTALL_DIR/riscv_sim_rv32d" "$INSTALL_DIR/riscv_sim_rv64d"
  echo "Installed riscv_sim_rv32d and riscv_sim_rv64d wrappers in $INSTALL_DIR"
}

download_prebuilt() {
  local arch="$1"
  local url="https://github.com/riscv/sail-riscv/releases/download/${SAIL_VERSION}/sail-riscv-Linux-${arch}.tar.gz"
  local tmp
  tmp="$(mktemp -d)"

  echo "Downloading sail-riscv ${SAIL_VERSION} (${arch})..."
  if ! curl -fsSL -o "$tmp/sail-riscv.tar.gz" "$url"; then
    rm -rf "$tmp"
    return 1
  fi

  rm -rf "$SAIL_DIR"
  mkdir -p "$SAIL_DIR"
  tar xzf "$tmp/sail-riscv.tar.gz" -C "$SAIL_DIR" --strip-components=1
  rm -rf "$tmp"
}

case "$(uname -m)" in
  x86_64)  SAIL_ARCH="x86_64" ;;
  aarch64|arm64) SAIL_ARCH="aarch64" ;;
  *)
    echo "Unsupported CPU architecture: $(uname -m)" >&2
    exit 1
    ;;
esac

if [ -x "$SAIL_DIR/bin/sail_riscv_sim" ]; then
  echo "Using existing sail-riscv at $SAIL_DIR"
elif download_prebuilt "$SAIL_ARCH"; then
  echo "Installed sail-riscv to $SAIL_DIR"
else
  echo "ERROR: failed to download sail-riscv ${SAIL_VERSION} for ${SAIL_ARCH}" >&2
  exit 1
fi

CONFIG_DIR="$SAIL_DIR/share/sail-riscv/config"
SIM_BIN="$SAIL_DIR/bin/sail_riscv_sim"

if [ ! -x "$SIM_BIN" ]; then
  echo "ERROR: sail_riscv_sim not found at $SIM_BIN" >&2
  exit 1
fi
if [ ! -f "$CONFIG_DIR/$RV32_CONFIG" ]; then
  echo "ERROR: config $CONFIG_DIR/$RV32_CONFIG not found" >&2
  exit 1
fi

install_wrappers "$SIM_BIN" "$CONFIG_DIR"
