# run_test.tcl -- System Console driver for the MXFP harness on the AXC3000.
#
#   system-console.exe --script=run_test.tcl --cli -- data_e2m1.tcl results_e2m1.json
#
# Loads the vectors from the data file produced by mx_golden.py, runs the DUT, reads the fp32
# results back, compares bit-exactly with the golden model, measures the DUT clock with the
# free-running counter, and writes a JSON record. Every number printed is read from the board.

set data_file   [expr {[info exists ::env(MX_DATA)]   ? $::env(MX_DATA)   : "data_e2m1.tcl"}]
set result_file [expr {[info exists ::env(MX_RESULT)] ? $::env(MX_RESULT) : "results.json"}]
source $data_file

proc W {m word val} { master_write_32 $m [expr {$word * 4}] [list $val] }
proc R {m word}     { return [lindex [master_read_32 $m [expr {$word * 4}] 1] 0] }

set paths [get_service_paths master]
if {[llength $paths] == 0} { error "no JTAG master found; is the board programmed?" }
set m [lindex $paths 0]
open_service master $m
puts "master: $m"

set id [R $m 0x000]
puts [format "ID       = 0x%08X (expect 0x4D580001)" $id]
if {[expr {$id & 0xFFFFFFFF}] != 0x4D580001} { error "harness ID mismatch" }
set fmt [R $m 0x004]
puts [format "FORMAT   = E%d M%d (data file E%d M%d)" [expr {($fmt >> 8) & 0xFF}] [expr {$fmt & 0xFF}] $::E $::M]
if {[expr {($fmt >> 8) & 0xFF}] != $::E || [expr {$fmt & 0xFF}] != $::M} { error "bitstream format does not match data file" }

# --- DUT clock measurement: free-running counter over ~1 s of host time
set c0 [R $m 0x006]; set t0 [clock milliseconds]
after 1000
set c1 [R $m 0x006]; set t1 [clock milliseconds]
set dcnt [expr {($c1 - $c0) & 0xFFFFFFFF}]
set mhz  [expr {double($dcnt) / (($t1 - $t0) * 1000.0)}]
puts [format "DUT clock ~ %.2f MHz (counter delta %u over %d ms)" $mhz $dcnt [expr {$t1 - $t0}]]

# --- load weights
for {set k 0} {$k < 8} {incr k} { W $m [expr {0x100 + $k}] [lindex $::W1 $k]; W $m [expr {0x110 + $k}] [lindex $::W2 $k] }
W $m 0x108 $::X1
W $m 0x118 $::X2
# --- load activations
set i 0
foreach a $::ACT {
    for {set k 0} {$k < 8} {incr k} { W $m [expr {0x200 + 16*$i + $k}] [lindex $a $k] }
    W $m [expr {0x200 + 16*$i + 8}] [lindex $a 8]
    incr i
}
W $m 0x003 $::NVEC

# readback sanity on one weight word
set rb [R $m 0x100]
if {[expr {$rb & 0xFFFFFFFF}] != [expr {[lindex $::W1 0] & 0xFFFFFFFF}]} { error [format "weight readback mismatch 0x%08X" $rb] }

# --- run
W $m 0x001 0x2    ;# DUT reset pulse
W $m 0x001 0x1    ;# START
set st 0
for {set tries 0} {$tries < 200} {incr tries} {
    set st [R $m 0x002]
    if {$st & 0x2} break
    after 5
}
puts [format "STATUS   = 0x%X (bit1 done, bit2 overrun)" $st]
if {!($st & 0x2)} { error "run did not complete" }
set cycles [R $m 0x005]
puts "CYCLES   = $cycles DUT clocks from START to last result ($::NVEC vectors)"

# --- compare
set mism 0
set out {}
for {set i 0} {$i < $::NVEC} {incr i} {
    set r1 [expr {[R $m [expr {0x600 + 2*$i}]] & 0xFFFFFFFF}]
    set r2 [expr {[R $m [expr {0x600 + 2*$i + 1}]] & 0xFFFFFFFF}]
    set e1 [expr {[lindex $::EXP1 $i] & 0xFFFFFFFF}]
    set e2 [expr {[lindex $::EXP2 $i] & 0xFFFFFFFF}]
    set ok [expr {$r1 == $e1 && $r2 == $e2}]
    if {!$ok} { incr mism; puts [format "  vec %2d: col1 0x%08X (exp 0x%08X)  col2 0x%08X (exp 0x%08X)  MISMATCH" $i $r1 $e1 $r2 $e2] }
    lappend out [format "{\"i\":%d,\"col1\":\"0x%08X\",\"col2\":\"0x%08X\",\"exp1\":\"0x%08X\",\"exp2\":\"0x%08X\",\"ok\":%s}" $i $r1 $r2 $e1 $e2 [expr {$ok ? "true" : "false"}]]
}
puts [format "RESULT   : %d / %d vectors bit-exact (%d mismatches), 2 dot-32 per vector" [expr {$::NVEC - $mism}] $::NVEC $mism]

set f [open $result_file w]
puts $f [format "{\"kind\":\"measurement\",\"board\":\"Arrow AXC3000 A3CY100BM16AE7S\",\"format\":\"E%dM%d\",\"nvec\":%d,\"mismatches\":%d,\"cycles\":%d,\"dut_mhz\":%.2f,\"data_file\":\"%s\",\"utc\":\"%s\",\"vectors\":[%s]}" \
    $::E $::M $::NVEC $mism $cycles $mhz $data_file [clock format [clock seconds] -format %Y-%m-%dT%H:%M:%SZ -gmt 1] [join $out ","]]
close $f
puts "wrote $result_file"
close_service master $m
