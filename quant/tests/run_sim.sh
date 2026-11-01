#!/usr/bin/env bash
# Simulate quant/rtl/mxq_decoders.sv against the Python goldens with Icarus (run from the repo root,
# in WSL or any Linux shell):  bash quant/tests/run_sim.sh
set -u
cd "$(dirname "$0")/../.."
iverilog -g2012 -o /tmp/tb_mxq quant/rtl/mxq_decoders.sv quant/tests/tb_mxq_decoders.sv > /tmp/iv.log 2>&1
echo "iverilog rc=$?"
grep -vi sorry /tmp/iv.log | head -20
[ -f /tmp/tb_mxq ] && vvp /tmp/tb_mxq 2>&1 | grep -vi sorry | tail -12
