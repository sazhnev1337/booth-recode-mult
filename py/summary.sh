#!/bin/bash
mkdir -p reports
python3 compute_accuracy.py > reports/summary_accuracy.txt
cat reports/summary_accuracy.txt
