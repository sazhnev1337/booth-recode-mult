#!/bin/bash
set -e

# Для baseline:
iverilog -o ./vvp/sim_baseline.vvp \
            ./tb/tb_power.v \
            ../syn/netlists/baseline.v \
            ../syn/lib/NangateOpenCellLibrary.v

vvp ./vvp/sim_baseline.vvp

mv power.vcd power_baseline.vcd
