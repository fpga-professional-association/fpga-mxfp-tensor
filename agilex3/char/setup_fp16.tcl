# argv: PROJ REV FAMILY DEVICE E M K UPSTREAM_FP16_DIR
package require ::quartus::project
lassign $argv PROJ REV FAMILY DEVICE E M K UP
if {[project_exists $PROJ]} { project_open -revision $REV $PROJ } else { project_new -revision $REV $PROJ }
set_global_assignment -name FAMILY $FAMILY
set_global_assignment -name DEVICE $DEVICE
foreach f {rtl/fp16_mxfp_dp.sv rtl/mxfp_to_fp.sv rtl/direct_vector_dp.sv rtl/add_shared_exp.sv rtl/pipeline.sv rtl/ip/sum_of_two.v rtl/ip/vector_one.v rtl/ip/vector_two.v rtl/ip/fp32_add.v} {
  set_global_assignment -name SYSTEMVERILOG_FILE [file normalize $UP/$f]
}
set_global_assignment -name SDC_FILE [file normalize $UP/quartus_tcl/mx_dp.sdc]
set_global_assignment -name TOP_LEVEL_ENTITY fp16_mxfp_dp
set_global_assignment -name NUM_PARALLEL_PROCESSORS 6
set_global_assignment -name PROJECT_OUTPUT_DIRECTORY "output_files_${REV}"
foreach p {rst mxfp_in_a mxfp_in_b shared_exp_in_a shared_exp_in_b fp32_out} { set_instance_assignment -name VIRTUAL_PIN ON -to $p -entity fp16_mxfp_dp }
set_parameter -name exp_width $E
set_parameter -name man_width $M
set_parameter -name k $K
set_global_assignment -name MIN_CORE_JUNCTION_TEMP 0
set_global_assignment -name MAX_CORE_JUNCTION_TEMP 100
export_assignments
project_close
