vlog -sv comb_gp_pkg.sv
vlog -sv comb_gp.sv

vsim comb_gp  -G X_WIDTH=2 -G Y_WIDTH=1 -G NUM_ROWS=2 -G NUM_COLS=2 -G LEVELS_BACK=1 -G POPUL_SIZE=1 -G NUM_MUTAT=1 -sv_seed random -suppress 3829
run -all