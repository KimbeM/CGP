vlog -sv comb_gp_pkg.sv
vlog -sv comb_gp.sv

vsim comb_gp  -G NUM_INPUTS=3 -G NUM_OUTPUTS=1 -G NUM_ROWS=5 -G NUM_COLS=5 -G LEVELS_BACK=5 -G CONST_MAX=20 -G COUNT_MAX=20 -G POPUL_SIZE=50 -G NUM_MUTAT=1 -sv_seed random -suppress 3829
run -all