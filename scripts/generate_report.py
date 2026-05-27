#!/usr/bin/env python3
"""Collect test and synthesis metrics and update README tournament report."""

import json
import os
import re
import subprocess
from datetime import datetime, timezone

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
CORES = os.path.join(ROOT, "cores")
RESULTS = os.path.join(ROOT, "results")
README = os.path.join(ROOT, "README.md")
MARKER_START = "<!-- TOURNAMENT_REPORT_START -->"
MARKER_END = "<!-- TOURNAMENT_REPORT_END -->"


def load_core_meta(core_dir):
    meta = {"name": os.path.basename(core_dir)}
    path = os.path.join(core_dir, "core.yaml")
    if os.path.isfile(path):
        with open(path) as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith("#") and ":" in line:
                    k, v = line.split(":", 1)
                    meta[k.strip()] = v.strip()
    return meta


def parse_riscof_summary(core_name):
    summary = os.path.join(RESULTS, core_name, "riscof_summary.txt")
    if not os.path.isfile(summary):
        return None
    with open(summary) as f:
        text = f.read()
    passed = failed = total = 0
    m = re.search(r"Total\s*:\s*(\d+)", text)
    if m:
        total = int(m.group(1))
    m = re.search(r"Passed\s*:\s*(\d+)", text)
    if m:
        passed = int(m.group(1))
    m = re.search(r"Failed\s*:\s*(\d+)", text)
    if m:
        failed = int(m.group(1))
    return {"total": total, "passed": passed, "failed": failed, "pass_rate": (passed / total * 100) if total else 0}


def parse_pnr_report(core_name):
    report = os.path.join(CORES, core_name, "build", "synth", "pnr_report.json")
    if not os.path.isfile(report):
        return None
    try:
        with open(report) as f:
            data = json.load(f)
    except json.JSONDecodeError:
        return None
    util = data.get("utilization", {})
    fmax = data.get("fmax", {})
    max_freq = None
    if isinstance(fmax, dict):
        for v in fmax.values():
            if isinstance(v, dict) and "achieved" in v:
                max_freq = round(v["achieved"], 2)
    lut_used = util.get("LUT4", {}).get("used")
    dff_used = util.get("DFF", {}).get("used")
    return {
        "logic_cells": lut_used,
        "registers": dff_used,
        "max_freq_mhz": max_freq,
    }


def parse_yosys_stats(core_name):
    log = os.path.join(CORES, core_name, "build", "synth", "yosys.log")
    if not os.path.isfile(log):
        return None
    with open(log) as f:
        text = f.read()
    cells = None
    for line in text.splitlines():
        if "Number of cells:" in line:
            cells = line.split(":")[-1].strip()
    return {"cells": cells}


def discover_cores():
    if not os.path.isdir(CORES):
        return []
    return sorted(
        d for d in os.listdir(CORES)
        if os.path.isdir(os.path.join(CORES, d)) and not d.startswith("_") and os.path.isfile(os.path.join(CORES, d, "core.yaml"))
    )


def build_report():
    cores = discover_cores()
    now = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    lines = [
        MARKER_START,
        "",
        "## Tournament Results",
        "",
        f"*Last updated: {now}*",
        "",
        "### Architecture Test Compliance (RISCOF / RV32I)",
        "",
        "| Core | HDL | Architecture | Tests Passed | Tests Failed | Pass Rate |",
        "|------|-----|--------------|--------------|--------------|-----------|",
    ]

    synth_rows = []
    for core in cores:
        meta = load_core_meta(os.path.join(CORES, core))
        tests = parse_riscof_summary(core)
        if tests:
            lines.append(
                f"| {core} | {meta.get('hdl', '-')} | {meta.get('architecture', '-')} | "
                f"{tests['passed']} | {tests['failed']} | {tests['pass_rate']:.1f}% |"
            )
        else:
            lines.append(
                f"| {core} | {meta.get('hdl', '-')} | {meta.get('architecture', '-')} | - | - | - |"
            )

        pnr = parse_pnr_report(core)
        yosys = parse_yosys_stats(core)
        synth_rows.append((core, meta, pnr, yosys))

    lines += [
        "",
        "### FPGA Synthesis (Trenz Tec0117 / GW1NR-9)",
        "",
        "| Core | Logic Cells | Registers | Max Freq (MHz) | Bitstream |",
        "|------|-------------|-----------|----------------|-----------|",
    ]

    for core, meta, pnr, yosys in synth_rows:
        bitstream = os.path.join(CORES, core, "build", "synth", "pack.fs")
        has_bit = "yes" if os.path.isfile(bitstream) else "no"
        if pnr:
            lines.append(
                f"| {core} | {pnr.get('logic_cells', '-')} | {pnr.get('registers', '-')} | "
                f"{pnr.get('max_freq_mhz', '-')} | {has_bit} |"
            )
        elif yosys:
            lines.append(f"| {core} | {yosys.get('cells', '-')} | - | - | {has_bit} |")
        else:
            lines.append(f"| {core} | - | - | - | {has_bit} |")

    # Efficiency ranking
    ranked = []
    for core, meta, pnr, yosys in synth_rows:
        if pnr and pnr.get("logic_cells"):
            try:
                cells = int(str(pnr["logic_cells"]).replace(",", ""))
                ranked.append((core, cells, pnr.get("max_freq_mhz")))
            except ValueError:
                pass
    if ranked:
        ranked.sort(key=lambda x: x[1])
        lines += [
            "",
            "### Efficiency Ranking (lower logic cell count is better)",
            "",
        ]
        for i, (core, cells, fmax) in enumerate(ranked, 1):
            fmax_s = f", {fmax} MHz" if fmax else ""
            lines.append(f"{i}. **{core}** — {cells} logic cells{fmax_s}")

    lines += ["", MARKER_END, ""]
    return "\n".join(lines)


def update_readme(report_block):
    if not os.path.isfile(README):
        return
    with open(README) as f:
        content = f.read()
    if MARKER_START in content and MARKER_END in content:
        pattern = re.compile(re.escape(MARKER_START) + r".*?" + re.escape(MARKER_END), re.DOTALL)
        content = pattern.sub(report_block.strip(), content)
    else:
        content = content.rstrip() + "\n\n" + report_block
    with open(README, "w") as f:
        f.write(content)


def main():
    os.makedirs(RESULTS, exist_ok=True)
    report = build_report()
    os.makedirs(os.path.join(RESULTS, "_reports"), exist_ok=True)
    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    with open(os.path.join(RESULTS, "_reports", f"report_{stamp}.md"), "w") as f:
        f.write(report)
    update_readme(report)
    print("Report updated in README.md")


if __name__ == "__main__":
    main()
