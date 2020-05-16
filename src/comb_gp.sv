module comb_gp;
  timeunit 1ns;
  import comb_gp_pkg::*;
  
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
  
  int                  L1_norm           = 0; //Sum of absolute deviations
  int                  mean_fitness      = 0;
  int                  mean_fitness_prev = 0;
  int                  fitness_cnt       = 0;
  int                  num_generations   = 10000000;  
  bit                  solution_exists   = 0;
  
  comb_circuit         population[POPUL_SIZE];
  comb_circuit         offspring[4];
  comb_circuit         best_offspring;
  comb_circuit         best_solution;

  
  task test(input comb_circuit individual, output int out);
    
    //Clear L1_norm before testing this individual
    L1_norm = 0;
    
    //First clock cycle
    //X[0]     = 1;
    //Y_EXP[0] = 0;
    //#1;
    //
    ////Next three clock cycles          
    //X[0] = 0;
    //for(int j=0; j<3; j++)begin
    //  Y_EXP[0] = 3+j;
    //  Y       = individual.evaluate_outputs(X);
    //  L1_norm = L1_norm + abs(Y[0] - Y_EXP[0]);   
    //  #1;        
    //end
    
    for(int j=0; j<7; j++)begin
      Y_EXP[0] = (j%3)*12+6;
      Y       = individual.evaluate_outputs(X);
      L1_norm = L1_norm + abs(Y[0] - Y_EXP[0]);
      #1;            
    end    
    
    out = L1_norm; 
  endtask: test


initial begin

  //Initialization phase
  assert (NUM_INPUTS  > 0 && NUM_INPUTS  < 6)                    else $fatal ("FAILURE! NUMBER OF INPUTS HAS NOT BEEN CONFIGURED WITHIN ALLOWED RANGE (1-5)");  
  assert (NUM_OUTPUTS > 0 && NUM_OUTPUTS < 6)                    else $fatal ("FAILURE! NUMBER OF OUTPUTS HAS NOT BEEN CONFIGURED WITHIN ALLOWED RANGE (1-5)");  
  assert (NUM_ROWS    > 1 && NUM_ROWS    < 17)                   else $fatal ("FAILURE! NUMBER OF ROWS HAS NOT BEEN CONFIGURED WITHIN ALLOWED RANGE (1-16)");
  assert (NUM_COLS    > 0 && NUM_COLS    < 17)                   else $fatal ("FAILURE! NUMBER OF COLUMNS HAS NOT BEEN CONFIGURED WITHIN ALLOWED RANGE (1-16)");
  assert (LEVELS_BACK > 0 && LEVELS_BACK <= NUM_COLS)            else $fatal ("FAILURE! LEVELS BACK HAS NOT BEEN CONFIGURED WITHIN ALLOWED RANGE (1-NUM_COLS)");
  assert (NUM_MUTAT   > 0 && NUM_MUTAT   <= NUM_ROWS * NUM_COLS) else $fatal ("FAILURE! NUMBER OF MUTATIONS HAS NOT BEEN CONFIGURED WITHIN ALLOWED RANGE (1-NUMBER OF NODES)");
  assert (COUNT_MAX   > 0 && COUNT_MAX   < 17)                   else $fatal ("FAILURE! MAX VALUE OF COUNTERS HAS NOT BEEN CONFIGURED WITHIN ALLOWED RANGE (1-16)");
  assert (CONST_MAX   > 0 && CONST_MAX   < 17)                   else $fatal ("FAILURE! MAX VALUE OF CONSTANTS HAS NOT BEEN CONFIGURED WITHIN ALLOWED RANGE (1-16)");
  assert (POPUL_SIZE  > 0)                                       else $fatal ("FAILURE! POPULATION SIZE MUST BE LARGER THAN 0");

  //Instantiate population of combinatorial circuits
  foreach(population[i])
    population[i] = new();

  best_solution = new();            //Create "dummy" best solution object
  
 
  //Main 
  for(int gen=0; gen<=num_generations; gen++)begin
    foreach(population[i])begin
     
      if(i == 0)begin
        $display("\n");
        $display("GENERATION NUMBER: %3d", gen);
        $display("\n");
      end    
        
      population[i].clear_registers();
      population[i].clear_counters();

      //Test this individual
      test(population[i], population[i].fitness);

      //Replace current best solution with improved solution
      if(best_solution.fitness > population[i].fitness)begin 
        best_solution = population[i].copy();
        $display("An improved solution found in generation %2d, genotype %2d. Fitness is %2d", gen, i, best_solution.fitness);                      
      end  
       
      
      if(population[i].fitness == 0)begin
        population[i].calc_resource_util();
        population[i].calc_score();
        if(population[i].score < best_solution.score)begin
          best_solution = population[i].copy();
          population[i].print_resource_util();
          $display("Solution found in generation %2d, genotype %2d with score of %2d", gen, i, best_solution.score); 
          $display("Resource utilization: %2d gates, %2d registers, %2d adders, %2d multipliers and %2d counters", best_solution.num_gates, best_solution.num_regs, best_solution.num_adders, best_solution.num_mults, best_solution.num_cnt);           
          $stop;
        end
      end       

      //Create mutated offspring.
      foreach(offspring[k])begin
        offspring[k] = population[i].copy(); 
        offspring[k].clear_registers();
        offspring[k].clear_counters();
        offspring[k].mutate();
      
        //Test this offspring individual
        test(offspring[k], offspring[k].fitness);

        if(k == 0)
          best_offspring = offspring[k].copy;
        else if(best_offspring.fitness > offspring[k].fitness)
          best_offspring = offspring[k].copy;
   
      end 
 

      //If fitness for offspring is equal or better than for parent, 
      //replace parent with offspring.
      if(population[i].fitness >= best_offspring.fitness)
        population[i] = best_offspring.copy();    
         
    end  
   
    $display("Best fitness: %d", best_solution.fitness);
  
  end
end 

endmodule