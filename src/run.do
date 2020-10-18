vlog -sv cgp_pkg.sv
vlog -sv cgp_main.sv

vsim cgp_main  -G NUM_INPUTS=3 -G NUM_OUTPUTS=2 -G NUM_ROWS=5 -G NUM_COLS=5 -G LEVELS_BACK=5 -G CONST_MAX=10 -G COUNT_MAX=10 -G POPUL_SIZE=50 -G NUM_MUTAT=1 -sv_seed random -suppress 3829
run -all