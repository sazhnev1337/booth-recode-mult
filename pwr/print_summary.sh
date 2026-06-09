#!/bin/bash
set -e

SCENARIOS="uniform_fast uniform_slow gauss_fast gauss_slow"
EXTREC_MODES="standard exact approx_1 approx_2"


# Извлечение Total power из отчёта.
get_total() {
    grep "^Total" "$1" | head -1 | awk '{print $5}'
}
echo ""
echo "=== Summary ==="
printf "%-25s" "config"
for scn in $SCENARIOS; do
    printf " %14s" "$scn"
done
echo ""

# naive строка
printf "%-25s" "naive"
for scn in $SCENARIOS; do
    val=$(get_total "reports/power_naive_${scn}.rpt")
    printf " %14s" "$val"
done
echo ""

# booth строка
printf "%-25s" "booth"
for scn in $SCENARIOS; do
    val=$(get_total "reports/power_booth_${scn}.rpt")
    printf " %14s" "$val"
done
echo ""

# booth_extrec — по строке на каждый режим
for mode in $EXTREC_MODES; do
    printf "%-25s" "booth_extrec_${mode}"
    for scn in $SCENARIOS; do
        val=$(get_total "reports/power_booth_extrec_${scn}_${mode}.rpt")
        printf " %14s" "$val"
    done
    echo ""
done
