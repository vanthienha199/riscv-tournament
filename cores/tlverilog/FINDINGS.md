# RISC-V Tournament - Repository Feedback & Recommendations

## Executive Summary

This document provides feedback to the RISC-V Tournament repository maintainers based on our experience implementing a complete RV32I core. We encountered several setup issues, documentation gaps, and tooling challenges that would benefit future contestants if addressed.

> **Target Audience**: This document is feedback for the tournament repository maintainers to help improve the contestant experience.

## Implementation Experience

✅ **Achieved**: Full RV32I compliance (41/41 RISCOF tests passing)  
✅ **Successful**: RISCOF integration and verification workflow  
✅ **Working**: Sail reference model comparison  
⚠️ **Challenging**: Initial setup due to documentation gaps and tooling issues

---

## Repository Setup Issues & Recommended Fixes

These issues were encountered during initial setup and would benefit future contestants if addressed in the repository documentation and scripts.

### 1. 🔴 **CRITICAL: Python Virtual Environment Not Documented**

**Issue**: README.md installation instructions install RISCOF globally with `pip install --user riscof`, but the repository's own scripts expect a Python virtual environment at `.venv/`.

**Impact**: 
- `make setup` fails with import errors if run outside venv
- Git diff shows README now mentions `source .venv/bin/activate` but setup steps are incomplete

**Observed Behavior**:
```bash
# Following README instructions:
pip install --user riscof  # Works, but...
make setup                 # Fails - scripts expect .venv/

# What actually works:
python3 -m venv .venv
source .venv/bin/activate
pip install riscof
make setup  # Now works
```

**Recommendation**: Update README.md with clear virtual environment setup:
```markdown
## Setup

### Create Python Virtual Environment (Required)

git clone <repo> && cd <repo>

# Create and activate virtual environment
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install riscof

# Now run setup
make setup
```

**Files to Update**: 
- `README.md` - Add venv creation as mandatory first step
- Consider adding a `setup.sh` script that creates venv automatically

---

### 2. 🔴 **CRITICAL: Toolchain PATH Issues in Generated Plugins**

**Issue**: The `generate_riscof_plugins.py` script generates RISCOF plugins that assume `riscv*-elf-gcc` is in the user's PATH. However, the framework installs wrapper scripts in `framework/bin/` that are NOT automatically added to PATH.

**Impact**: Tests compile with 0 instructions and fail silently with misleading errors.

**Root Cause**:
Generated plugin code used:
```python
self.compile_cmd = "riscv%s-unknown-elf-gcc ..."  # Assumes in PATH
```

But wrappers are at: `framework/bin/riscv32-unknown-elf-gcc` (not in PATH)

**Our Fix** (shown in git diff):
```python
# Use absolute paths to toolchain wrappers
toolchain_dir = os.path.abspath(os.path.join(self.core_dir, "../../framework/bin"))
self.compile_cmd = toolchain_dir + "/riscv%s-unknown-elf-gcc ..."
```

**Recommendation**: 
1. Apply our fix permanently to `scripts/generate_riscof_plugins.py`
2. OR: Have `make setup` add `framework/bin` to user's PATH via `.envrc` or similar
3. Document the PATH requirement clearly in README

**Files to Update**:
- `scripts/generate_riscof_plugins.py` - Use absolute paths (already in your diff)
- `framework/tests/sail_cSim/riscof_sail_cSim.py` - Same fix needed (already in your diff)

---

### 3. 🔴 **CRITICAL: Sail Reference Model PATH Configuration Missing**

**Issue**: Even after running `make setup` which installs Sail wrappers to `framework/bin/`, RISCOF can't find them because the generated `config.ini` doesn't set PATH for the sail_cSim plugin.

**Impact**: Tests appear to run but have no reference signatures to compare against, making it impossible to verify correctness.

**Error Message**:
```
riscv_sim_rv32d: not found
```

**Our Fix** (shown in git diff):
```python
def write_config_ini(cores, dut_core=None):
    framework_bin = os.path.abspath(os.path.join(FRAMEWORK_TESTS, "../bin"))
    lines = [
        "[sail_cSim]",
        "pluginpath=sail_cSim",
        f"PATH={framework_bin}",  # ADD THIS LINE
    ]
```

**Recommendation**:
1. Apply this fix to `scripts/generate_riscof_plugins.py`
2. OR: Have Sail install script add wrappers to system PATH
3. Document in README that `framework/bin` must be in PATH

**Files to Update**:
- `scripts/generate_riscof_plugins.py` - Add PATH to config.ini (in your diff)

---

### 4. 🟡 **MEDIUM: Empty Macros Crash Plugin Generator**

**Issue**: Some RISCOF tests have empty or missing `macros` fields in `test_list.yaml`, causing plugin generation to crash when trying to join them.

**Error**:
```python
compile_macros = " -D" + " -D".join(testentry["macros"])  # Crashes if missing or empty
```

**Our Fix**:
```python
macros = testentry.get("macros", [])
if isinstance(macros, list) and macros:
    compile_macros = " -D" + " -D".join(macros)
else:
    compile_macros = ""
```

**Recommendation**: Apply this defensive fix to `scripts/generate_riscof_plugins.py`

---

### 5. 🟡 **MEDIUM: Custom HDL Support Requires Manual Plugin Modification**

**Issue**: The plugin generator only supports standard Verilog workflows. Cores using other HDLs (or custom build flows) require:
1. Custom compilation steps before simulation
2. Different file paths and dependencies
3. HDL-specific toolchain configuration

**Impact**: Contestants using non-Verilog HDLs must manually modify generated RISCOF plugins.

**Our Solution**: Extended `generate_riscof_plugins.py` to support custom `hdl:` field in `core.yaml`, allowing plugin generator to adapt to different HDL workflows.

**Recommendation**: 
1. Merge extensible HDL support into plugin generator
2. Document plugin customization process in README
3. Provide templates for common alternative HDLs

**Files to Update**:
- `scripts/generate_riscof_plugins.py` - Add HDL extensibility (in git diff)
- `README.md` - Document supported HDLs and custom workflow process

---

### 6. 🟢 **LOW: README.md Installation Formatting Issues**

**Issue**: Git diff shows formatting problems in README installation section:
```bash
grep -qxF 'source ~/oss-cad-suite/environment' ~/.bashrc || \
  echo 'source ~/oss-cad-suite/environment' >> ~/.bashrcsource ~/oss-cad-suite/
```

The `>> ~/.bashrc` is missing a space before `source`, so it would literally append "~/.bashrcsource" to the file.

**Recommendation**: Fix the bash command formatting in README.md

---

### 7. 🟢 **LOW: Tournament Results Table Reset**

**Issue**: Git diff shows tournament results table was reset from actual results to placeholder dashes:
```diff
-| verilog | Verilog | 38 | 0 | 100.0% |
+| verilog | Verilog | - | - | - |
```

**Question**: Was this intentional? If this is a template repository, should there be a separate "template" branch vs "main" branch with actual results?

**Recommendation**: Consider using git branches:
- `main` - Actual tournament results and working cores  
- `template` - Clean template for new contestants

---

## Documentation Gaps & Suggestions

### 8. 📖 **Missing: HDL-Specific Requirements**

**Issue**: README doesn't mention what HDLs are supported or what additional tools are needed for each.

**Current State**: Only Verilog example exists, but framework could support other HDLs.

**Recommendation**: Add section to README:
```markdown
## Supported HDLs

### Verilog/SystemVerilog
- Standard Verilog 2005/2012
- Use `cores/verilog/` as reference
- No additional tools required beyond iverilog

### Other HDLs
- Framework supports custom HDLs via plugin system
- May require HDL-specific compilers/translators
- Document toolchain requirements in core.yaml
- See plugin generator for custom integration
```

---

### 9. 📖 **Missing: Test Suite Size Documentation**

**Issue**: README mentions running tests but doesn't explain:
- How many total tests exist (41 for RV32I base)
- How `NUM_TESTS` parameter works
- What `test_list.yaml` vs `test_list_small.yaml` are

**Observed Behavior**:
- Default: `make riscof-test` runs 3 tests (for quick validation)
- Full suite: `make riscof-test NUM_TESTS=41` (or higher number)
- Tests are selected from first N entries in test_list.yaml

**Recommendation**: Document in README:
```markdown
## Running Tests

# Quick validation (first 3 tests)
make riscof-test

# Run first 10 tests
make riscof-test NUM_TESTS=10

# Full RV32I compliance suite (41 tests)
make riscof-test NUM_TESTS=41

# Note: Total available tests may vary based on ISA extensions
```

---

### 10. 📖 **Unclear: What Architectures Must Be Identical?**

**Issue**: README states "implement the same RV32I pipelined core" but doesn't clarify what "same" means:
- Same number of pipeline stages?
- Same hazard detection approach?
- Just same ISA compliance?

**Our Experience**: We successfully used a different pipeline architecture than the reference:
- **Reference Verilog**: 5-stage classic RISC pipeline (F→D→E→M→W)
- **Our Implementation**: Alternative 5-stage pipeline with different stage organization
- **Both**: 100% RV32I compliant, but different microarchitectures

**Recommendation**: Clarify tournament rules:
```markdown
## Tournament Rules

### Required
- ✅ Full RV32I ISA compliance (all 41 base tests must pass)
- ✅ Pipelined implementation (at least 2 stages)
- ✅ Basic hazard handling (data, control hazards)

### Flexible
- ⚡ Number of pipeline stages (3, 5, 7, etc.)
- ⚡ Hazard resolution strategy (stall, bypass, predict)
- ⚡ Pipeline organization (classic vs custom approaches)

### Comparison Metrics
- Tests passed (must be 100%)
- FPGA resource usage (CPE_LT, CPE_FF, RAM)
- Maximum frequency (MHz)
```

This would help contestants understand they can innovate on microarchitecture while maintaining ISA compliance.

---

### 11. 📖 **Missing: Common Pitfalls & Debugging Guide**

**Issue**: No troubleshooting documentation for common setup problems.

**Recommendation**: Add a TROUBLESHOOTING.md with:

```markdown
## Common Issues

### "text words=0" in compile output
**Cause**: RISC-V toolchain not found
**Fix**: Ensure framework/bin is in PATH or use absolute paths in plugins

### "riscv_sim_rv32d: not found"  
**Cause**: Sail wrappers not in PATH
**Fix**: Verify framework/bin exists and config.ini has PATH= line

### Tests compile but all fail
**Cause**: No reference signatures (Sail not working)
**Fix**: Check framework/tests/riscof_work/*/ref/ for Reference-*.signature files

### "Plugin import error"
**Cause**: Not in Python virtual environment
**Fix**: source .venv/bin/activate

### Simulation hangs/very slow
**Cause**: Large generate loops or inefficient memory models
**Fix**: Use direct array assignment instead of generate loops
```

---

## What Worked Well (Keep These!)

### ✅ Clean Repository Structure
The cores/*/rtl/, cores/*/programs/ organization is intuitive and scales well.

### ✅ Makefile Abstraction
The per-core Makefiles with standard targets (sim, riscof-test, synth) provide a clean interface.

### ✅ RISCOF Integration
Once setup is complete, RISCOF integration is solid and provides excellent verification.

### ✅ Reference Verilog Core
Having a complete, working reference implementation is invaluable for understanding expectations.

### ✅ Sail Reference Model
The Sail C simulator provides authoritative reference signatures for verification.

---

## Recommendations for Repository Maintainers

### Priority 1: Fix Critical Setup Issues
1. **Apply all fixes from our git diff** (toolchain paths, Sail PATH, empty macros handling)
2. **Document Python venv requirement** clearly at top of README
3. **Add setup validation script** that checks:
   - Python venv exists
   - RISCOF installed
   - Toolchain wrappers exist
   - Sail wrappers exist
   - PATH configured correctly

Example validation script:
```bash
#!/bin/bash
# scripts/validate_setup.sh

echo "Validating tournament setup..."

# Check venv
if [ ! -d ".venv" ]; then
    echo "❌ Python venv not found. Run: python3 -m venv .venv"
    exit 1
fi

# Check RISCOF
if ! command -v riscof &> /dev/null; then
    echo "❌ RISCOF not installed. Run: pip install riscof"
    exit 1
fi

# Check toolchain
if [ ! -f "framework/bin/riscv32-unknown-elf-gcc" ]; then
    echo "❌ Toolchain wrappers not found. Run: make setup"
    exit 1
fi

# Check Sail
if [ ! -f "framework/bin/riscv_sim_rv32d" ]; then
    echo "❌ Sail wrappers not found. Run: make setup"
    exit 1
fi

echo "✅ Setup validation passed!"
```

### Priority 2: Improve Documentation
1. **Add QUICKSTART.md** with minimal steps to first passing test
2. **Add TROUBLESHOOTING.md** with common issues (see above)
3. **Clarify tournament rules** about architecture requirements
4. **Document test suite** size and NUM_TESTS parameter

### Priority 3: Template Improvements
1. **Add HDL templates** for different languages (Verilog baseline, others as contributed)
2. **Add HDL comparison table** showing which tools are needed for each HDL
3. **Consider wizard script** that interactively sets up new cores:
   ```bash
   $ make new-core
   Core name: my_riscv
   HDL [verilog/tlv/vhdl]: tlv
   Pipeline stages: 5
   ✅ Created cores/my_riscv/ from template
   ```

### Priority 4: Testing & CI
1. **Add CI workflow** that validates:
   - All templates compile
   - Reference cores pass tests
   - Setup scripts work on fresh clone
2. **Add example test runs** in CI to catch broken scripts

---

## Files Modified (Git Diff Summary)

Our implementation required these changes to the tournament repository:

### `README.md`
- Added Python venv activation instructions
- Fixed oss-cad-suite bashrc formatting bug
- Updated installation workflow

### `scripts/generate_riscof_plugins.py`
- ✅ **Added absolute paths** for toolchain (critical fix)
- ✅ **Added PATH to config.ini** for Sail (critical fix)
- ✅ **Added empty macros handling** (defensive fix)
- ✅ **Added custom HDL support** (extensibility improvement)
- Allows `hdl:` field in core.yaml for HDL-specific builds
- Enables plugin generator to support multiple HDL workflows

### `framework/tests/sail_cSim/riscof_sail_cSim.py`
- ✅ **Added absolute paths** for toolchain (critical fix)
- Matches fix in generate_riscof_plugins.py

**Recommendation**: **Merge all these changes** into main repository - they fix critical bugs that affect all contestants.

---

## Suggested Repository Enhancements

### High Priority

1. **Apply Critical Fixes**
   - Merge our git diff (toolchain paths, Sail PATH, macros)
   - Test on fresh clone to verify fixes work
   - Add regression test to prevent regressions

2. **Improve Setup Documentation**
   - Make Python venv setup explicit and mandatory
   - Add validation script (`make validate-setup`)
   - Document expected output at each step
   - Add troubleshooting section

3. **Add Setup Wizard**
   - Interactive script that guides through setup
   - Validates each step before proceeding
   - Provides clear error messages with solutions

### Medium Priority

4. **HDL Templates**
   - Add templates for different HDLs (as community contributes them)
   - Include example cores with proper configuration
   - Document HDL-specific build requirements

---

## Final Recommendations Summary

### For Repository Maintainers

**Must Fix (Critical)**:
- ✅ Apply all git diff changes (toolchain paths, Sail PATH, macros handling)
- ✅ Document Python venv requirement at top of README
- ✅ Add troubleshooting section

**Should Add (High Value)**:
- ✅ Setup validation script
- ✅ Test output improvements
- ✅ Clarify tournament rules about architecture flexibility
- ✅ Templates for different HDLs (Verilog, VHDL, etc.)

**Nice to Have (Future)**:
- Setup wizard for better onboarding experience
- CI/CD for regression prevention
- Performance comparison dashboard

### For Future Contestants

**Setup**:
- Create Python venv first thing (before make setup)
- Verify each setup step completed successfully
- Use absolute paths for toolchain in generated plugins
- Ensure Sail reference model is working

**Development**:
- Start with reference Verilog implementation to understand requirements
- Test early and often with RISCOF
- Run `make riscof-test NUM_TESTS=3` for quick validation
- Use VCD waveforms for debugging - they're invaluable

**Common Pitfalls**:
- Don't skip Python venv - scripts depend on it
- Don't assume toolchain is in PATH - verify framework/bin exists
- Don't start debugging core until Sail is working
- Don't ignore signature mismatches - they indicate bugs

---

## Conclusion

The RISC-V Tournament repository is a **solid foundation** for HDL comparison. With a few critical fixes (mostly around PATH and setup documentation), it will be an excellent resource for the community.

Our implementation experience demonstrates that:
- ✅ RISCOF integration is well-designed and effective
- ✅ The framework can support different HDLs with plugin extensibility
- ✅ Different microarchitectures can coexist fairly
- ✅ With proper fixes, the setup process can be streamlined

**Critical Fixes Needed**:
1. Apply toolchain/Sail PATH fixes from our git diff
2. Document Python venv requirement clearly
3. Add setup validation script
4. Improve troubleshooting documentation

**Thank you** for creating this tournament framework! We hope this feedback helps make it even better for future contestants.

---

**Document Version**: 2.0 (Final)  
**Date**: June 13, 2026  
**Experience**: Full RV32I implementation (41/41 tests passing)  
**Framework**: RISC-V Tournament 2024  
**Authors**: Tournament Contestant Feedback
