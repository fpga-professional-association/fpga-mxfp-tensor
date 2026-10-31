# Retarget of upstream characterization/ai_tensor_block/syn/setup.tcl.
# argv: PROJ REV FAMILY DEVICE E M PIPE UPSTREAM_DIR
package require ::quartus::project
set PROJ   [lindex $argv 0]
set REV    [lindex $argv 1]
set FAMILY [lindex $argv 2]
set DEVICE [lindex $argv 3]
set E      [lindex $argv 4]
set M      [lindex $argv 5]
set PIPE   [lindex $argv 6]
set UP     [lindex $argv 7]
if {[project_exists $PROJ]} { project_open -revision $REV $PROJ } else { project_new -revision $REV $PROJ }
set_global_assignment -name FAMILY $FAMILY
set_global_assignment -name DEVICE $DEVICE
set_global_assignment -name SYSTEMVERILOG_FILE [file normalize $UP/rtl/fp_aitb.sv]
set_global_assignment -name SYSTEMVERILOG_FILE [file normalize $UP/rtl/mxfp_dot.sv]
set_global_assignment -name SYSTEMVERILOG_FILE [file normalize $UP/rtl/pipeline.sv]
set_global_assignment -name SDC_FILE [file normalize $UP/cons/mxfp_dot.sdc]
set_global_assignment -name TOP_LEVEL_ENTITY mxfp_dot
set_global_assignment -name NUM_PARALLEL_PROCESSORS 8
set_global_assignment -name PROJECT_OUTPUT_DIRECTORY "output_files_${REV}"
foreach p {rst load_en valid_in mx_data_in shared_exponent fp32_dot_out valid_out fp32_flags} {
  set_instance_assignment -name VIRTUAL_PIN ON -to $p -entity mxfp_dot
}
set_parameter -name M $M
set_parameter -name E $E
set_parameter -name PIPE $PIPE
set_global_assignment -name MIN_CORE_JUNCTION_TEMP 0
set_global_assignment -name MAX_CORE_JUNCTION_TEMP 100
set_global_assignment -name ERROR_CHECK_FREQUENCY_DIVISOR 256
export_assignments
project_close
