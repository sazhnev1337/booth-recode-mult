#!/bin/bash
{
    echo "=== Area Summary ==="
    for cfg in naive booth booth_extrec; do
        area=$(grep "Chip area" reports/area_mult_${cfg}.rpt | awk '{print $NF}')
        printf "%-15s %s um^2\n" "$cfg" "$area"
    done
} > reports/summary_area.txt

cat reports/summary_area.txt
