#!/bin/bash
set -e

mkdir -p reports

sta -no_init -no_splash power.tcl | tee reports/power_baseline.rpt
