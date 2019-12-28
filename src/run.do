vlog -sv comb_gp_pkg.sv
vlog -sv comb_gp.sv

#vsim comb_gp -G NUM_INPUTS=2 -G EXP_OUTPUTS='b1011 -G NUM_ROWS=2 -G NUM_COLS=3 -G LEVELS_BACK=2 -sv_seed random
vsim comb_gp -G NUM_INPUTS=3 -G EXP_OUTPUTS='b00101110 -G NUM_ROWS=4 -G NUM_COLS=4 -G LEVELS_BACK=2 -sv_seed random
run 500 ns