package cgp_pkg;
  `include "cgp_circuit.sv"
  `include "tests.sv"
  `include "dot_product.sv"
  
  function int abs(int value);
    int out;
    if(value >= 0)
      out = value;
    else
      out = -value;
    return out;
  endfunction: abs
  
endpackage