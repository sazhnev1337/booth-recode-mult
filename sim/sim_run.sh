#!/bin/bash

 #DUT="booth_encoder"
 #DUT="booth_multiplier"
 DUT="booth_recoder_pair_exact"

iverilog -o $DUT -y ../rtl/ ../rtl/$DUT.v ./tb/tb_$DUT.v && vvp $DUT
