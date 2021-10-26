suppress_message { VER-130 }

source ./config.tcl

set OUT_DIR ./out
# Reports and logs directories creation
file mkdir ${OUT_DIR}
set REPORTS_DIR "${OUT_DIR}/rpts"
set RESULTS_DIR "${OUT_DIR}/results"
set LOGS_DIR     "${OUT_DIR}/logs"

# Added if you run Formality
set_svf ${OUT_DIR}/${TOP_DESIGN}.svf
file mkdir ${REPORTS_DIR}
file mkdir ${RESULTS_DIR}
file mkdir ${LOGS_DIR}

# Shorten long module names
set_app_var hdlin_shorten_long_module_name true
set_app_var hdlin_module_name_limit 256

# Library and Search Path variables */
#- add $search_path , use "" instead of list []
set_app_var search_path ". $search_path"

# Path to Memories here

# Specify synthetic_library, since using compile_ultra
#put $target_library first
set_app_var synthetic_library dw_foundation.sldb
set_app_var link_library "* \
                       $target_library \
                       $synthetic_library"
#set symbol_library = {}

# Add so that the synopsys_cache_XXX directory is in the directory where synthesis is run
set_app_var cache_read         ${OUT_DIR}
set_app_var cache_write        ${OUT_DIR}
set alib_library_analysis_path ${ALIB_DIR}

#${TOP_DESIGN}_file.list contains all of the design files

# Add this so analyzed files are all in one directory
define_design_lib work -path ${OUT_DIR}/work

# Comment in order read in elab DC
analyze -format sverilog -vcs "-f ${FILE_LIST}"
#read_ddc ${TOP_DESIGN}.elab.ddc
elaborate ${TOP_DESIGN}
# No need to have set in front of current_design
current_design ${TOP_DESIGN}

link

check_design > ./${LOGS_DIR}/check_design_pre.log

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
set_clock_uncertainty -setup ${CLK_UNC_SETUP} [get_clocks ${CLK_NAME}]
set_clock_uncertainty -hold  ${CLK_UNC_HOLD} [get_clocks ${CLK_NAME}]

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
compile_ultra

optimize_netlist -area

report_qor > ${REPORTS_DIR}/${TOP_DESIGN}_qor.rpt

report_area -nosplit > ${REPORTS_DIR}/area_no_split.rpt
report_area -hierarchy > ${REPORTS_DIR}/area_hierarchy.rpt

check_design > ./${LOGS_DIR}/check_design_post.log

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
