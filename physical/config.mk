export DESIGN_NAME = rv32i_core
export PLATFORM = nangate45
export VERILOG_FILES = /workspace/rtl/rv32i_core.sv
export SDC_FILE = /workspace/physical/constraints.sdc
export CORE_UTILIZATION = 35
export CORE_ASPECT_RATIO = 1
export CORE_MARGIN = 5
export PLACE_DENSITY_LB_ADDON = 0.20
export TNS_END_PERCENT = 100
export NUM_CORES = 2
export SYNTH_REPEATABLE_BUILD = 1
# Both variants use identical RTL, clocks, I/O constraints and floorplan settings.
export ABC_AREA = $(if $(filter area,$(FLOW_VARIANT)),1,0)
