vlog -sv comb_gp_pkg.sv
vlog -sv comb_gp.sv

vsim comb_gp  -G NUM_INPUTS=4 -G NUM_OUTPUTS=1 -G NUM_ROWS=4 -G NUM_COLS=4 -G LEVELS_BACK=4 -G CONST_MAX=16 -G COUNT_MAX=16 -G POPUL_SIZE=50 -G NUM_MUTAT=1 -sv_seed random -suppress 3829
run -all