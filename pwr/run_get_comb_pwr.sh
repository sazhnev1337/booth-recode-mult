#!/bin/bash

for cfg in baseline exact approx_1 approx_2 approx_3 approx_4; do
    combo=$(grep "^Combinational" reports/power_${cfg}.rpt | awk '{print $5}')
    printf "%-12s %s\n" "$cfg" "$combo"
done
