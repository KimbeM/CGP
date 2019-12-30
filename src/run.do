vlog -sv comb_gp_pkg.sv
vlog -sv comb_gp.sv

vsim comb_gp  -G NUM_INPUTS=4 -G EXP_OUTPUTS='b1011011101010110 -G NUM_ROWS=4 -G NUM_COLS=5 -G LEVELS_BACK=2 -G POPUL_SIZE=50 -G NUM_MUTAT=3 -sv_seed random
run -all