vlog -sv comb_gp_pkg.sv
vlog -sv comb_gp.sv

vsim comb_gp  -G X_WIDTH=2 -G Y_WIDTH=3 -G NUM_ROWS=3 -G NUM_COLS=3 -G LEVELS_BACK=2 -G POPUL_SIZE=50 -G NUM_MUTAT=2 -sv_seed random -suppress 3829
run -all