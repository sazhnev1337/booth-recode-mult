#!/bin/bash
set -e

mkdir -p reports _gen

CONFIGS="baseline \
         exact approx_1 approx_2 approx_3 approx_4 \
         exact_z approx_1_z approx_2_z approx_3_z approx_4_z \
         exact_b approx_1_b approx_2_b approx_3_b approx_4_b"

SCENARIOS="uniform_fast uniform_slow gauss_slow"

for scn in $SCENARIOS; do
    for cfg in $CONFIGS; do
        cat > _gen/power_${cfg}_${scn}.tcl <<EOF
read_liberty ../syn/lib/NangateOpenCellLibrary_typical.lib
read_verilog ../syn/netlists/${cfg}.v
link_design booth_multiplier_wrapper
read_sdc booth.sdc
read_vcd -scope tb_power/dut ../sim/waves/power_${cfg}_${scn}.vcd
report_power
exit
EOF
        sta -no_init -no_splash _gen/power_${cfg}_${scn}.tcl \
            > reports/power_${cfg}_${scn}.rpt 2>&1
    done
done

# Сводная таблица: строки — конфиги, колонки — сценарии.
echo ""
echo "=== Summary ==="
printf "%-15s" "config"
for scn in $SCENARIOS; do
    printf " %12s" "$scn"
done
echo ""

for cfg in $CONFIGS; do
    printf "%-15s" "$cfg"
    for scn in $SCENARIOS; do
        total=$(grep "^Total" reports/power_${cfg}_${scn}.rpt | head -1 | awk '{print $5}')
        printf " %12s" "$total"
    done
    echo ""
done
