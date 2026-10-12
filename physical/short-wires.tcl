# Bound long input/clock-root wires before routing. This is a repair experiment;
# the extracted KLayout antenna checks remain the acceptance test.
estimate_parasitics -placement
repair_clock_nets -max_wire_length 30
repair_design -max_wire_length 30 -cap_margin 15
# Legalize newly inserted buffers before global routing.
detailed_placement
