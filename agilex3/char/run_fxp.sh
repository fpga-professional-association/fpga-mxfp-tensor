#!/usr/bin/env bash
# usage: run_bfp.sh <tag> <FAMILY> <DEVICE>
set -e
TAG=$1; FAMILY=$2; DEVICE=$3
Q=/c/altera_pro/26.1/quartus/bin64
HERE=$(cd "$(dirname "$0")" && pwd)
UP=$(cd "$HERE/../../upstream/fpga-mxfp/characterization/ai_tensor_block" && pwd -W)
BR=$(cd "$HERE/../board/rtl" && pwd -W)
W="$HERE/fxp_$TAG"; mkdir -p "$W"; cd "$W"
REV=FXP_V1
$Q/quartus_sh -t "$HERE/setup_fxp.tcl" fxp_cli $REV "$FAMILY" $DEVICE 1 "$UP" "$BR" > setup_$REV.log 2>&1
$Q/quartus_sh -t "$HERE/fit.tcl" fxp_cli $REV > fit_$REV.log 2>&1 || { echo "FIT FAILED $TAG"; grep -E "^Error" fit_$REV.log | head -5; exit 1; }
bash "$HERE/../../upstream/fpga-mxfp/characterization/extract_results.sh" $REV output_files_$REV | sed "s/^/fxp,$TAG,/" | tee -a "$HERE/other_results.csv"
