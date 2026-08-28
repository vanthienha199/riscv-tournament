# TL-Verilog Core, Unshared Variant

The same RV32I core as `cores/tlverilog/`, kept at the state before the
adder-sharing work. Each adder and comparator is written where it is used,
with no operand muxing, so this version reads more directly at the cost of
more arithmetic cells.

The two variants are functionally equivalent (both pass the full RISCOF
suite) and differ only in `rtl/rv32i_plh.tlv`. Keep whichever one the
tournament wants and delete the other directory.

Run: `make test CORE=tlverilog_unshared` from the repository root.
