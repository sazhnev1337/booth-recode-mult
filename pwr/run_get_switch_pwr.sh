#!/bin/bash

for cfg in baseline exact approx_1 approx_2 approx_3 approx_4; do
    switch_combo=$(grep "^Combinational" reports/power_${cfg}.rpt | awk '{print $3}')
    printf "%-12s %s\n" "$cfg" "$switch_combo"
done
