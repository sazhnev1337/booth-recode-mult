#!/bin/bash
set -e

mkdir -p ../sim/data

# Distribution × update_period × recoding_mode
# Genератор всех сценариев которые мы планируем измерять.

# Для baseline нужен только один режим — standard (используется как reference).
# Recoded-варианты: exact, approx_1, approx_2, approx_3, approx_4.

for dist in uniform gauss; do
    for period in 1 50; do
        # Имя сценария: gauss_slow, uniform_fast, etc.
        if [ "$period" = "1" ]; then
            scn_suffix="fast"
        else
            scn_suffix="slow"
        fi
        scn="${dist}_${scn_suffix}"

        for mode in standard exact approx_1 approx_2 approx_3 approx_4; do
            python3 gen_stimulus.py $dist $period $mode ../sim/data/stim_${scn}_${mode}.txt
        done
    done
done

echo ""
echo "Generated stimulus files:"
ls -lh ../sim/data/stim_*.txt
