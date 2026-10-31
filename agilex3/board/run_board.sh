#!/usr/bin/env bash
# Program the AXC3000 and run the MXFP harness test.
#   bash run_board.sh [data_file] [result_file]
# The AXC3000 needs a reduced JTAG clock for reliable configuration (board errata found in the
# earlier CoreDLA project), so the clock is set to 6 MHz before programming.
set -e
Q=/c/altera_pro/26.1/quartus/bin64
SC=/c/altera_pro/26.1/syscon/bin/system-console.exe
CABLE="USB Blaster III [USB-1]"
cd "$(dirname "$0")"
DATA=${1:-data_e2m1.tcl}
RES=${2:-results_e2m1.json}
SOF=syn/output_files/top.sof
[ -f "$SOF" ] || { echo "missing $SOF; run build.sh first"; exit 1; }
mkdir -p results
echo "=== JTAG chain ==="; $Q/jtagconfig
$Q/jtagconfig --setparam "$CABLE" JtagClock 6M
echo "=== programming $(sha256sum $SOF | cut -c1-16) ==="
$Q/quartus_pgm -c "$CABLE" -m jtag -o "p;$SOF" 2>&1 | grep -E "Info \(209|Error" | tail -4
sleep 2
echo "=== running test ==="
cd host
MX_DATA="$DATA" MX_RESULT="../results/$RES" "$SC" --script=run_test.tcl 2>&1 | grep -vE "^\s*$" | tail -80
