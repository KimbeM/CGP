module comb_gp;
  timeunit 1ns;
  import comb_gp_pkg::*;
  
  parameter           NUM_INPUTS;
  parameter           EXP_OUTPUTS;
  parameter           NUM_ROWS;
  parameter           NUM_COLS;
  parameter           LEVELS_BACK;
  
  bit[NUM_INPUTS-1:0] INPUTS;
  bit                 OUT;
  
  int                 num_pass  = 0;
  int                 num_gates = 0;
  
  comb_circuit        population[50];

initial begin

  //Instantiate population of combinatorial circuits
  foreach(population[i])
    population[i] = new();


  //Initialization phase
  assert (NUM_INPUTS  > 0 && NUM_INPUTS  < 6)         else $fatal ("FAILURE! NUMBER OF INPUTS HAS NOT BEEN CONFIGURED WITHIN ALLOWED RANGE (1-5)");  
  assert (NUM_ROWS    > 0 && NUM_ROWS    < 17)        else $fatal ("FAILURE! NUMBER OF ROWS HAS NOT BEEN CONFIGURED WITHIN ALLOWED RANGE (1-16)");
  assert (NUM_COLS    > 0 && NUM_COLS    < 17)        else $fatal ("FAILURE! NUMBER OF COLUMNS HAS NOT BEEN CONFIGURED WITHIN ALLOWED RANGE (1-16)");
  assert (LEVELS_BACK > 0 && LEVELS_BACK <= NUM_COLS) else $fatal ("FAILURE! LEVELS BACK HAS NOT BEEN CONFIGURED WITHIN ALLOWED RANGE (1-NUM_COLS)");

 
  //Test phase
  foreach(population[i])begin
    for(int j=0; j<=2**NUM_INPUTS-1; j++)begin
      INPUTS <= j;
      #1;
      OUT = population[i].evaluate_fitness(INPUTS);
      if(EXP_OUTPUTS[j] == OUT)begin
        num_pass = num_pass + 1;
      end 
    end
    
    if(num_pass != 2**NUM_INPUTS)begin
      $display("Fitness for genotype nr %2d: %2d /%2d", i, num_pass, 2**NUM_INPUTS);
      num_pass = 0;
    end else begin
      num_gates = population[i].calc_num_gates();
      $display("Full fitness achieved for genotype nr %2d with %2d gates. Terminating program", i, num_gates);
      $stop;
    end
  end

end 

endmodule