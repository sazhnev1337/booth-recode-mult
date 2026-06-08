#!/bin/bash
set -e

mkdir -p ../sim/data

python3 gen_stimulus.py uniform 1   ../sim/data/stimulus_uniform_fast.txt
python3 gen_stimulus.py uniform 50  ../sim/data/stimulus_uniform_slow.txt
python3 gen_stimulus.py gauss   50  ../sim/data/stimulus_gauss_slow.txt

echo ""
echo "Stimulus files:"
ls -lh ../sim/data/stimulus_*.txt
