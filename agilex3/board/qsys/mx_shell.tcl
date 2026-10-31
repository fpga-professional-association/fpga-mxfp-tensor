package require -exact qsys 26.1
# DUT clock in MHz is passed as argv 0 (default 250)
set DUT_MHZ [expr {$argc > 0 ? [lindex $argv 0] : 250.0}]
proc configure_iopll {refclk_mhz nclk freq_list phase_list} {
	set_component_parameter_value gui_active_clk {0}
	for {set i 0} {$i < 9} {incr i} {
		set_component_parameter_value gui_c_cnt_in_src${i} {c_m_cnt_in_src_ph_mux_clk}
	}
	set_component_parameter_value gui_cal_code_hex_file {iossm.hex}
	set_component_parameter_value gui_cal_converge {0}
	set_component_parameter_value gui_cal_error {cal_clean}
	for {set i 0} {$i < 18} {incr i} {
		set_component_parameter_value gui_cascade_counter${i} {0}
		set_component_parameter_value gui_clock_name_string${i} outclk${i}
		set_component_parameter_value gui_duty_cycle${i} {50.0}
		set_component_parameter_value gui_ps_units${i} {ps}
		set_component_parameter_value gui_phase_shift${i} {0.0}
		# defaults; overridden below for the clocks actually in use
		set_component_parameter_value gui_output_clock_frequency${i} {100.0}
		set_component_parameter_value gui_phase_shift_deg${i} {0.0}
	}
	set_component_parameter_value gui_cascade_outclk_index {0}
	set_component_parameter_value gui_clk_bad {0}
	set_component_parameter_value gui_clock_name_global {0}
	set_component_parameter_value gui_clock_to_compensate {0}
	set_component_parameter_value gui_debug_mode {0}
	set_component_parameter_value gui_dps_cntr {C0}
	set_component_parameter_value gui_dps_dir {Positive}
	set_component_parameter_value gui_dps_num {1}
	set_component_parameter_value gui_dsm_out_sel {1st_order}
	set_component_parameter_value gui_en_adv_params {0}
	set_component_parameter_value gui_en_dps_ports {0}
	set_component_parameter_value gui_en_extclkout_ports {0}
	set_component_parameter_value gui_en_iossm_reconf {0}
	set_component_parameter_value gui_en_lvds_ports {Disabled}
	set_component_parameter_value gui_en_periphery_ports {0}
	set_component_parameter_value gui_en_phout_ports {0}
	set_component_parameter_value gui_en_reconf {0}
	set_component_parameter_value gui_enable_cascade_in {0}
	set_component_parameter_value gui_enable_cascade_out {0}
	set_component_parameter_value gui_enable_mif_dps {0}
	set_component_parameter_value gui_enable_output_counter_cascading {0}
	set_component_parameter_value gui_enable_permit_cal {0}
	set_component_parameter_value gui_enable_upstream_out_clk {0}
	set_component_parameter_value gui_extclkout_0_source {C0}
	set_component_parameter_value gui_extclkout_1_source {C0}
	set_component_parameter_value gui_extclkout_source {C0}
	set_component_parameter_value gui_feedback_clock {Global Clock}
	set_component_parameter_value gui_fix_vco_frequency {0}
	set_component_parameter_value gui_fractional_cout {32}
	set_component_parameter_value gui_include_iossm {0}
	set_component_parameter_value gui_location_type {Fabric-Feeding}
	set_component_parameter_value gui_lock_setting {Low Lock Time}
	set_component_parameter_value gui_mif_config_name {unnamed}
	set_component_parameter_value gui_mif_gen_options {Generate New MIF File}
	set_component_parameter_value gui_number_of_clocks $nclk
	set_component_parameter_value gui_operation_mode {direct}
	set_component_parameter_value gui_parameter_table_hex_file {seq_params_sim.hex}
	set_component_parameter_value gui_phout_division {1}
	set_component_parameter_value gui_pll_auto_reset {0}
	set_component_parameter_value gui_pll_bandwidth_preset {Medium}
	set_component_parameter_value gui_pll_cal_done {0}
	set_component_parameter_value gui_pll_cascading_mode {adjpllin}
	set_component_parameter_value gui_pll_freqcal_en {1}
	set_component_parameter_value gui_pll_freqcal_req_flag {1}
	set_component_parameter_value gui_pll_m_cnt_in_src {c_m_cnt_in_src_ph_mux_clk}
	set_component_parameter_value gui_pll_mode {Integer-N PLL}
	set_component_parameter_value gui_pll_tclk_mux_en {0}
	set_component_parameter_value gui_pll_tclk_sel {pll_tclk_m_src}
	set_component_parameter_value gui_pll_type {S10_Simple}
	set_component_parameter_value gui_pll_vco_freq_band_0 {pll_freq_clk0_band18}
	set_component_parameter_value gui_pll_vco_freq_band_1 {pll_freq_clk1_band18}
	set_component_parameter_value gui_prot_mode {UNUSED}
	set_component_parameter_value gui_refclk1_frequency $refclk_mhz
	set_component_parameter_value gui_refclk_might_change {0}
	set_component_parameter_value gui_refclk_switch {0}
	set_component_parameter_value gui_reference_clock_frequency $refclk_mhz
	set_component_parameter_value gui_reference_clock_frequency_ps [expr {1000000 / $refclk_mhz}]
	set_component_parameter_value gui_simulation_type {0}
	set_component_parameter_value gui_skip_sdc_generation {0}
	set_component_parameter_value gui_switchover_delay {0}
	set_component_parameter_value gui_switchover_mode {Automatic Switchover}
	set_component_parameter_value gui_use_NDFB_modes {0}
	set_component_parameter_value gui_use_coreclk {1}
	set_component_parameter_value gui_use_locked {1}
	set_component_parameter_value gui_use_logical {0}
	set_component_parameter_value gui_user_base_address {0}
	set_component_parameter_value gui_usr_device_speed_grade {1}
	set_component_parameter_value gui_vco_frequency {600.0}
	set_component_parameter_value hp_qsys_scripting_mode {0}
	set_component_parameter_value system_info_device_iobank_rev {}

	# the clocks that are actually in use
	for {set i 0} {$i < $nclk} {incr i} {
		set_component_parameter_value gui_output_clock_frequency${i} [lindex $freq_list $i]
		set_component_parameter_value gui_phase_shift_deg${i}        [lindex $phase_list $i]
	}
}

# ------------------------------------------------------------------ system
create_system mx_shell
set_project_property BOARD {default}
set_project_property DEVICE {A3CY100BM16AE7S}
set_project_property DEVICE_FAMILY {Agilex 3}
set_project_property HIDE_FROM_IP_CATALOG {false}
set_module_property FILE {mx_shell.qsys}
set_module_property GENERATION_ID {0x00000000}
set_module_property NAME {mx_shell}

add_component rrip ip/mx_shell/mx_shell_rrip.ip altera_s10_user_rst_clkgate rrip_inst
load_component rrip
set_component_parameter_value outputType {Reset Interface}
set_component_project_property HIDE_FROM_IP_CATALOG {false}
save_component

add_component pll ip/mx_shell/mx_shell_pll.ip altera_iopll iopll_inst
load_component pll
configure_iopll 25 2 [list 100.0 $DUT_MHZ] {0 0}
set_component_project_property HIDE_FROM_IP_CATALOG {false}
save_component

add_component jtag_master ip/mx_shell/mx_shell_jtag_master.ip altera_jtag_avalon_master master_0
load_component jtag_master
set_component_parameter_value FAST_VER {0}
set_component_parameter_value FIFO_DEPTHS {2}
set_component_parameter_value PLI_PORT {50000}
set_component_parameter_value USE_PLI {0}
set_component_project_property HIDE_FROM_IP_CATALOG {false}
save_component
load_instantiation jtag_master
set_instantiation_assignment_value debug.hostConnection {type jtag id 110:132}
save_instantiation

add_component ccb ip/mx_shell/mx_shell_ccb.ip mm_ccb mm_ccb_0
load_component ccb
set_component_parameter_value ADDRESS_UNITS {SYMBOLS}
set_component_parameter_value ADDRESS_WIDTH {13}
set_component_parameter_value COMMAND_FIFO_DEPTH {4}
set_component_parameter_value DATA_WIDTH {32}
set_component_parameter_value ENABLE_RESPONSE {0}
set_component_parameter_value MASTER_SYNC_DEPTH {2}
set_component_parameter_value MAX_BURST_SIZE {1}
set_component_parameter_value RESPONSE_FIFO_DEPTH {4}
set_component_parameter_value SLAVE_SYNC_DEPTH {2}
set_component_parameter_value SYMBOL_WIDTH {8}
set_component_parameter_value SYNC_RESET {0}
set_component_parameter_value USE_AUTO_ADDRESS_WIDTH {0}
set_component_project_property HIDE_FROM_IP_CATALOG {false}
save_component

foreach {inst nout} {rst_sys 1 rst_dut 2} {
  add_component $inst ip/mx_shell/mx_shell_${inst}.ip altera_reset_bridge reset_bridge_0
  load_component $inst
  set_component_parameter_value ACTIVE_LOW_RESET {1}
  set_component_parameter_value NUM_RESET_OUTPUTS $nout
  set_component_parameter_value SYNCHRONOUS_EDGES {deassert}
  set_component_parameter_value SYNC_RESET {0}
  set_component_parameter_value USE_RESET_REQUEST {0}
  set_component_project_property HIDE_FROM_IP_CATALOG {false}
  save_component
}
foreach inst {clkb_sys clkb_dut} {
  add_component $inst ip/mx_shell/mx_shell_${inst}.ip altera_clock_bridge clock_bridge_0
  load_component $inst
  set_component_parameter_value EXPLICIT_CLOCK_RATE {0.0}
  set_component_parameter_value NUM_CLOCK_OUTPUTS {1}
  set_component_project_property HIDE_FROM_IP_CATALOG {false}
  save_component
}

# clocks
add_connection pll.outclk0/jtag_master.clk
add_connection pll.outclk0/ccb.s0_clk
add_connection pll.outclk0/rst_sys.clk
add_connection pll.outclk0/clkb_sys.in_clk
add_connection pll.outclk1/ccb.m0_clk
add_connection pll.outclk1/rst_dut.clk
add_connection pll.outclk1/clkb_dut.in_clk
# resets
add_connection rrip.ninit_done/pll.reset
add_connection rst_sys.out_reset/jtag_master.clk_reset
add_connection rst_sys.out_reset/ccb.s0_reset
add_connection rst_dut.out_reset/ccb.m0_reset
# data
add_connection jtag_master.master/ccb.s0
set_connection_parameter_value jtag_master.master/ccb.s0 baseAddress {0x0000}

# exports
set_interface_property pll_refclk   EXPORT_OF pll.refclk
set_interface_property pll_locked   EXPORT_OF pll.locked
set_interface_property rst_sys_in   EXPORT_OF rst_sys.in_reset
set_interface_property rst_dut_in   EXPORT_OF rst_dut.in_reset
set_interface_property rst_dut_out  EXPORT_OF rst_dut.out_reset_1
set_interface_property clk_sys      EXPORT_OF clkb_sys.out_clk
set_interface_property clk_dut      EXPORT_OF clkb_dut.out_clk
set_interface_property dut_av       EXPORT_OF ccb.m0

sync_sysinfo_parameters
save_system mx_shell
