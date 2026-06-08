#!/bin/bash
set -e

./synth.sh baseline        0
./synth.sh exact           1 0 0 0
./synth.sh approx_1        2 1 0 0
./synth.sh approx_2        2 2 0 0
./synth.sh approx_3        2 3 0 0
./synth.sh approx_4        2 4 0 0
./synth.sh exact_z         1 0 1 0
./synth.sh approx_1_z      2 1 1 0
./synth.sh approx_2_z      2 2 1 0
./synth.sh approx_3_z      2 3 1 0
./synth.sh approx_4_z      2 4 1 0
./synth.sh exact_b         1 0 0 1
./synth.sh approx_1_b      2 1 0 1
./synth.sh approx_2_b      2 2 0 1
./synth.sh approx_3_b      2 3 0 1
./synth.sh approx_4_b      2 4 0 1

echo ""
echo "=== Summary ==="
for cfg in baseline \
           exact approx_1 approx_2 approx_3 approx_4 \
           exact_z approx_1_z approx_2_z approx_3_z approx_4_z \
           exact_b approx_1_b approx_2_b approx_3_b approx_4_b; do
    area=$(grep "Chip area" reports/area_${cfg}.rpt | awk '{print $NF}')
    printf "%-15s %s um^2\n" "$cfg" "$area"
done
