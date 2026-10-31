package require ::quartus::project
set PROJ [lindex $argv 0]; set REV [lindex $argv 1]
project_open -revision $REV $PROJ
execute_module -tool map
execute_module -tool fit
execute_module -tool sta
project_close
