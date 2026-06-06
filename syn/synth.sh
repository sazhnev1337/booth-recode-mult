#!/bin/bash
set -e

# Usage: ./synth.sh CONFIG_NAME DUT_TYPE [APPROX_PAIRS]
# Examples:
#   ./synth.sh baseline 0
#   ./synth.sh exact    1
#   ./synth.sh approx_1 2 1
#   ./synth.sh approx_2 2 2

CONFIG=$1
DUT_TYPE=$2
APPROX_PAIRS=${3:-1}

if [ -z "$CONFIG" ] || [ -z "$DUT_TYPE" ]; then
    echo "Usage: $0 CONFIG_NAME DUT_TYPE [APPROX_PAIRS]"
    exit 1
fi

mkdir -p netlists reports

# Параметр для APPROX_PAIRS подаётся только если DUT_TYPE=2,
# иначе hierarchy воткнётся в неиспользованный параметр.
if [ "$DUT_TYPE" = "2" ]; then
    PARAM_LINE="hierarchy -check -top booth_multiplier_wrapper -chparam DUT_TYPE $DUT_TYPE -chparam APPROX_PAIRS $APPROX_PAIRS"
else
    PARAM_LINE="hierarchy -check -top booth_multiplier_wrapper -chparam DUT_TYPE $DUT_TYPE"
fi

cat > _synth_${CONFIG}.ys <<EOF
read_verilog ../rtl/booth_encoder.v
read_verilog ../rtl/booth_ppg.v
read_verilog ../rtl/booth_multiplier.v
read_verilog ../rtl/booth_multiplier_exact_recoded.v
read_verilog ../rtl/booth_recoder_pair_exact.v
read_verilog ../rtl/booth_multiplier_approx_recoded.v
read_verilog ../rtl/booth_recoder_pair_approx.v
read_verilog ../rtl/booth_multiplier_wrapper.v

${PARAM_LINE}

proc
opt -full
techmap
opt -fast
flatten

dfflibmap -liberty lib/NangateOpenCellLibrary_typical.lib
abc -liberty lib/NangateOpenCellLibrary_typical.lib

opt_clean -purge
setundef -undriven -zero

tee -o reports/area_${CONFIG}.rpt stat -liberty lib/NangateOpenCellLibrary_typical.lib
write_verilog -noattr netlists/${CONFIG}.v
EOF

yosys _synth_${CONFIG}.ys

echo ""
echo "=== Done: $CONFIG ==="
grep "Chip area" reports/area_${CONFIG}.rpt