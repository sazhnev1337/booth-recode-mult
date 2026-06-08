#!/bin/bash
set -e

mkdir -p vvp waves

CONFIGS="baseline \
         exact approx_1 approx_2 approx_3 approx_4 \
         exact_z approx_1_z approx_2_z approx_3_z approx_4_z \
         exact_b approx_1_b approx_2_b approx_3_b approx_4_b"

SCENARIOS="uniform_fast uniform_slow gauss_slow"

# Сначала компилируем каждый конфиг один раз.
for cfg in $CONFIGS; do
    if [ ! -f ./vvp/sim_${cfg}.vvp ]; then
        echo "Compiling $cfg ..."
        iverilog -o ./vvp/sim_${cfg}.vvp \
            ./tb/tb_power.v \
            ../syn/netlists/${cfg}.v \
            ../syn/lib/NangateOpenCellLibrary.v
    fi
done

# Потом гоняем все комбинации.
for scn in $SCENARIOS; do
    for cfg in $CONFIGS; do
        echo "=== $cfg / $scn ==="
        vvp ./vvp/sim_${cfg}.vvp +STIM=data/stimulus_${scn}.txt > /dev/null
        mv waves/power.vcd waves/power_${cfg}_${scn}.vcd
    done
done

echo ""
echo "VCD count: $(ls waves/power_*.vcd | wc -l)"
