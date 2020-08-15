vlog -sv comb_gp_pkg.sv
vlog -sv comb_gp.sv

vsim comb_gp  -G NUM_INPUTS=3 -G NUM_OUTPUTS=1 -G NUM_ROWS=2 -G NUM_COLS=3 -G LEVELS_BACK=3 -G CONST_MAX=100 -G COUNT_MAX=100 -G POPUL_SIZE=50 -G NUM_MUTAT=1 -sv_seed random -suppress 3829
run -all