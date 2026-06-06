#!/bin/bash

DUT="approx_sweep"

iverilog -o ./vvp/$DUT \
         -y ../rtl/    \
         ./tb/tb_$DUT.v  \
         && vvp ./vvp/$DUT