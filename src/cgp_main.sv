module cgp_main;
  timeunit 1ns;
  import cgp_pkg::*;
  
  parameter            NUM_INPUTS;
  parameter            NUM_OUTPUTS;
  parameter            NUM_ROWS;
  parameter            NUM_COLS;
  parameter            LEVELS_BACK;
  parameter            CONST_MAX;
  parameter            COUNT_MAX;
  parameter            POPUL_SIZE;
  parameter            NUM_MUTAT;

    
  int X[NUM_INPUTS]; 
  int Y[NUM_OUTPUTS];
  int Y_EXP[NUM_OUTPUTS]; //Expected output
  
  int Y_FB[POPUL_SIZE];
  
  int                  L1_norm           = 0; //Sum of absolute deviations
  int                  mean_sad      = 0;
  int                  mean_sad_prev = 0;
  int                  sad_cnt       = 0;
  int                  num_generations   = 10000000;  
  bit                  solution_exists   = 0;
  
  cgp_circuit          population[POPUL_SIZE];
  cgp_circuit          offspring[4];
  cgp_circuit          best_offspring;
  cgp_circuit          best_solution;
  dot_product          dp;
  tests                t;

initial begin

  //Initialization phase
  assert (NUM_INPUTS  > 0 && NUM_INPUTS  < 6)                    else $fatal ("FAILURE! NUMBER OF INPUTS HAS NOT BEEN CONFIGURED WITHIN ALLOWED RANGE (1-5)");  
  assert (NUM_OUTPUTS > 0 && NUM_OUTPUTS < 6)                    else $fatal ("FAILURE! NUMBER OF OUTPUTS HAS NOT BEEN CONFIGURED WITHIN ALLOWED RANGE (1-5)");  
  assert (NUM_ROWS    > 0 && NUM_ROWS    < 17)                   else $fatal ("FAILURE! NUMBER OF ROWS HAS NOT BEEN CONFIGURED WITHIN ALLOWED RANGE (1-16)");
  assert (NUM_COLS    > 0 && NUM_COLS    < 17)                   else $fatal ("FAILURE! NUMBER OF COLUMNS HAS NOT BEEN CONFIGURED WITHIN ALLOWED RANGE (1-16)");
  assert (LEVELS_BACK > 0 && LEVELS_BACK <= NUM_COLS)            else $fatal ("FAILURE! LEVELS BACK HAS NOT BEEN CONFIGURED WITHIN ALLOWED RANGE (1-NUM_COLS)");
  assert (NUM_MUTAT   > 0 && NUM_MUTAT   <= NUM_ROWS * NUM_COLS) else $fatal ("FAILURE! NUMBER OF MUTATIONS HAS NOT BEEN CONFIGURED WITHIN ALLOWED RANGE (1-NUMBER OF NODES)");
  assert (COUNT_MAX   > 0 && COUNT_MAX   < 101)                  else $fatal ("FAILURE! MAX VALUE OF COUNTERS HAS NOT BEEN CONFIGURED WITHIN ALLOWED RANGE (1-16)");
  assert (CONST_MAX   > 0 && CONST_MAX   < 101)                  else $fatal ("FAILURE! MAX VALUE OF CONSTANTS HAS NOT BEEN CONFIGURED WITHIN ALLOWED RANGE (1-16)");
  assert (POPUL_SIZE  > 0)                                       else $fatal ("FAILURE! POPULATION SIZE MUST BE LARGER THAN 0");

  //Instantiate population of combinatorial circuits
  foreach(population[i])
    population[i] = new();

  best_solution = new();            //Create "dummy" best solution object
  
  dp = new();
  t  = new();
 
  //Main 
  for(int gen=0; gen<=num_generations; gen++)begin
    foreach(population[i])begin
     
      if(i == 0)begin
        $display("\n");
        $display("GENERATION NUMBER: %3d", gen);
        $display("\n");
      end    
        
      population[i].reset();  

      //Test this individual
      //t.tri_wave_test(population[i], 4, 2, population[i].sad);
      //t.pwm_test(population[i], 10, 3, 3, population[i].sad);
      t.register_test(population[i], population[i].sad);

      //Replace current best solution with improved solution
      if(best_solution.sad > population[i].sad && population[i].sad >= 0)begin 
        best_solution = population[i].copy();
        $display("An improved solution found in generation %2d, genotype %2d. Sum of Absolute Differences is %2d", gen, i, best_solution.sad);                      
      end  
       
      
      if(population[i].sad == 0)begin
        population[i].calc_resource_util();
        population[i].calc_score();
        if(population[i].score < best_solution.score)begin// && population[i].score < 80)begin
          best_solution = population[i].copy();
          population[i].print_resource_util();
          $display("Solution found in generation %2d, genotype %2d with number of slices: %2d", gen, i, best_solution.num_slices); 
          $stop;
        end
      end       

      //Create mutated offspring.
      foreach(offspring[k])begin
        offspring[k] = population[i].copy(); 
        offspring[k].reset();
        offspring[k].mutate();
      
        //Test this offspring individual
        //t.tri_wave_test(offspring[k], 4, 2, offspring[k].sad);
        //t.pwm_test(offspring[k], 10, 3, 3, offspring[k].sad);
        t.register_test(offspring[k], offspring[k].sad);

        if(k == 0)
          best_offspring = offspring[k].copy;
        else if(best_offspring.sad > offspring[k].sad)
          best_offspring = offspring[k].copy;
   
      end 
 

      //If sad for offspring is equal or better than for parent, 
      //replace parent with offspring.
      if(population[i].sad >= best_offspring.sad)
        population[i] = best_offspring.copy();    
         
    end  
   
    $display("Best SAD: %d", best_solution.sad);
  
  end
end 

endmodule