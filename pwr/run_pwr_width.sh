#!/bin/bash
# OpenSTA power analysis for a single bit-width.
# Run from: pwr/
#
# Usage: ./run_pwr_width.sh <width>
#   width: 8 | 16 | 20
set -e

WIDTH=$1
if [ -z "$WIDTH" ]; then
    echo "Usage: $0 <width>  (8 | 16 | 20)"
    exit 1
fi

LIB="../syn/lib/NangateOpenCellLibrary_typical.lib"
SCENARIOS="uniform_fast uniform_slow gauss_fast gauss_slow"
EXTREC_MODES="standard exact approx_1 approx_2"

mkdir -p reports _gen

case "$WIDTH" in
    8)
        NET_BOOTH="mult_booth_8"
        NET_EXTREC="mult_booth_extrec_8"
        TB_BOOTH="tb_mult_booth_8"
        TB_EXTREC="tb_mult_booth_extrec_8"
        VCD_BOOTH="power_booth8"
        VCD_EXTREC="power_booth_extrec8"
        RPT_BOOTH="power_booth8"
        RPT_EXTREC="power_booth_extrec8"
        ;;
    16)
        NET_BOOTH="mult_booth"
        NET_EXTREC="mult_booth_extrec"
        TB_BOOTH="tb_mult_booth"
        TB_EXTREC="tb_mult_booth_extrec"
        VCD_BOOTH="power_booth"
        VCD_EXTREC="power_booth_extrec"
        RPT_BOOTH="power_booth"
        RPT_EXTREC="power_booth_extrec"
        ;;
    20)
        NET_BOOTH="mult_booth_20"
        NET_EXTREC="mult_booth_extrec_20"
        TB_BOOTH="tb_mult_booth_20"
        TB_EXTREC="tb_mult_booth_extrec_20"
        VCD_BOOTH="power_booth20"
        VCD_EXTREC="power_booth_extrec20"
        RPT_BOOTH="power_booth20"
        RPT_EXTREC="power_booth_extrec20"
        ;;
    *)
        echo "ERROR: unknown width '$WIDTH'. Use 8, 16, or 20."
        exit 1
        ;;
esac

run_sta() {
    local cfg=$1 netlist=$2 tb=$3 vcd=$4 rpt=$5
    cat > _gen/power_${cfg}.tcl <<EOF
read_liberty ${LIB}
read_verilog ../syn/netlists/${netlist}.v
link_design ${netlist}
read_sdc booth.sdc
read_vcd -scope ${tb}/dut ${vcd}
report_power
exit
EOF
    sta -no_init -no_splash _gen/power_${cfg}.tcl > "$rpt" 2>&1
}

echo "=== Power analysis (${WIDTH}-bit) ==="

for scn in $SCENARIOS; do
    cfg="${RPT_BOOTH}_${scn}"
    echo "  booth_${WIDTH} / $scn"
    run_sta "$cfg" "$NET_BOOTH" "$TB_BOOTH" \
        "../sim/waves/${VCD_BOOTH}_${scn}.vcd" \
        "reports/${cfg}.rpt"
done

for scn in $SCENARIOS; do
    for mode in $EXTREC_MODES; do
        cfg="${RPT_EXTREC}_${scn}_${mode}"
        echo "  booth_extrec_${WIDTH} / $scn / $mode"
        run_sta "$cfg" "$NET_EXTREC" "$TB_EXTREC" \
            "../sim/waves/${VCD_EXTREC}_${scn}_${mode}.vcd" \
            "reports/${cfg}.rpt"
    done
done

get_total() { grep "^Total" "$1" 2>/dev/null | head -1 | awk '{print $5}'; }

echo ""
echo "=== Summary (${WIDTH}-bit) ==="
printf "%-28s" "config"
for scn in $SCENARIOS; do printf " %14s" "$scn"; done
echo ""

printf "%-28s" "booth_${WIDTH}"
for scn in $SCENARIOS; do
    printf " %14s" "$(get_total reports/${RPT_BOOTH}_${scn}.rpt)"
done
echo ""

for mode in $EXTREC_MODES; do
    printf "%-28s" "booth_extrec_${WIDTH}_${mode}"
    for scn in $SCENARIOS; do
        printf " %14s" "$(get_total reports/${RPT_EXTREC}_${scn}_${mode}.rpt)"
    done
    echo ""
done
