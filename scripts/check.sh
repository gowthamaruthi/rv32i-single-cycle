#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
{ python3 --version; iverilog -V 2>&1 | sed -n '1p'; verilator --version; yosys -V; } > build/versions.txt
verilator --lint-only -Wall rtl/rv32i_core.sv 2>&1 | tee build/lint.log
python3 -u scripts/regress.py | tee build/regression.log
yosys -p 'read_verilog -sv rtl/rv32i_core.sv; hierarchy -check -top rv32i_core; synth -top rv32i_core; check -assert; stat; write_json build/synthesis.json' > build/synthesis.log
python3 scripts/mutations.py | tee build/mutations.log
