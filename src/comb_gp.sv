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
  
  int                  L1_norm           = 0; //Sum of absolute deviations
  int                  parent_fitness    = 0;
  int                  offspring_fitness = 0;
  int                  num_generations   = 100000;  
  bit                  solution_exists   = 0;
  
  comb_circuit         population[POPUL_SIZE];
  comb_circuit         offspring;
  comb_circuit         best_solution;
  
  

initial begin

  //Instantiate population of combinatorial circuits
  foreach(population[i])
    population[i] = new();


  //Initialization phase
  assert (X_WIDTH  > 0 && X_WIDTH  < 6)                        else $fatal ("FAILURE! WIDTH OF X HAS NOT BEEN CONFIGURED WITHIN ALLOWED RANGE (1-5)");  
  assert (Y_WIDTH  > 0 && Y_WIDTH  < 6)                        else $fatal ("FAILURE! WIDTH OF Y HAS NOT BEEN CONFIGURED WITHIN ALLOWED RANGE (1-5)");  
  assert (NUM_ROWS    > 0 && NUM_ROWS    < 17)                 else $fatal ("FAILURE! NUMBER OF ROWS HAS NOT BEEN CONFIGURED WITHIN ALLOWED RANGE (1-16)");
  assert (NUM_COLS    > 0 && NUM_COLS    < 17)                 else $fatal ("FAILURE! NUMBER OF COLUMNS HAS NOT BEEN CONFIGURED WITHIN ALLOWED RANGE (1-16)");
  assert (LEVELS_BACK > 0 && LEVELS_BACK <= NUM_COLS)          else $fatal ("FAILURE! LEVELS BACK HAS NOT BEEN CONFIGURED WITHIN ALLOWED RANGE (1-NUM_COLS)");
  assert (NUM_MUTAT   > 0 && NUM_MUTAT <= NUM_ROWS * NUM_COLS) else $fatal ("FAILURE! NUMBER OF MUTATIONS HAS NOT BEEN CONFIGURED WITHIN ALLOWED RANGE (1-NUMBER OF NODES)");
  assert (POPUL_SIZE  > 0)                                     else $fatal ("FAILURE! POPULATION SIZE MUST BE LARGER THAN 0");


  
 
  //Main 
  for(int i=0; i<=num_generations; i++)begin
    foreach(population[i])begin
     
      if(i == 0)begin
        $display("\n");
        $display("GENERATION NUMBER: %3d", i);
        $display("\n");
      end    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
      //Evaluate fitness
      for(int j=0; j<=2**X_WIDTH-1; j++)begin
        X <= j;
        #1;
        Y = population[i].evaluate_fitness(X);
        if(EXP_OUTPUTS[j] == Y)begin
          num_pass = num_pass + 1;
        end 
      end
      
      parent_fitness = num_pass;
      
      if(num_pass != 2**X_WIDTH)begin
        $display("Number of tests passed for genotype nr %2d: %2d /%2d", i, num_pass, 2**X_WIDTH);
      end else begin
        $display("All tests passed for genotype nr %2d: %2d /%2d", i, num_pass, 2**X_WIDTH);
        num_gates = population[i].calc_num_gates();
        if(solution_exists == 1)begin
          if(best_solution.num_gates > num_gates)begin
            best_solution = population[i].copy();
            $display("An improved solution found in generation %2d, genotype %2d. Number of gates is %2d", x, i, num_gates);
            $display("Breakpoint here");
          end
        end else begin
          solution_exists = 1;
          best_solution = population[i].copy();
          $display("First viable solution found in generation %2d, genotype %2d. Number of gates is %2d", x, i, num_gates);
        end
        if(best_solution.num_gates < 4)
          $stop;
      end
      
      num_pass = 0;

      //Create mutated offspring.
      offspring =new();
      offspring = population[i].copy(); 
      offspring.mutate();
      
      //Evaluate fitness
      for(int j=0; j<=2**X_WIDTH-1; j++)begin
        X <= j;
        #1;
        Y = offspring.evaluate_fitness(X);
        if(EXP_OUTPUTS[j] == Y)begin
          num_pass = num_pass + 1;
        end 
      end      

      offspring_fitness = num_pass;     

      //If fitness for offspring is equal or better than for parent, 
      //replace parent with offspring.
      if(parent_fitness <= offspring_fitness)
        population[i] = offspring;
      
      num_pass = 0;
      
      
    end  
  end
end 

endmodule