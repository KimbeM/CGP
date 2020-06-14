class dot_product#(parameter NUM_INPUTS);

  parameter NUM_VECTORS = 3; //Number of stimulus vectors for dot product test
  
  typedef int out_type[NUM_INPUTS];

  int fd;
  int dp_coeffs[NUM_INPUTS];
  int stim_vector[NUM_VECTORS][NUM_INPUTS];


  function new();
        
    for(int i=0; i<NUM_INPUTS; i++)begin
      dp_coeffs[i]    = $urandom_range(0, 16);
      foreach(stim_vector[j])
        stim_vector[j][i] = $urandom_range(0, 16);      
    end    
    
    //Write dot product coefficient content to file
    fd = $fopen ("./dp_coeffs.txt", "w");
    for (int i = 0; i < NUM_INPUTS; i++) begin
      $fdisplay (fd, "dp_coeffs[%1d] = %1d", i, dp_coeffs[i]);
    end
    $fclose(fd);     
    
    //Write stim_vector content to file
    fd = $fopen ("./stim_vectors.txt", "w");
    foreach(stim_vector[j])begin
      for (int i = 0; i < NUM_INPUTS; i++) begin
        $fdisplay (fd, "stim_vector[%1d][%1d] = %1d", j, i, stim_vector[j][i]);        
      end
    end
    $fclose(fd); 
      
  endfunction: new
  
  function int get_num_tests;
    return NUM_VECTORS;
  endfunction: get_num_tests
  
  function out_type get_stim_vector(int idx);
    return stim_vector[idx];
  endfunction: get_stim_vector
  
  function int dp_expected(int idx);
    int out = 0;
    
    foreach(stim_vector[idx][i])
      out = out + (stim_vector[idx][i] * dp_coeffs[i]);
    
    return out;
  endfunction: dp_expected
  

endclass: dot_product