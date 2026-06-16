#!/bin/bash
# Gate-level power simulations for a single bit-width.
# Run from: sim/
#
# Usage: ./run_sim_width.sh <width>
#   width: 8 | 16 | 20
#
# Examples:
#   ./run_sim_width.sh 8
#   ./run_sim_width.sh 16
#   ./run_sim_width.sh 20
set -e

WIDTH=$1
if [ -z "$WIDTH" ]; then
    echo "Usage: $0 <width>  (8 | 16 | 20)"
    exit 1
fi

LIB="../syn/lib/NangateOpenCellLibrary.v"
NETLISTS="../syn/netlists"
SCENARIOS="uniform_fast uniform_slow gauss_fast gauss_slow"
EXTREC_MODES="standard exact approx_1 approx_2"
N=20000

mkdir -p vvp waves

case "$WIDTH" in
    8)
        TB_BOOTH="tb/tb_mult_booth_8.v"
        TB_EXTREC="tb/tb_mult_booth_extrec_8.v"
        NET_BOOTH="${NETLISTS}/mult_booth_8.v"
        NET_EXTREC="${NETLISTS}/mult_booth_extrec_8.v"
        VVP_BOOTH="vvp/sim_booth_8.vvp"
        VVP_EXTREC="vvp/sim_booth_extrec_8.vvp"
        STIM_PREFIX="stim8"
        VCD_BOOTH="power_booth8"
        VCD_EXTREC="power_booth_extrec8"
        ;;
    16)
        TB_BOOTH="tb/tb_mult_booth.v"
        TB_EXTREC="tb/tb_mult_booth_extrec.v"
        NET_BOOTH="${NETLISTS}/mult_booth.v"
        NET_EXTREC="${NETLISTS}/mult_booth_extrec.v"
        VVP_BOOTH="vvp/sim_booth_16.vvp"
        VVP_EXTREC="vvp/sim_booth_extrec_16.vvp"
        STIM_PREFIX="stim"
        VCD_BOOTH="power_booth"
        VCD_EXTREC="power_booth_extrec"
        ;;
    20)
        TB_BOOTH="tb/tb_mult_booth_20.v"
        TB_EXTREC="tb/tb_mult_booth_extrec_20.v"
        NET_BOOTH="${NETLISTS}/mult_booth_20.v"
        NET_EXTREC="${NETLISTS}/mult_booth_extrec_20.v"
        VVP_BOOTH="vvp/sim_booth_20.vvp"
        VVP_EXTREC="vvp/sim_booth_extrec_20.vvp"
        STIM_PREFIX="stim20"
        VCD_BOOTH="power_booth20"
        VCD_EXTREC="power_booth_extrec20"
        ;;
    *)
        echo "ERROR: unknown width '$WIDTH'. Use 8, 16, or 20."
        exit 1
        ;;
esac

echo "=== Compiling testbenches (${WIDTH}-bit) ==="
iverilog -o "$VVP_BOOTH"   "$TB_BOOTH"   "$NET_BOOTH"   "$LIB"
echo "  booth_${WIDTH}: compiled"
iverilog -o "$VVP_EXTREC"  "$TB_EXTREC"  "$NET_EXTREC"  "$LIB"
echo "  booth_extrec_${WIDTH}: compiled"

echo ""
echo "=== Running simulations (${WIDTH}-bit) ==="

for scn in $SCENARIOS; do
    out="waves/${VCD_BOOTH}_${scn}.vcd"
    echo "  booth_${WIDTH} / $scn"
    vvp "$VVP_BOOTH"  +STIM=data/${STIM_PREFIX}_${scn}_standard.txt +N=$N > /dev/null
    mv waves/power.vcd "$out"
done

for scn in $SCENARIOS; do
    for mode in $EXTREC_MODES; do
        out="waves/${VCD_EXTREC}_${scn}_${mode}.vcd"
        echo "  booth_extrec_${WIDTH} / $scn / $mode"
        vvp "$VVP_EXTREC" +STIM=data/${STIM_PREFIX}_${scn}_${mode}.txt +N=$N > /dev/null
        mv waves/power.vcd "$out"
    done
done

echo ""
echo "=== Done (${WIDTH}-bit): $(ls waves/${VCD_BOOTH}_*.vcd waves/${VCD_EXTREC}_*.vcd 2>/dev/null | wc -l) VCDs ==="
