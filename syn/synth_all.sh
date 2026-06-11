#!/bin/bash
set -e

./synth.sh booth
./synth.sh booth_extrec

echo ""
echo "=== Summary ==="
for cfg in booth booth_extrec; do
    area=$(grep "Chip area" reports/area_mult_${cfg}.rpt | awk '{print $NF}')
    printf "%-15s %s um^2\n" "$cfg" "$area"
done
