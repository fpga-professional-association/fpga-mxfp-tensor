#!/usr/bin/env bash
# Build the AXC3000 MXFP harness bitstream.
#   bash build.sh            full flow (syn, fit, sta, asm) -> syn/output_files/top.sof
#   bash build.sh syn        synthesis only
# Regenerate the Platform Designer shell first if qsys/mx_shell.tcl changed:
#   (cd qsys && qsys-script --quartus-project=none --script=mx_shell.tcl 240.0 &&
#    qsys-generate mx_shell.qsys --synthesis=VERILOG --quartus-project=none --family="Agilex 3" --part=A3CY100BM16AE7S)
set -e
Q=/c/altera_pro/26.1/quartus/bin64
cd "$(dirname "$0")/syn"
STAGE=${1:-all}
$Q/quartus_syn --read_settings_files=on --write_settings_files=off top -c top
[ "$STAGE" = syn ] && exit 0
$Q/quartus_fit --read_settings_files=on --write_settings_files=off top -c top
$Q/quartus_sta top -c top --mode=finalize
$Q/quartus_asm --read_settings_files=on --write_settings_files=off top -c top
echo "=== resource summary ==="
grep -E "Logic utilization \(ALMs\)|DSP Blocks|Total RAM Blocks|M20K" output_files/top.fit.rpt | head -6
echo "=== fmax ==="
awk '/; Fmax Summary/,/^$/' output_files/top.sta.rpt | head -14
