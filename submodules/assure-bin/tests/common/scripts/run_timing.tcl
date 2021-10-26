set TOP_DESIGN "ethmac_0_obf"
set CLK_NAME "wb_clk_i"

# Clock period is 10000 ps or 10 ns which is 100MHz
set CLOCK_PERIOD 10000

# Reports and logs directories creation
set REPORTS_DIR "./rpts"
set RESULTS_DIR "./results"
set LOGS_DIR "./logs"

# Added if you run Formality
set_svf ${TOP_DESIGN}.svf
file mkdir ${REPORTS_DIR}
file mkdir ${RESULTS_DIR}
file mkdir ${LOGS_DIR}

# Shorten long module names
set_app_var hdlin_shorten_long_module_name true
set_app_var hdlin_module_name_limit 256

# Library and Search Path variables */
#- add $search_path , use "" instead of list []
set_app_var search_path ". $search_path"

# Target library
#set_app_var target_library "/project/ssed/dig_lib/global/gf14lpp/arm/gf/14lppxl/sc9mcpp84_base_rvt_c14/r0p0/db/sc9mcpp84_14lppxl_base_rvt_c14_nn_nominal_max_0p80v_25c.db"
set_app_var target_library "/home/abc586/techLibrary/nanGate_15nm_Library/synopsysUsage/front_end_library/lib/NanGate_15nm_OCL_fast_conditional_ccs.db"

# Path to Memories here

# Specify synthetic_library, since using compile_ultra
#put $target_library first
set_app_var synthetic_library dw_foundation.sldb
set_app_var link_library "* \
                       $target_library \
                       $synthetic_library"
#set symbol_library = {}

# Add so that the synopsys_cache_XXX directory is in the directory where synthesis is run
set_app_var cache_read ./
set_app_var cache_write ./

#${TOP_DESIGN}_file.list contains all of the design files

# Add this so analyzed files are all in one directory
define_design_lib work -path ./work

# Comment in order read in elab DC
analyze -format sverilog -vcs "-f files.f"
#read_ddc ${TOP_DESIGN}.elab.ddc
elaborate ${TOP_DESIGN}
# No need to have set in front of current_design
current_design ${TOP_DESIGN}

link

check_design > ./${LOGS_DIR}/check_design.log

#write -hierarchy -format ddc -output ${RESULTS_DIR}/${TOP_DESIGN}.elab.ddc

set EXT_DELAY [expr $CLOCK_PERIOD * 0.2]

# Defining basic parameters
set_max_fanout 10 [current_design]
set_max_transition 150 [current_design]
set_max_area 0
set_load -pin_load 1.844 [all_outputs]

# These clocks come from the PLL, but since we don't have
# a PLL in the design, just treat them the same to get a
# rough estimate on the gate count.

# Main clock
create_clock [get_ports ${CLK_NAME}] -period $CLOCK_PERIOD
set_clock_uncertainty -setup 200 [get_clocks ${CLK_NAME}]
set_clock_uncertainty -hold  20  [get_clocks ${CLK_NAME}]

# This design sits on the lower level of the big file
# that was used for FPGA build, there are a lot of tied 0 / tied 1
# this would cause certain logic to be optimized out. Use the
# don't touch to prevent logic from optimizing out for a more conservative
# gate count.

# set_dont_touch [all_inputs]

# Start compilation and mapping

#- to remove assign statement
set_fix_multiple_port_nets -all -buffer

#- added clock-gating and multicore
set_host_options -max_cores 8

#compile_ultra -gate_clock
set_app_var compile_timing_high_effort_tns true
compile_ultra

#compile_ultra -retime
#optimize_netlist -area

report_qor > ${REPORTS_DIR}/${TOP_DESIGN}_qor.rpt

report_area -nosplit > ${REPORTS_DIR}/area_no_split.rpt

#- not needed, since not running DC Topographical, where you would need to read in the Milkyway Reference libraries
#report_congestion > ${REPORTS_DIR}/congestion.rpt

#- added -verbose
#report_power -verbose -nosplit –scenario [all_scenarios] > ${REPORTS_DIR}/power.rpt
report_power -verbose -nosplit > ${REPORTS_DIR}/${TOP_DESIGN}_power.rpt

#report_clock_gating -nosplit > ${REPORTS_DIR}/clock_gating.rpt

report_timing -delay max -max_paths 500 -nosplit -nets -transition_time -input_pins > ${REPORTS_DIR}/max_timing.rpt
report_reference -nosplit -hier > ${REPORTS_DIR}/reference.rpt

#- add
change_names -rules verilog -hier
# Writing out synthesized design
write -format verilog -hierarchy -output ${RESULTS_DIR}/${TOP_DESIGN}_mapped.v
write -hierarchy -format ddc -output ${RESULTS_DIR}/${TOP_DESIGN}.final.ddc

exit
