#!/bin/bash
# Wrapper: run gate-level simulations for all three bit-widths sequentially.
# Run from: sim/
set -e

SCRIPT="$(dirname "$0")/run_sim_width.sh"

for width in 8 16 20; do
    echo ""
    echo "========================================"
    echo "  Width: ${width}-bit"
    echo "========================================"
    bash "$SCRIPT" "$width"
done

echo ""
echo "=== All widths done ==="
ls waves/power_booth*.vcd | wc -l
