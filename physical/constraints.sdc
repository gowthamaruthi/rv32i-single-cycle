current_design rv32i_core
# Standalone core budget, not a characterized external SRAM model.
create_clock -name core_clk -period 10.0 [get_ports clk]
set_clock_uncertainty 0.10 [get_clocks core_clk]
set_input_delay -max 2.0 -clock core_clk [all_inputs -no_clocks]
set_input_delay -min 0.10 -clock core_clk [all_inputs -no_clocks]
set_output_delay -max 2.0 -clock core_clk [all_outputs]
set_output_delay -min 0.10 -clock core_clk [all_outputs]
set_input_transition 0.10 [all_inputs -no_clocks]
set_load 0.010 [all_outputs]
# Reset is synchronous and remains timed. No false/multicycle paths.
