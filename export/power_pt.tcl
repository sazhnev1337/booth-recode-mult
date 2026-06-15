###############################################################################
#  power_pt.tcl  —  power analysis for pt_shell
#
#  Run from: pwr/
#    pt_shell -f ../export/power_pt.tcl
#
#  Prerequisites:
#    ../syn/netlists/mult_booth_gate.v
#    ../syn/netlists/mult_booth_extrec_gate.v
#    ../sim/waves/power_<module>_<scenario>[_<mode>].vcd  (from ncverilog run)
#    booth.sdc                                             (clock constraint)
#
#  Libraries: add your read_db / set_link_library calls in the section below.
#  Output:    pwr/reports/power_<module>_<scenario>[_<mode>].rpt
###############################################################################

# ── Libraries (fill in) ──────────────────────────────────────────────────────
#
# set_link_library { * your_lib.db }
# set_target_library your_lib.db
# read_db your_lib.db
#
# ─────────────────────────────────────────────────────────────────────────────

set NETLIST_DIR "../syn/netlists"
set VCD_DIR     "../sim/waves"
set RPT_DIR     "rpt"
set SDC         "booth.sdc"

set SCENARIOS    {uniform_fast uniform_slow gauss_fast gauss_slow}
set EXTREC_MODES {standard exact approx_1 approx_2}

file mkdir $RPT_DIR

# ── helper ───────────────────────────────────────────────────────────────────
# measure_power <vcd_file> <strip_path> <report_file> <design name>
proc measure_power {vcd strip_path rpt des} {
    reset_switching_activity
    read_vcd -strip_path $strip_path $vcd
    set_power_analysis_options -waveform_format out -waveform_output des
    update_power
    redirect $rpt { report_power }
    puts "  -> $rpt"
}

# ── mult_booth_gate ───────────────────────────────────────────────────────────
puts "\n=== mult_booth_gate ==="

read_verilog ${NETLIST_DIR}/mult_booth_gate.v
link_design mult_booth
create_clock -period 2.036 [get_ports {clk}]

foreach scn $SCENARIOS {
    puts "booth / $scn"
    measure_power \
        "${VCD_DIR}/power_booth_${scn}.vcd" \
        "tb_mult_booth/dut" \
        "${RPT_DIR}/power_booth_${scn}.rpt" "booth_multiplier"
}

# ── mult_booth_extrec_gate ───────────────────────────────────────────────────
puts "\n=== mult_booth_extrec_gate ==="

read_verilog ${NETLIST_DIR}/mult_booth_extrec_gate.v
link_design mult_booth_extrec
read_sdc $SDC

foreach scn $SCENARIOS {
    foreach mode $EXTREC_MODES {
        puts "booth_extrec / $scn / $mode"
        measure_power \
            "${VCD_DIR}/power_booth_extrec_${scn}_${mode}.vcd" \
            "tb_mult_booth_extrec/dut" \
            "${RPT_DIR}/power_booth_extrec_${scn}_${mode}.rpt" "booth_multiplier_extrec"
    }
}

puts "\n=== Done: [llength [glob ${RPT_DIR}/power_*.rpt]] reports ==="

exit
