vlog -sv comb_gp_pkg.sv
vlog -sv comb_gp.sv

vsim comb_gp  -G X_WIDTH=2 -G Y_WIDTH=2 -G NUM_ROWS=4 -G NUM_COLS=5 -G LEVELS_BACK=1 -G POPUL_SIZE=100 -G NUM_MUTAT=2 -sv_seed random -suppress 3829
run -all