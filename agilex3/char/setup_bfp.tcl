# Standalone fit of bfp_dot (paper's tensor cascade without the MXFP decoder), same SDC as mxfp_dot.
# argv: PROJ REV FAMILY DEVICE PIPE UPSTREAM_AITB_DIR BOARD_RTL_DIR
package require ::quartus::project
lassign $argv PROJ REV FAMILY DEVICE PIPE UP BR
if {[project_exists $PROJ]} { project_open -revision $REV $PROJ } else { project_new -revision $REV $PROJ }
set_global_assignment -name FAMILY $FAMILY
set_global_assignment -name DEVICE $DEVICE
set_global_assignment -name SYSTEMVERILOG_FILE [file normalize $UP/rtl/fp_aitb.sv]
set_global_assignment -name SYSTEMVERILOG_FILE [file normalize $UP/rtl/pipeline.sv]
set_global_assignment -name SYSTEMVERILOG_FILE [file normalize $BR/bfp_dot.sv]
set_global_assignment -name SDC_FILE [file normalize $UP/cons/mxfp_dot.sdc]
set_global_assignment -name TOP_LEVEL_ENTITY bfp_dot
set_global_assignment -name NUM_PARALLEL_PROCESSORS 6
set_global_assignment -name PROJECT_OUTPUT_DIRECTORY "output_files_${REV}"
set_instance_assignment -name VIRTUAL_PIN ON -to * -entity bfp_dot
set_parameter -name PIPE $PIPE
set_global_assignment -name MIN_CORE_JUNCTION_TEMP 0
set_global_assignment -name MAX_CORE_JUNCTION_TEMP 100
export_assignments
project_close
