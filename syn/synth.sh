#!/bin/bash
set -e

CONFIG=$1
DUT_TYPE=$2
APPROX_PAIRS=${3:-1}
USE_ZEROED_PPG=${4:-0}
USE_LEVEL_B=${5:-0}

if [ -z "$CONFIG" ] || [ -z "$DUT_TYPE" ]; then
    echo "Usage: $0 CONFIG_NAME DUT_TYPE [APPROX_PAIRS] [USE_ZEROED_PPG] [USE_LEVEL_B]"
    exit 1
fi

mkdir -p netlists reports _gen

PARAMS="-chparam DUT_TYPE $DUT_TYPE"
if [ "$DUT_TYPE" = "2" ]; then
    PARAMS="$PARAMS -chparam APPROX_PAIRS $APPROX_PAIRS"
fi
if [ "$DUT_TYPE" != "0" ]; then
    PARAMS="$PARAMS -chparam USE_ZEROED_PPG $USE_ZEROED_PPG"
    PARAMS="$PARAMS -chparam USE_LEVEL_B $USE_LEVEL_B"
fi

cat > _gen/synth_${CONFIG}.ys <<EOF
read_verilog ../rtl/booth_encoder.v
read_verilog ../rtl/booth_ppg.v
read_verilog ../rtl/booth_ppg_zeroed.v
read_verilog ../rtl/booth_multiplier.v
read_verilog ../rtl/booth_multiplier_exact_recoded.v
read_verilog ../rtl/booth_multiplier_exact_recoded_zeroed.v
read_verilog ../rtl/booth_multiplier_exact_recoded_b.v
read_verilog ../rtl/booth_recoder_pair_exact.v
read_verilog ../rtl/booth_recoder_pair_exact_b.v
read_verilog ../rtl/booth_recoder_pair_odd_exact.v
read_verilog ../rtl/booth_multiplier_approx_recoded.v
read_verilog ../rtl/booth_multiplier_approx_recoded_zeroed.v
read_verilog ../rtl/booth_multiplier_approx_recoded_b.v
read_verilog ../rtl/booth_recoder_pair_approx.v
read_verilog ../rtl/booth_recoder_pair_approx_b.v
read_verilog ../rtl/booth_recoder_pair_odd_approx.v
read_verilog ../rtl/booth_multiplier_wrapper.v

hierarchy -check -top booth_multiplier_wrapper ${PARAMS}

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

yosys _gen/synth_${CONFIG}.ys

echo ""
echo "=== Done: $CONFIG ==="
grep "Chip area" reports/area_${CONFIG}.rpt
