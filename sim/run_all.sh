#!/bin/bash
set -e

mkdir -p vvp waves

SCENARIOS="uniform_fast uniform_slow gauss_fast gauss_slow"
EXTREC_MODES="standard exact approx_1 approx_2"

# Все сценарии: N=20000 (fast period=1, slow period=10)
n_for_scenario() {
    echo 20000
}

# Сначала компилируем все тестбенчи один раз.
echo "=== Compiling testbenches ==="

iverilog -o vvp/sim_booth.vvp \
    tb/tb_mult_booth.v \
    ../syn/netlists/mult_booth.v \
    ../syn/lib/NangateOpenCellLibrary.v
echo "  booth: compiled"

iverilog -o vvp/sim_booth_extrec.vvp \
    tb/tb_mult_booth_extrec.v \
    ../syn/netlists/mult_booth_extrec.v \
    ../syn/lib/NangateOpenCellLibrary.v
echo "  booth_extrec: compiled"

# Теперь прогоны.
echo ""
echo "=== Running simulations ==="

# booth: 4 сценария
for scn in $SCENARIOS; do
    stim="data/stim_${scn}_standard.txt"
    out="waves/power_booth_${scn}.vcd"
    n=$(n_for_scenario $scn)
    echo "booth / $scn (N=$n)"
    vvp vvp/sim_booth.vvp +STIM=$stim +N=$n > /dev/null
    mv waves/power.vcd $out
done

# booth_extrec: 4 сценария × 4 режима.
for scn in $SCENARIOS; do
    for mode in $EXTREC_MODES; do
        stim="data/stim_${scn}_${mode}.txt"
        out="waves/power_booth_extrec_${scn}_${mode}.vcd"
        n=$(n_for_scenario $scn)
        echo "booth_extrec / $scn / $mode (N=$n)"
        vvp vvp/sim_booth_extrec.vvp +STIM=$stim +N=$n > /dev/null
        mv waves/power.vcd $out
    done
done

echo ""
echo "=== Done ==="
echo "VCD count: $(ls waves/power_*.vcd | wc -l)"
ls -lh waves/power_*.vcd | head -5
echo "..."
