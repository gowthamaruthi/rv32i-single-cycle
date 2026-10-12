#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build/power
iverilog -g2012 -s tb_power -o build/power/test.vvp rtl/rv32i_core.sv power/rv32i_power_shell.sv power/tb_power.sv
vvp build/power/test.vvp | tee build/power/simulation.log
yosys -Q -T -p 'read_verilog -sv rtl/rv32i_core.sv power/rv32i_power_shell.sv; hierarchy -check -top rv32i_power_shell; synth -top rv32i_power_shell; check -assert; write_verilog -noattr build/power/shell.v' > build/power/synthesis.log
