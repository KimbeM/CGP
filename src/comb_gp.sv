module comb_gp;
  timeunit 1ns;
  import comb_gp_pkg::*;
  
  parameter            X_WIDTH;
  parameter            Y_WIDTH;
  parameter            NUM_ROWS;
  parameter            NUM_COLS;
  parameter            LEVELS_BACK;
  parameter            POPUL_SIZE;
  parameter            NUM_MUTAT;
  
  bit[X_WIDTH-1:0]     X;
  bit[Y_WIDTH-1:0]     Y;
  bit[Y_WIDTH-1:0]     Y_EXP             = 0; //Expected output
  
  int                  L1_norm           = 0; //Sum of absolute deviations
  int                  mean_fitness      = 0;
  int                  mean_fitness_prev = 0;
  int                  fitness_cnt       = 0;
  int                  num_generations   = 1000000;  
  bit                  solution_exists   = 0;
  
  comb_circuit         population[POPUL_SIZE];
  comb_circuit         offspring;
  comb_circuit         best_solution;
  
  function bit[Y_WIDTH-1:0] get_expected_y(bit[X_WIDTH-1:0] X);
    bit[Y_WIDTH-1:0] Y;
    Y = X+1; //Fitness function
    return Y;
  endfunction: get_expected_y  
  

initial begin

  //Instantiate population of combinatorial circuits
  foreach(population[i])
    population[i] = new();

  best_solution = new();            //Create "dummy" best solution object


  //Initialization phase
  assert (X_WIDTH  > 0 && X_WIDTH  < 6)                        else $fatal ("FAILURE! WIDTH OF X HAS NOT BEEN CONFIGURED WITHIN ALLOWED RANGE (1-5)");  
  assert (Y_WIDTH  > 0 && Y_WIDTH  < 6)                        else $fatal ("FAILURE! WIDTH OF Y HAS NOT BEEN CONFIGURED WITHIN ALLOWED RANGE (1-5)");  
  assert (NUM_ROWS    > 0 && NUM_ROWS    < 17)                 else $fatal ("FAILURE! NUMBER OF ROWS HAS NOT BEEN CONFIGURED WITHIN ALLOWED RANGE (1-16)");
  assert (NUM_COLS    > 0 && NUM_COLS    < 17)                 else $fatal ("FAILURE! NUMBER OF COLUMNS HAS NOT BEEN CONFIGURED WITHIN ALLOWED RANGE (1-16)");
  assert (LEVELS_BACK > 0 && LEVELS_BACK <= NUM_COLS)          else $fatal ("FAILURE! LEVELS BACK HAS NOT BEEN CONFIGURED WITHIN ALLOWED RANGE (1-NUM_COLS)");
  assert (NUM_MUTAT   > 0 && NUM_MUTAT <= NUM_ROWS * NUM_COLS) else $fatal ("FAILURE! NUMBER OF MUTATIONS HAS NOT BEEN CONFIGURED WITHIN ALLOWED RANGE (1-NUMBER OF NODES)");
  assert (POPUL_SIZE  > 0)                                     else $fatal ("FAILURE! POPULATION SIZE MUST BE LARGER THAN 0");


  
 
  //Main 
  for(int gen=0; gen<=num_generations; gen++)begin
    foreach(population[i])begin
     
      if(i == 0)begin
        $display("\n");
        $display("GENERATION NUMBER: %3d", gen);
        $display("\n");
      end    
    
      L1_norm = 0;
    
      //Evaluate fitness
      for(int j=0; j<=2**X_WIDTH-1; j++)begin
        X <= j;
        #1;
        Y_EXP   = get_expected_y(X); 
        Y       = population[i].evaluate_outputs(X);
        L1_norm = L1_norm + abs(Y - Y_EXP); 
      end
      
      population[i].fitness = L1_norm;
      
      //parent_fitness = L1_norm;
      
      if(population[i].fitness > 0)begin
        //$display("Fitness for genotype nr %2d: %2d", i, population[i].fitness); 
      end else if(best_solution.fitness > population[i].fitness)begin 
        best_solution = population[i].copy();
        if(best_solution.fitness == 0)begin
          best_solution.calc_num_gates();
          $display("Solution found in generation %2d, genotype %2d with %2d gates", gen, i, best_solution.num_gates); 
          $stop;
        end else begin
          $display("An improved solution found in generation %2d, genotype %2d. Fitness is %2d", gen, i, best_solution.fitness);              
        end        
      end 

      //Create mutated offspring.
      offspring = new();
      offspring = population[i].copy(); 
      offspring.mutate();
      
      L1_norm = 0;
    
      //Evaluate fitness
      for(int j=0; j<=2**X_WIDTH-1; j++)begin
        X <= j;
        #1;
        Y_EXP   = get_expected_y(X); 
        Y       = offspring.evaluate_outputs(X);
        L1_norm = L1_norm + abs(Y - Y_EXP); 
      end     
      
      offspring.fitness = L1_norm;
      

      //If fitness for offspring is equal or better than for parent, 
      //replace parent with offspring.
      if(population[i].fitness >= offspring.fitness)
        population[i] = offspring;      
      
      
      
    end  
    
    mean_fitness_prev = mean_fitness;
    mean_fitness      = 0;
    for(int i=0; i<POPUL_SIZE; i++)
      mean_fitness = mean_fitness + population[i].fitness;
    mean_fitness = mean_fitness/POPUL_SIZE;
    
    $display("Mean fitness: %d", mean_fitness);    
    
    if(mean_fitness >= mean_fitness_prev)
      fitness_cnt = fitness_cnt + 1;
    else
      fitness_cnt = 0;
      
    if(fitness_cnt == 2000)begin
      foreach(population[i])
        population[i] = new();      
    end
  
  end
end 

endmodule