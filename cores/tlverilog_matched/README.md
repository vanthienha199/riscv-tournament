# TL-Verilog Core, Matched Variant

The same RV32I core as `cores/tlverilog/`, structured to mirror the Verilog
reference core: the same adder sharing (one main ALU adder, a separate
subtractor that also serves the comparisons, a PC incrementer, a branch
target adder, and a late adder for AUIPC and the link value) and the same
memory modules, so synthesis produces the same resource usage as the
Verilog core. It exists to show that TL-Verilog reaches identical results
with a fraction of the source.

`cores/tlverilog/` goes further (a single ALU adder for add, subtract, and
compare, and a data memory that infers block RAM) and is the optimized
design. `cores/tlverilog_unshared/` is the readable form without any adder
sharing. All three pass the full RISCOF suite and differ only in `rtl/`.

Run: `make test CORE=tlverilog_matched` from the repository root.
