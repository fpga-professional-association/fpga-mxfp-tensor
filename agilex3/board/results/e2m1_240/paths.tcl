project_open top -revision top
create_timing_netlist -model slow
read_sdc
update_timing_netlist
report_timing -setup -npaths 4 -detail path_only -to_clock {u0|pll|iopll_inst_outclk1} -file paths_setup.txt
report_clocks -file clocks.txt
delete_timing_netlist
project_close
