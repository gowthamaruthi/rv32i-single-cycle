#!/usr/bin/env bash
set -euo pipefail
source /OpenROAD-flow-scripts/env.sh
cd /workspace
mkdir -p build/power
lib=/OpenROAD-flow-scripts/flow/platforms/nangate45/lib/NangateOpenCellLibrary_typical.lib
yosys -Q -T -p "read_verilog -sv rtl/rv32i_core.sv power/rv32i_power_shell.sv; hierarchy -check -top rv32i_power_shell; synth -top rv32i_power_shell; dfflibmap -liberty $lib; abc -liberty $lib; clean; write_verilog -noattr build/power/shell.v" > build/power/mapping.log
openroad -exit power/check-upf.tcl | tee build/power/upf.log
