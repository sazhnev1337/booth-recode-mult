CONFIGS="baseline \
         exact approx_1 approx_2 approx_3 approx_4 \
         exact_z approx_1_z approx_2_z approx_3_z approx_4_z \
         exact_b approx_1_b approx_2_b approx_3_b approx_4_b"

SCENARIOS="uniform_fast uniform_slow gauss_slow"

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
