#!/bin/bash
set -e

mkdir -p vvp waves

# Конфигурации с их источниками RTL.
# Для каждой пары (cfg, mode) запускаем симуляцию с соответствующим stimulus.
# naive и booth работают только с режимом 'standard' (recoded-колонка игнорируется).
# booth_extrec работает со всеми режимами recoding.

SCENARIOS="uniform_fast uniform_slow gauss_fast gauss_slow"
EXTREC_MODES="standard exact approx_1 approx_2"

# Сначала компилируем все тестбенчи один раз.
echo "=== Compiling testbenches ==="

if [ ! -f vvp/sim_naive.vvp ]; then
    iverilog -o vvp/sim_naive.vvp \
        tb/tb_mult_naive.v \
        ../syn/netlists/mult_naive.v \
        ../syn/lib/NangateOpenCellLibrary.v
    echo "  naive: compiled"
fi

if [ ! -f vvp/sim_booth.vvp ]; then
    iverilog -o vvp/sim_booth.vvp \
        tb/tb_mult_booth.v \
        ../syn/netlists/mult_booth.v \
        ../syn/lib/NangateOpenCellLibrary.v
    echo "  booth: compiled"
fi

if [ ! -f vvp/sim_booth_extrec.vvp ]; then
    iverilog -o vvp/sim_booth_extrec.vvp \
        tb/tb_mult_booth_extrec.v \
        ../syn/netlists/mult_booth_extrec.v \
        ../syn/lib/NangateOpenCellLibrary.v
    echo "  booth_extrec: compiled"
fi

# Теперь прогоны.
echo ""
echo "=== Running simulations ==="

# naive: 4 сценария
for scn in $SCENARIOS; do
    stim="data/stim_${scn}_standard.txt"
    out="waves/power_naive_${scn}.vcd"
    echo "naive / $scn"
    vvp vvp/sim_naive.vvp +STIM=$stim > /dev/null
    mv waves/power.vcd $out
done

# booth: 4 сценария
for scn in $SCENARIOS; do
    stim="data/stim_${scn}_standard.txt"
    out="waves/power_booth_${scn}.vcd"
    echo "booth / $scn"
    vvp vvp/sim_booth.vvp +STIM=$stim > /dev/null
    mv waves/power.vcd $out
done

# booth_extrec: 4 сценария × 4 режима.
for scn in $SCENARIOS; do
    for mode in $EXTREC_MODES; do
        stim="data/stim_${scn}_${mode}.txt"
        out="waves/power_booth_extrec_${scn}_${mode}.vcd"
        echo "booth_extrec / $scn / $mode"
        vvp vvp/sim_booth_extrec.vvp +STIM=$stim > /dev/null
        mv waves/power.vcd $out
    done
done

echo ""
echo "=== Done ==="
echo "VCD count: $(ls waves/power_*.vcd | wc -l)"
ls -lh waves/power_*.vcd | head -5
echo "..."
