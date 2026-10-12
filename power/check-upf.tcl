read_lef /OpenROAD-flow-scripts/flow/platforms/nangate45/lef/NangateOpenCellLibrary.tech.lef
read_lef /OpenROAD-flow-scripts/flow/platforms/nangate45/lef/NangateOpenCellLibrary.macro.mod.lef
read_liberty /OpenROAD-flow-scripts/flow/platforms/nangate45/lib/NangateOpenCellLibrary_typical.lib
read_verilog /workspace/build/power/shell.v
link_design rv32i_power_shell
read_upf -file /workspace/power/cpu.upf
write_upf /workspace/build/power/roundtrip.upf
puts "PASS UPF read/write for CPU output-isolation intent"
exit
