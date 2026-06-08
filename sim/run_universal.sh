#!/bin/bash

TB="booth_multiplier_exact_recoded"
DUT="booth_multiplier_approx_recoded_b_0"

iverilog -o ./vvp/$DUT \
         -y ../rtl/    \
         ./tb/tb_$TB.v  \
         && vvp ./vvp/$DUT
