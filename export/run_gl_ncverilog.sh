#!/bin/bash
# Gate-level simulation with ncverilog (Cadence).
#
# Run from: sim/
#   bash ../export/run_gl_ncverilog.sh
#
# Prerequisites (must exist in sim/ on the target machine):
#   x_run_sim_cad_gl.vc        — CAD environment: libraries, SDF, timescale
#   ../syn/netlists/mult_naive_gate.v
#   ../syn/netlists/mult_booth_gate.v
#   ../syn/netlists/mult_booth_extrec_gate.v
#
# Output: sim/waves/power_<module>_<scenario>[_<mode>].vcd
#   — identical naming convention as the iverilog flow.

set -e

# ── guard: must be run from sim/ ─────────────────────────────────────────────
if [ ! -f "x_run_sim_cad_gl.vc" ]; then
    echo "ERROR: x_run_sim_cad_gl.vc not found. Run this script from sim/."
    exit 1
fi

mkdir -p waves

SCENARIOS="uniform_fast uniform_slow gauss_fast gauss_slow"
EXTREC_MODES="standard exact approx_1 approx_2"
N=20000

# ── helper ───────────────────────────────────────────────────────────────────
# run_sim <testbench.v> <netlist.v> <output.vcd> [+ARG ...]
run_sim() {
    local tb="$1"
    local netlist="$2"
    local out="$3"
    shift 3

    # ncverilog creates INCA_libs/ work directory; remove stale state first
    # so consecutive runs don't reuse a mismatched elaboration snapshot.
    rm -rf INCA_libs

    ncverilog \
        -f x_run_sim_cad_gl.vc \
        "$tb" \
        "$netlist" \
        "$@"

    if [ ! -f "waves/power.vcd" ]; then
        echo "ERROR: waves/power.vcd not produced (target: $out)"
        exit 1
    fi
    mv waves/power.vcd "$out"
    echo "  -> $out"
}

# ── mult_naive_gate: 4 scenarios ─────────────────────────────────────────────
echo "=== mult_naive_gate ==="
for scn in $SCENARIOS; do
    echo "naive / $scn"
    run_sim \
        "tb/tb_mult_naive.v" \
        "../syn/netlists/mult_naive_gate.v" \
        "waves/power_naive_${scn}.vcd" \
        "+STIM=data/stim_${scn}_standard.txt" \
        "+N=$N"
done

# ── mult_booth_gate: 4 scenarios ─────────────────────────────────────────────
echo ""
echo "=== mult_booth_gate ==="
for scn in $SCENARIOS; do
    echo "booth / $scn"
    run_sim \
        "tb/tb_mult_booth.v" \
        "../syn/netlists/mult_booth_gate.v" \
        "waves/power_booth_${scn}.vcd" \
        "+STIM=data/stim_${scn}_standard.txt" \
        "+N=$N"
done

# ── mult_booth_extrec_gate: 4 scenarios × 4 modes ────────────────────────────
echo ""
echo "=== mult_booth_extrec_gate ==="
for scn in $SCENARIOS; do
    for mode in $EXTREC_MODES; do
        echo "booth_extrec / $scn / $mode"
        run_sim \
            "tb/tb_mult_booth_extrec.v" \
            "../syn/netlists/mult_booth_extrec_gate.v" \
            "waves/power_booth_extrec_${scn}_${mode}.vcd" \
            "+STIM=data/stim_${scn}_${mode}.txt" \
            "+N=$N"
    done
done

echo ""
echo "=== Done: $(ls waves/power_*.vcd | wc -l) VCD files ==="
ls waves/power_*.vcd
