vlog -sv cgp_pkg.sv
vlog -sv cgp_main.sv

vsim cgp_main  -G NUM_INPUTS=2 -G NUM_OUTPUTS=1 -G NUM_ROWS=3 -G NUM_COLS=4 -G LEVELS_BACK=4 -G CONST_MAX=10 -G COUNT_MAX=10 -G POPUL_SIZE=50 -G NUM_MUTAT=1 -sv_seed random -suppress 3829
set start [clock seconds]
run -all
set finish [clock seconds]
puts "[expr {$finish - $start}] seconds"