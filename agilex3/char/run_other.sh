#!/usr/bin/env bash
# usage: run_other.sh <fp16|packed> <tag> <FAMILY> <DEVICE> <E> <M>
set -e
KIND=$1; TAG=$2; FAMILY=$3; DEVICE=$4; E=$5; M=$6
Q=/c/altera_pro/26.1/quartus/bin64
HERE=$(cd "$(dirname "$0")" && pwd)
UPROOT=$(cd "$HERE/../../upstream/fpga-mxfp/characterization" && pwd -W)
W="$HERE/${KIND}_$TAG"; mkdir -p "$W"; cd "$W"
REV=E${E}_M${M}
if [ "$KIND" = fp16 ]; then
  $Q/quartus_sh -t "$HERE/setup_fp16.tcl" ${KIND}_cli $REV "$FAMILY" $DEVICE $E $M 32 "$UPROOT/fp16_dot_product" > setup_$REV.log 2>&1
else
  $Q/quartus_sh -t "$HERE/setup_packed.tcl" ${KIND}_cli $REV "$FAMILY" $DEVICE $E $M "$UPROOT/packed_multiplier" > setup_$REV.log 2>&1
fi
$Q/quartus_sh -t "$HERE/fit.tcl" ${KIND}_cli $REV > fit_$REV.log 2>&1 || { echo "FIT FAILED $KIND $TAG $REV"; grep -E "^Error" fit_$REV.log | head -5; exit 1; }
bash "$UPROOT/extract_results.sh" $REV output_files_$REV | sed "s/^/$KIND,$TAG,/" | tee -a "$HERE/other_results.csv"
