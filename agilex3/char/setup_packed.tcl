# argv: PROJ REV FAMILY DEVICE E M UPSTREAM_PACKED_DIR
package require ::quartus::project
lassign $argv PROJ REV FAMILY DEVICE E M UP
if {[project_exists $PROJ]} { project_open -revision $REV $PROJ } else { project_new -revision $REV $PROJ }
set_global_assignment -name FAMILY $FAMILY
set_global_assignment -name DEVICE $DEVICE
foreach f {packed_dot_product_fp32.sv packed_dot_product.sv packed_multiplier.sv DSP_2x18x18.sv reduction.sv} {
  set_global_assignment -name SYSTEMVERILOG_FILE [file normalize $UP/$f]
}
set_global_assignment -name VHDL_FILE [file normalize $UP/flopoco_fx2fp_pipelined/mxfp_e${E}m${M}_to_fp32.vhdl]
set_global_assignment -name SDC_FILE [file normalize $UP/packed_dot_product_fp32.sdc]
set_global_assignment -name TOP_LEVEL_ENTITY packed_dot_product_fp32
set_global_assignment -name NUM_PARALLEL_PROCESSORS 6
set_global_assignment -name PROJECT_OUTPUT_DIRECTORY "output_files_${REV}"
set_instance_assignment -name VIRTUAL_PIN ON -to *
set_parameter -name exponent_width $E
set_parameter -name mantissa_width $M
set_global_assignment -name MIN_CORE_JUNCTION_TEMP 0
set_global_assignment -name MAX_CORE_JUNCTION_TEMP 100
export_assignments
project_close
