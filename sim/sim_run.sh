#!/bin/bash

# DUT="booth_encoder"
# DUT="booth_multiplier"
# DUT="booth_recoder_pair_exact"
DUT="booth_recoder_pair_approx"
# DUT="booth_multiplier_exact_recoded"

iverilog -o ./vvp/$DUT -y ../rtl/ ../rtl/$DUT.v ./tb/tb_$DUT.v && vvp ./vvp/$DUT