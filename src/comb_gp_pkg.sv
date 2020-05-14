package comb_gp_pkg;
  `include "comb_circuit.sv"
  
  function int abs(int value);
    int out;
    if(value >= 0)
      out = value;
    else
      out = -value;
    return out;
  endfunction: abs
  
endpackage