read_liberty ../syn/lib/NangateOpenCellLibrary_typical.lib

read_verilog ../syn/netlists/baseline.v
link_design booth_multiplier_wrapper

read_sdc booth.sdc

read_vcd -scope tb_power/dut ../sim/power_baseline.vcd

report_power

exit
