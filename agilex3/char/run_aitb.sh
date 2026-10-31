#!/usr/bin/env bash
# usage: run_aitb.sh <tag> <FAMILY> <DEVICE> <E> <M>
set -e
TAG=$1; FAMILY=$2; DEVICE=$3; E=$4; M=$5
Q=/c/altera_pro/26.1/quartus/bin64
HERE=$(cd "$(dirname "$0")" && pwd)
UP=$(cd "$HERE/../../upstream/fpga-mxfp/characterization/ai_tensor_block" && pwd -W)
W="$HERE/aitb_$TAG"; mkdir -p "$W"; cd "$W"
REV=E${E}_M${M}
$Q/quartus_sh -t "$HERE/setup_aitb.tcl" mxfp_dot_cli $REV "$FAMILY" $DEVICE $E $M 1 "$UP" > setup_$REV.log 2>&1
$Q/quartus_sh -t "$HERE/fit.tcl" mxfp_dot_cli $REV > fit_$REV.log 2>&1 || { echo "FIT FAILED $TAG $REV"; tail -30 fit_$REV.log; exit 1; }
bash "$HERE/../../upstream/fpga-mxfp/characterization/extract_results.sh" $REV output_files_$REV | sed "s/^/$TAG,/" | tee -a "$HERE/aitb_results.csv"
