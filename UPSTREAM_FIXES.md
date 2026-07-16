# Fixes found while reproducing the environment (candidates for upstream PRs)

1. scripts/create_toolchain_wrappers.sh: computes BIN_DIR with `cd` into
   framework/bin BEFORE mkdir -p, so a fresh clone fails `make setup` with
   "No such file or directory". Fix: mkdir first, then resolve with cd.
   (Found Jul 15, environment: Debian bookworm container, aarch64.)
2. cores/tlverilog/Makefile (Steve's fork): sandpiper-saas without --noline emits
   `line directives that current iverilog (oss-cad-suite 2026) rejects as
   "Invalid line number for `line directive". Added --noline to both flag sets.
   (Update: the real fix is in scripts/generate_riscof_plugins.py, which hardcodes its
   own sandpiper-saas command in the sim template and regenerates the plugin each run.
   Also note the `|| test -f gen/rv32i_plh.v` fallback silently reuses a stale build
   when sandpiper fails, which masks compile errors — same silent-failure class as the
   convert.py bugs found earlier this month.)
