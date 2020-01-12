vlog -sv comb_gp_pkg.sv
vlog -sv comb_gp.sv

#vsim comb_gp  -G NUM_INPUTS=2 -G EXP_OUTPUTS='b1011 -G NUM_ROWS=4 -G NUM_COLS=5 -G LEVELS_BACK=2 -G POPUL_SIZE=50 -G NUM_MUTAT=3 -sv_seed random
vsim comb_gp  -G NUM_INPUTS=2 -G EXP_OUTPUTS='b1011 -G NUM_ROWS=3 -G NUM_COLS=3 -G LEVELS_BACK=2 -G POPUL_SIZE=50 -G NUM_MUTAT=3
run -all