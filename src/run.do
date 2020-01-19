vlog -sv comb_gp_pkg.sv
vlog -sv comb_gp.sv

vsim comb_gp  -G NUM_INPUTS=3 -G EXP_OUTPUTS='b10110110 -G NUM_ROWS=4 -G NUM_COLS=5 -G LEVELS_BACK=2 -G POPUL_SIZE=50 -G NUM_MUTAT=2 -sv_seed random -suppress 3829
run -all