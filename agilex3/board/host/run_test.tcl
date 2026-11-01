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
puts [format "ID       = 0x%08X (expect 0x4D58000x)" $id]
if {[expr {($id & 0xFFFFFF00)}] != 0x4D580000} { error "harness ID mismatch" }
set mode [expr {[info exists ::env(MX_MODE)] ? $::env(MX_MODE) : 3}]
W $m 0x008 $mode
puts [format "MODE     = 0x%02X (bit0 two_load, bit1 pipe_align, bit2 loada_zero, bit3 swap_cols, bits7-4 extra reset)" [expr {[R $m 0x008] & 0xFF}]]
set fmt [R $m 0x004]
set hw_kind [expr {($fmt >> 16) & 0xFF}]; set hw_e [expr {($fmt >> 8) & 0xFF}]; set hw_m [expr {$fmt & 0xFF}]
if {![info exists ::KIND]} { set ::KIND 0 }
puts [format "FORMAT   = kind %d E%d M%d (data file kind %d E%d M%d)" $hw_kind $hw_e $hw_m $::KIND $::E $::M]
if {$hw_kind != $::KIND} { error "bitstream DUT kind does not match data file" }
if {$::KIND == 0 && ($hw_e != $::E || $hw_m != $::M)} { error "bitstream format does not match data file" }

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
set cycles [expr {[R $m 0x005] & 0xFFFFFFFF}]
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


# --- per-cycle trace: find where the expected results actually appear
set TRN 192
set tr1 {}; set tr2 {}; set fl {}
set raw1 [master_read_32 $m [expr {0x680 * 4}] [expr {2 * $TRN}]]
for {set i 0} {$i < $TRN} {incr i} {
    lappend tr1 [expr {[lindex $raw1 [expr {2*$i}]] & 0xFFFFFFFF}]
    lappend tr2 [expr {[lindex $raw1 [expr {2*$i+1}]] & 0xFFFFFFFF}]
}
set rawf [master_read_32 $m [expr {0x080 * 4}] [expr {$TRN / 8}]]
for {set i 0} {$i < $TRN} {incr i} { lappend fl [expr {([lindex $rawf [expr {$i >> 3}]] >> (4 * ($i & 7))) & 0xF}] }
set first_valid_in -1; set first_valid_out -1; set first_load -1
for {set i 0} {$i < $TRN} {incr i} {
    set f [lindex $fl $i]
    if {$first_load < 0 && ($f & 2)}      { set first_load $i }
    if {$first_valid_in < 0 && ($f & 4)}  { set first_valid_in $i }
    if {$first_valid_out < 0 && ($f & 8)} { set first_valid_out $i }
}
puts "TRACE    : first load_en at cycle $first_load, first valid_in at $first_valid_in, first valid_out at $first_valid_out (cycle 0 = START)"
# where does expected vector 0 (both columns) first appear in the trace?
set e1 [expr {[lindex $::EXP1 0] & 0xFFFFFFFF}]; set e2 [expr {[lindex $::EXP2 0] & 0xFFFFFFFF}]
set hit -1
for {set i 0} {$i < $TRN} {incr i} { if {[lindex $tr1 $i] == $e1 && [lindex $tr2 $i] == $e2} { set hit $i; break } }
if {$hit >= 0} {
    set lat [expr {$hit - $first_valid_in}]
    puts "TRACE    : expected result 0 first appears at cycle $hit => measured latency valid_in->result = $lat cycles (harness assumes [expr {$first_valid_out - $first_valid_in}])"
    # count how many consecutive vectors match from that point
    set run 0
    for {set k 0} {$k < $::NVEC && ($hit + $k) < $TRN} {incr k} {
        if {[lindex $tr1 [expr {$hit+$k}]] == [expr {[lindex $::EXP1 $k] & 0xFFFFFFFF}] && [lindex $tr2 [expr {$hit+$k}]] == [expr {[lindex $::EXP2 $k] & 0xFFFFFFFF}]} { incr run } else { break }
    }
    puts "TRACE    : $run consecutive vectors bit-exact in the trace starting at cycle $hit"
    set trace_matches $run
} else {
    puts "TRACE    : expected result 0 not found anywhere in the trace"
    set trace_matches 0
    set lat -1
}
if {[info exists ::env(MX_TRACE_DUMP)]} {
    for {set i 0} {$i < $TRN} {incr i} {
        set f [lindex $fl $i]
        puts [format "  c%3d rst=%d load=%d vin=%d vout=%d  col1 0x%08X  col2 0x%08X" $i [expr {$f&1}] [expr {($f>>1)&1}] [expr {($f>>2)&1}] [expr {($f>>3)&1}] [lindex $tr1 $i] [lindex $tr2 $i]]
    }
}
set f [open $result_file w]
set json "{\"kind\":\"measurement\",\"board\":\"Arrow AXC3000 A3CY100BM16AE7S\","
append json [format "\"format\":\"E%dM%d\",\"nvec\":%d,\"mismatches\":%d,\"cycles\":%d,\"dut_mhz\":%.2f,\"mode\":%d,\"trace_latency\":%d,\"trace_matches\":%d," $::E $::M $::NVEC $mism $cycles $mhz $mode $lat $trace_matches]
append json "\"data_file\":\"$data_file\",\"utc\":\"[clock format [clock seconds] -format %Y-%m-%dT%H:%M:%SZ -gmt 1]\","
append json "\"vectors\":\[[join $out ","]\]}"
puts $f $json
close $f
puts "wrote $result_file"
close_service master $m
