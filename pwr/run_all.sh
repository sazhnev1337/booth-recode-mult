#!/bin/bash
set -e

mkdir -p reports
mkdir -p _gen

for cfg in baseline exact approx_1 approx_2 approx_3 approx_4; do
    echo "=== Analyzing $cfg ==="
    
    # Генерируем power.tcl на лету.
    cat > _gen/power_${cfg}.tcl <<EOF
read_liberty ../syn/lib/NangateOpenCellLibrary_typical.lib
read_verilog ../syn/netlists/${cfg}.v
link_design booth_multiplier_wrapper
read_sdc booth.sdc
read_vcd -scope tb_power/dut ../sim/power_${cfg}.vcd
report_power
exit
EOF
    
    sta -no_init -no_splash _gen/power_${cfg}.tcl > reports/power_${cfg}.rpt 2>&1
    
    # Печатаем итоговую строку Total.
    total=$(grep "^Total" reports/power_${cfg}.rpt | head -1 | awk '{print $5}')
    printf "  Total: %s W\n" "$total"
done

echo ""
echo "=== Summary ==="
printf "%-12s %s\n" "config" "Total power (W)"
for cfg in baseline exact approx_1 approx_2 approx_3 approx_4; do
    total=$(grep "^Total" reports/power_${cfg}.rpt | head -1 | awk '{print $5}')
    printf "%-12s %s\n" "$cfg" "$total"
done
