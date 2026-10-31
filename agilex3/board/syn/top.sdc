set_time_format -unit ns -decimal_places 3
source jtag_example.sdc
create_clock -name CLK_25M -period 40.000 [get_ports {CLK_25M}]
derive_pll_clocks
derive_clock_uncertainty
set ck_sys [get_clocks -nowarn {*pll*outclk0*}]
set ck_dut [get_clocks -nowarn {*pll*outclk1*}]
if {[get_collection_size $ck_sys] > 0 && [get_collection_size $ck_dut] > 0} {
    set_clock_groups -asynchronous -group $ck_sys -group $ck_dut
} else {
    post_message -type critical_warning "top.sdc: PLL clock groups not matched"
}
set_false_path -to [get_ports {LED1_N GLED_N RLED_N BLED_N UART_TX}]
set_false_path -from [get_ports {UART_RX}]
