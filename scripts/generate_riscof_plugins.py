#!/usr/bin/env python3
"""Generate RISCOF DUT plugin and config for tournament cores."""

import argparse
import os
import shutil

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
CORES = os.path.join(ROOT, "cores")
FRAMEWORK_TESTS = os.path.join(ROOT, "framework", "tests")
ENV_TEMPLATE = os.path.join(FRAMEWORK_TESTS, "plugins", "env")


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
    meta.setdefault("top_module", "core_top")
    meta.setdefault("simulator", "iverilog")
    meta.setdefault("riscof_dmem_size", "65540")
    return meta


def sim_command(core_name, core_dir, simulator, riscof_dmem_size=65540, hdl="Verilog"):
    if simulator == "iverilog":
        if hdl == "TL-Verilog":
            # TL-Verilog: compile with sandpiper-saas first
            return f"""
cd WORK_DIR && \\
  IMEM_WORDS=$$(wc -l < ./files/text.txt); \\
  IMEM_SIZE=1; \\
  while [ $$IMEM_SIZE -lt $$IMEM_WORDS ]; do IMEM_SIZE=$$((IMEM_SIZE * 2)); done; \\
  if [ $$IMEM_SIZE -lt 8192 ]; then IMEM_SIZE=8192; fi; \\
  if [ $$IMEM_SIZE -lt 4 ]; then IMEM_SIZE=4; fi; \\
  while [ $$(wc -l < ./files/text.txt) -lt $$IMEM_SIZE ]; do echo 00000000 >> ./files/text.txt; done; \\
  DMEM_SIZE={riscof_dmem_size}; \\
  echo "IMEM_SIZE=$$IMEM_SIZE DMEM_SIZE=$$DMEM_SIZE (text words=$$IMEM_WORDS)"; \\
  mkdir -p gen/support/src gen/support/include gen/support/peripherals gen/support/tb; \\
  cp {core_dir}/../verilog/rtl/src/register_file.v gen/support/src/; \\
  cp -r {core_dir}/../verilog/rtl/include/* gen/support/include/; \\
  cp -r {core_dir}/../verilog/rtl/peripherals/* gen/support/peripherals/; \\
  cp -r {core_dir}/../verilog/rtl/tb/* gen/support/tb/; \\
  cp {core_dir}/rtl/tb/testbench_debug.v gen/support/tb/testbench.v 2>/dev/null || true; \\
  sandpiper-saas -i {core_dir}/rtl/rv32i_plh.tlv -o rv32i_plh.v --outdir gen --reset0 --clkAlways --inlineGen --noline > /dev/null 2>&1 || test -f gen/rv32i_plh.v; \\
  VVP_FLAGS=""; \\
  if [ "$$DEBUG_VCD" = "1" ]; then VVP_FLAGS="+debug"; fi; \\
  iverilog -g2005-sv -DSIMULATION -Igen -Igen/support/include -y{core_dir}/rtl -ygen/support/peripherals -ygen/support/src \\
    -Ptestbench.IMEM_SIZE=$$IMEM_SIZE -Ptestbench.DMEM_SIZE=$$DMEM_SIZE \\
    -Ptestbench.SIM_TIMEOUT=0 \\
    gen/rv32i_plh.v {core_dir}/rtl/instruction_memory_fast.v {core_dir}/rtl/data_memory_fast.v gen/support/tb/testbench.v -o sim.vvp && \\
  timeout 30 vvp sim.vvp $$VVP_FLAGS && \\
  mv DUT-verilog.signature DUT-{core_name}.signature 2>/dev/null || true; \\
  tr 'A-F' 'a-f' < DUT-{core_name}.signature > DUT-{core_name}.signature.tmp && \\
  mv DUT-{core_name}.signature.tmp DUT-{core_name}.signature
""".strip()
        else:
            # Standard Verilog
            return f"""
cd WORK_DIR && \\
  IMEM_WORDS=$$(wc -l < ./files/text.txt); \\
  IMEM_SIZE=1; \\
  while [ $$IMEM_SIZE -lt $$IMEM_WORDS ]; do IMEM_SIZE=$$((IMEM_SIZE * 2)); done; \\
  if [ $$IMEM_SIZE -lt 8192 ]; then IMEM_SIZE=8192; fi; \\
  if [ $$IMEM_SIZE -lt 4 ]; then IMEM_SIZE=4; fi; \\
  while [ $$(wc -l < ./files/text.txt) -lt $$IMEM_SIZE ]; do echo 00000000 >> ./files/text.txt; done; \\
  DMEM_SIZE={riscof_dmem_size}; \\
  echo "IMEM_SIZE=$$IMEM_SIZE DMEM_SIZE=$$DMEM_SIZE (text words=$$IMEM_WORDS)"; \\
  iverilog -g2012 -DSIMULATION -I{core_dir}/rtl/include -y{core_dir}/rtl/peripherals \\
    -Ptestbench.IMEM_SIZE=$$IMEM_SIZE -Ptestbench.DMEM_SIZE=$$DMEM_SIZE \\
    -Ptestbench.SIM_TIMEOUT=0 \\
    {core_dir}/rtl/src/*.v {core_dir}/rtl/tb/testbench.v -o sim.vvp && \\
  vvp sim.vvp && \\
  tr 'A-F' 'a-f' < DUT-{core_name}.signature > DUT-{core_name}.signature.tmp && \\
  mv DUT-{core_name}.signature.tmp DUT-{core_name}.signature
""".strip()
    raise SystemExit(f"Unsupported simulator: {simulator}")


def write_plugin(core_name, meta, plugin_dir, core_dir):
    os.makedirs(os.path.join(plugin_dir, "env"), exist_ok=True)
    plugin_class = core_name.replace("-", "_")
    sim_cmds = sim_command(
        core_name,
        core_dir,
        meta.get("simulator", "iverilog"),
        int(meta.get("riscof_dmem_size", 65540)),
        meta.get("hdl", "Verilog"),
    )

    plugin_py = f'''import os
import logging
import riscof.utils as utils
from riscof.pluginTemplate import pluginTemplate

logger = logging.getLogger()

class {plugin_class}(pluginTemplate):
    __model__ = "{core_name}"
    __version__ = "1.0.0"

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        config = kwargs.get("config")
        if config is None:
            raise SystemExit("Missing plugin config")
        self.num_jobs = str(config.get("jobs", 1))
        self.timeout = int(config.get("timeout", 3600))
        self.pluginpath = os.path.abspath(config["pluginpath"])
        self.isa_spec = os.path.abspath(config["ispec"])
        self.platform_spec = os.path.abspath(config["pspec"])
        self.target_run = config.get("target_run", "1") != "0"
        self.core_dir = r"{core_dir}"
        self.sim_template = {repr(sim_cmds)}

    def initialise(self, suite, work_dir, archtest_env):
        self.work_dir = work_dir
        self.suite_dir = suite
        # Use absolute paths to toolchain wrappers in framework/bin
        toolchain_dir = os.path.abspath(os.path.join(self.core_dir, "../../framework/bin"))
        self.compile_cmd = (
            toolchain_dir + "/riscv%s-unknown-elf-gcc -g -march=%s "
            "-static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles "
            "-T " + self.pluginpath + "/env/link.ld "
            "-I " + self.pluginpath + "/env/ "
            "-I " + archtest_env + " %s -o dut.elf %s"
        )
        self.text_copy_cmd = (
            "rm -rf ./files; mkdir ./files; "
            + toolchain_dir + "/riscv%s-unknown-elf-objcopy -O binary -j .text.init -j .text dut.elf dut.text.bin --strip-debug; "
            "od -t x4 -An -w4 -v dut.text.bin | tr -d \\" \\" > ./files/text.txt"
        )
        self.data_copy_cmd = (
            toolchain_dir + "/riscv%s-unknown-elf-objcopy -O binary -j .data -j .data.string dut.elf dut.data.bin --strip-debug; "
            "od -t x4 -An -w4 -v dut.data.bin | tr -d \\" \\" > data.hex.txt; "
            "awk 'BEGIN {{ addr=268439552; }} {{ printf(\\"%%08x %%s\\\\n\\", addr, $$0); addr += 4; }}' data.hex.txt > ./files/data.txt"
        )

    def build(self, isa_yaml, platform_yaml):
        ispec = utils.load_yaml(isa_yaml)["hart0"]
        self.xlen = "64" if 64 in ispec["supported_xlen"] else "32"
        self.isa = "rv" + self.xlen
        for ext in "IMFDC":
            if ext in ispec["ISA"]:
                self.isa += ext.lower()
        self.compile_cmd += " -mabi=" + ("lp64 " if self.xlen == "64" else "ilp32 ")

    def runTests(self, testList):
        make = utils.makeUtil(makefilePath=os.path.join(self.work_dir, "Makefile." + self.name[:-1]))
        make.makeCommand = "make -k -j" + self.num_jobs
        for testname in testList:
            testentry = testList[testname]
            macros = testentry.get("macros", [])
            if isinstance(macros, list) and macros:
                compile_macros = " -D" + " -D".join(macros)
            else:
                compile_macros = ""
            cmd = self.compile_cmd % (self.xlen, testentry["isa"].lower(), testentry["test_path"], compile_macros)
            cmd_text = self.text_copy_cmd % self.xlen
            cmd_data = self.data_copy_cmd % self.xlen
            work = testentry["work_dir"]
            if self.target_run:
                simcmd = self.sim_template.replace("WORK_DIR", work)
                execute = f"cd {{work}}; {{cmd}}; {{cmd_text}}; {{cmd_data}}; {{simcmd}}"
                make.add_target(execute)
        make.execute_all(self.work_dir, timeout=self.timeout)
        if not self.target_run:
            raise SystemExit(0)
'''

    with open(os.path.join(plugin_dir, f"riscof_{core_name}.py"), "w") as f:
        f.write(plugin_py)
    with open(os.path.join(plugin_dir, "__init__.py"), "w") as f:
        f.write("")

    shutil.copy(os.path.join(ENV_TEMPLATE, "link.ld"), os.path.join(plugin_dir, "env", "link.ld"))
    shutil.copy(os.path.join(ENV_TEMPLATE, "model_test.h"), os.path.join(plugin_dir, "env", "model_test.h"))

    with open(os.path.join(plugin_dir, f"{core_name}_isa.yaml"), "w") as f:
        f.write("""hart_ids: [0]
hart0:
  ISA: RV32I
  physical_addr_sz: 32
  User_Spec_Version: '2.3'
  supported_xlen: [32]
""")
    with open(os.path.join(plugin_dir, f"{core_name}_platform.yaml"), "w") as f:
        f.write("""mtime:
  implemented: false
mtimecmp:
  implemented: false
nmi:
  label: nmi_vector
reset:
  label: reset_vector
""")


def write_config_ini(cores, dut_core=None):
    if dut_core is None:
        dut_core = next((c for c in cores if not c.startswith("_")), "verilog")
    
    # Get absolute path to framework/bin for Sail wrappers
    framework_bin = os.path.abspath(os.path.join(FRAMEWORK_TESTS, "../bin"))
    
    lines = [
        "[RISCOF]",
        "ReferencePlugin=sail_cSim",
        "ReferencePluginPath=sail_cSim",
        f"DUTPlugin={dut_core}",
        f"DUTPluginPath={dut_core}",
        "",
        "[sail_cSim]",
        "pluginpath=sail_cSim",
        f"PATH={framework_bin}",
        "",
    ]
    for core in cores:
        if core.startswith("_"):
            continue
        lines += [
            f"[{core}]",
            f"pluginpath={core}",
            f"ispec={core}/{core}_isa.yaml",
            f"pspec={core}/{core}_platform.yaml",
            f"dutpath=../../cores/{core}",
            "target_run=1",
            "timeout=7200",
            "jobs=4",
            "",
        ]
    config_path = os.path.join(FRAMEWORK_TESTS, "config.ini")
    with open(config_path, "w") as f:
        f.write("\n".join(lines))
    return config_path


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--core", help="Set active DUT core in config.ini")
    args = parser.parse_args()

    all_cores = sorted(
        d for d in os.listdir(CORES)
        if os.path.isdir(os.path.join(CORES, d)) and not d.startswith("_")
    )

    for core_name in all_cores:
        core_dir = os.path.join(CORES, core_name)
        meta = load_core_meta(core_dir)
        plugin_dir = os.path.join(FRAMEWORK_TESTS, core_name)
        if os.path.isdir(plugin_dir):
            shutil.rmtree(plugin_dir)
        write_plugin(core_name, meta, plugin_dir, core_dir)
        print(f"Generated plugin for {core_name}")

    dut = args.core or (all_cores[0] if all_cores else None)
    cfg = write_config_ini(all_cores, dut_core=dut)
    print(f"Wrote {cfg} (DUT={dut})")


if __name__ == "__main__":
    main()
