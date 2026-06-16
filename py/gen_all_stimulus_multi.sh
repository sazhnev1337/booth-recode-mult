#!/bin/bash
# Generate stimulus files for 8-bit and 20-bit multipliers.
# Run from: py/
set -e

mkdir -p ../sim/data

for dist in uniform gauss; do
    for period in 1 10; do
        [ "$period" = "1" ] && suffix="fast" || suffix="slow"
        scn="${dist}_${suffix}"

        for mode in standard exact approx_1 approx_2 approx_3 approx_4; do
            python3 gen_stimulus_8.py  $dist $period $mode ../sim/data/stim8_${scn}_${mode}.txt  20000
            python3 gen_stimulus_20.py $dist $period $mode ../sim/data/stim20_${scn}_${mode}.txt 20000
        done
    done
done

echo ""
echo "Generated stimulus files:"
ls -lh ../sim/data/stim8_*.txt ../sim/data/stim20_*.txt
