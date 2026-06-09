#!/bin/bash
set -e

mkdir -p reports _gen

SCENARIOS="uniform_fast uniform_slow gauss_fast gauss_slow"
EXTREC_MODES="standard exact approx_1 approx_2"

# Функция для генерации и запуска одного OpenSTA скрипта.
# Аргументы: config_name, netlist_name, tb_module, vcd_path, rpt_path
run_sta() {
    local cfg=$1
    local netlist=$2
    local tb=$3
    local vcd=$4
    local rpt=$5

    cat > _gen/power_${cfg}.tcl <<EOF
read_liberty ../syn/lib/NangateOpenCellLibrary_typical.lib
read_verilog ../syn/netlists/${netlist}.v
link_design ${netlist}
read_sdc booth.sdc
read_vcd -scope ${tb}/dut ${vcd}
report_power
exit
EOF

    sta -no_init -no_splash _gen/power_${cfg}.tcl > $rpt 2>&1
}

echo "=== Analyzing power ==="

# naive: 4 сценария.
for scn in $SCENARIOS; do
    cfg="naive_${scn}"
    echo "  $cfg"
    run_sta "$cfg" "mult_naive" "tb_mult_naive" \
        "../sim/waves/power_naive_${scn}.vcd" \
        "reports/power_${cfg}.rpt"
done

# booth: 4 сценария.
for scn in $SCENARIOS; do
    cfg="booth_${scn}"
    echo "  $cfg"
    run_sta "$cfg" "mult_booth" "tb_mult_booth" \
        "../sim/waves/power_booth_${scn}.vcd" \
        "reports/power_${cfg}.rpt"
done

# booth_extrec: 4 сценария × 4 режима.
for scn in $SCENARIOS; do
    for mode in $EXTREC_MODES; do
        cfg="booth_extrec_${scn}_${mode}"
        echo "  $cfg"
        run_sta "$cfg" "mult_booth_extrec" "tb_mult_booth_extrec" \
            "../sim/waves/power_booth_extrec_${scn}_${mode}.vcd" \
            "reports/power_${cfg}.rpt"
    done
done

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
