#!/bin/bash
set -e

CONFIG=$1

if [ -z "$CONFIG" ]; then
    echo "Usage: $0 <config>"
    echo "  config: naive | booth | booth_extrec"
    exit 1
fi

# Файлы RTL для каждого конфига.
case "$CONFIG" in
    naive)
        RTL_FILES="../rtl/mult_naive.v"
        TOP="mult_naive"
        ;;
    booth)
        RTL_FILES="../rtl/booth_encoder.v ../rtl/booth_ppg.v ../rtl/mult_booth.v"
        TOP="mult_booth"
        ;;
    booth_extrec)
        RTL_FILES="../rtl/booth_ppg.v ../rtl/mult_booth_extrec.v"
        TOP="mult_booth_extrec"
        ;;
    *)
        echo "Unknown config: $CONFIG"
        exit 1
        ;;
esac

mkdir -p netlists reports _gen

# Генерируем .ys для конкретного конфига.
READ_LINES=""
for f in $RTL_FILES; do
    READ_LINES="${READ_LINES}read_verilog ${f}
"
done

cat > _gen/synth_${CONFIG}.ys <<EOF
${READ_LINES}
hierarchy -check -top ${TOP}

proc
opt -full
techmap
opt -fast
flatten

dfflibmap -liberty lib/NangateOpenCellLibrary_typical.lib
abc -liberty lib/NangateOpenCellLibrary_typical.lib

opt_clean -purge
setundef -undriven -zero

tee -o reports/area_${TOP}.rpt stat -liberty lib/NangateOpenCellLibrary_typical.lib
write_verilog -noattr netlists/${TOP}.v
EOF

yosys _gen/synth_${CONFIG}.ys

echo ""
echo "=== Done: $CONFIG ==="
grep "Chip area" reports/area_${TOP}.rpt
