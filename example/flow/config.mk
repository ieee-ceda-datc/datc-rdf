export DESIGN_NICKNAME        = riscv-mini
export DESIGN_NAME            = Core_0_obf
export PLATFORM               = sky130hd

export VERILOG_FILES          = $(sort $(wildcard ../assure/out/hdl/*.v))
export SDC_FILE               = ./constraint.sdc

export CORE_UTILIZATION       = 20
export CORE_ASPECT_RATIO      = 1
export CORE_MARGIN            = 2

export PLACE_DENSITY          = 0.6
export ABC_CLOCK_PERIOD_IN_PS = 100000
