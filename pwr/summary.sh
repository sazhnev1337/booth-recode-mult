#!/bin/bash

get_total() {
    grep "^Total" "$1" | head -1 | awk '{print $5}'
}

SCENARIOS="uniform_fast uniform_slow  gauss_fast gauss_slow"
EXTREC_MODES="standard exact approx_1 approx_2"

{
    echo "=== Power Summary (Total power in Watts) ==="
    printf "%-25s" "config"
    for scn in $SCENARIOS; do
        printf " %14s" "$scn"
    done
    echo ""

    printf "%-25s" "booth"
    for scn in $SCENARIOS; do
        val=$(get_total "reports/power_booth8_${scn}.rpt")
        printf " %14s" "$val"
    done
    echo ""

    for mode in $EXTREC_MODES; do
        printf "%-25s" "booth_extrec_${mode}"
        for scn in $SCENARIOS; do
            val=$(get_total "reports/power_booth_extrec8_${scn}_${mode}.rpt")
            printf " %14s" "$val"
        done
        echo ""
    done
} > reports/summary_power8.txt

cat reports/summary_power8.txt
