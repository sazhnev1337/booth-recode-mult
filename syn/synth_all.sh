#!/bin/bash
set -e

./synth.sh baseline 0
./synth.sh exact    1
./synth.sh approx_1 2 1
./synth.sh approx_2 2 2
./synth.sh approx_3 2 3
./synth.sh approx_4 2 4

echo ""
echo "=== Summary ==="
for cfg in baseline exact approx_1 approx_2 approx_3 approx_4; do
    area=$(grep "Chip area" reports/area_${cfg}.rpt | awk '{print $NF}')
    printf "%-12s %s um^2\n" "$cfg" "$area"
done