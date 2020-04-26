vlog -sv comb_gp_pkg.sv
vlog -sv comb_gp.sv

vsim comb_gp  -G X_WIDTH=4 -G Y_WIDTH=5 -G NUM_ROWS=5 -G NUM_COLS=6 -G LEVELS_BACK=2 -G POPUL_SIZE=30 -G NUM_MUTAT=1 -sv_seed random -suppress 3829
run -all