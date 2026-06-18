#!/bin/bash
# Synthesis for 8-bit and 20-bit multipliers (NanGate45).
# Run from: syn/
set -e

LIB="../syn/lib/NangateOpenCellLibrary_typical.lib"
mkdir -p netlists reports _gen

synth_one() {
    local cfg=$1; local top=$2; shift 2
    local rtl_files="$*"

    # Рецепт идентичен synth.sh (16 бит): один abc-скрипт на все разрядности,
    # иначе мэппинг extrec-датапаса немонотонен по ширине (см. коммент в synth.sh).
    local ys="_gen/synth_${cfg}.ys"
    {
        for f in $rtl_files; do echo "read_verilog ${f}"; done
        echo "synth -top ${top} -flatten"
        echo "dfflibmap -liberty ${LIB}"
        echo "abc -liberty ${LIB} -script +strash;dch;map"
        echo "opt_clean -purge"
        echo "setundef -undriven -zero"
        echo "write_verilog -noattr netlists/${cfg}.v"
        echo "tee -o reports/area_${cfg}.rpt stat -liberty ${LIB}"
    } > "$ys"

    echo "  Synthesizing ${cfg}..."
    yosys -q "$ys"
    echo "  -> netlists/${cfg}.v  reports/area_${cfg}.rpt"
}

echo "=== Synthesis: 8-bit ==="
synth_one mult_booth_8     mult_booth_8     \
    ../rtl/booth_encoder.v ../rtl/booth_ppg_8.v ../rtl/mult_booth_8.v

synth_one mult_booth_extrec_8  mult_booth_extrec_8  \
    ../rtl/booth_ppg_8.v ../rtl/mult_booth_extrec_8.v

echo ""
echo "=== Synthesis: 20-bit ==="
synth_one mult_booth_20    mult_booth_20    \
    ../rtl/booth_encoder.v ../rtl/booth_ppg_20.v ../rtl/mult_booth_20.v

synth_one mult_booth_extrec_20 mult_booth_extrec_20 \
    ../rtl/booth_ppg_20.v ../rtl/mult_booth_extrec_20.v

echo ""
echo "=== Area summary ==="
grep -h "Chip area" reports/area_mult_booth_8.rpt \
                    reports/area_mult_booth_extrec_8.rpt \
                    reports/area_mult_booth_20.rpt \
                    reports/area_mult_booth_extrec_20.rpt \
    | paste - <(echo -e "mult_booth_8\nmult_booth_extrec_8\nmult_booth_20\nmult_booth_extrec_20") \
    | awk '{print $NF, $0}' | sort -k1 | awk '{$1=""; print}' || true

for rpt in reports/area_mult_booth_8.rpt \
           reports/area_mult_booth_extrec_8.rpt \
           reports/area_mult_booth_20.rpt \
           reports/area_mult_booth_extrec_20.rpt; do
    echo -n "$(basename $rpt .rpt):  "
    grep "Chip area" "$rpt" || echo "(not found)"
done
