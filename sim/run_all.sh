#!/bin/bash
set -e

mkdir -p vvp

for cfg in baseline exact approx_1 approx_2 approx_3 approx_4; do
    echo "=== Simulating $cfg ==="
    iverilog -o ./vvp/sim_${cfg}.vvp \
        ./tb/tb_power.v \
        ../syn/netlists/${cfg}.v \
        ../syn/lib/NangateOpenCellLibrary.v
    vvp ./vvp/sim_${cfg}.vvp > /dev/null
    mv power.vcd power_${cfg}.vcd
    echo "  $(ls -lh power_${cfg}.vcd | awk '{print $5}')"
done

echo ""
echo "=== All VCDs ==="
ls -lh power_*.vcd