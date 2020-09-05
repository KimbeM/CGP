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
  
  int Y_FB[POPUL_SIZE];
  
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
  dot_product          dp;
  
  /*

  task test(input comb_circuit individual, output int out); 
    int num_tests;
    
    num_tests = dp.get_num_tests;
    
    //Clear L1_norm before testing this individual
    L1_norm = 0; 
    
    for(int i=0; i<num_tests; i++)begin   
      //Clear registers and counters to avoid faulty results
      individual.clear_registers();
      individual.clear_counters();
      
      //Get expected dot product output for one stimulus vector at a time
      Y_EXP[0] = dp.dp_expected(i);
      
      X = dp.get_stim_vector(i);
      
      //Evaluate output of digital circuit
      Y = individual.evaluate_outputs(X);
      for(int j=0; j<NUM_OUTPUTS; j++)begin
       L1_norm = L1_norm + abs(Y[0] - Y_EXP[0]);
       if(L1_norm < 0)
         L1_norm = 2**31-1;  //Saturate to max if L1 norm overflowed
       #1;  
      end    
    end
 
    out = L1_norm; 
  endtask: test

  
  //PWM with enable input
  task test(input comb_circuit individual, output int out);
    const int pwm_period  = 20;
    const int num_periods = 2;
    const int duty_cycle  = 2;
    
    L1_norm = 0;    
    
    X[0] = 0;
    X[1] = duty_cycle;
    
    for(int t=0; t<pwm_period; t++)begin
      Y = individual.evaluate_outputs(X);
      Y_EXP[0] = 0;
      L1_norm = L1_norm + abs(Y[0] - Y_EXP[0]);
      #1;
    end 
    
    
    X[0] = 1;
    X[1] = duty_cycle;      

    for(int i=0; i<num_periods; i++)begin
      for(int t=0; t<pwm_period; t++)begin
        if(t < X[1])
          Y_EXP[0] = 1;
        else
          Y_EXP[0] = 0;
        Y = individual.evaluate_outputs(X);
        L1_norm = L1_norm + abs(Y[0] - Y_EXP[0]);
        #1;
      end 
    end    
    
    out = L1_norm;
  endtask: test

  */
  
  //Square wave with selectable duty cycle
  task test(input comb_circuit individual, output int out);
    const int peak       = 10;
    const int num_periods = 3;
        
    L1_norm = 0;      
        
    X[0] = 0;
        
    for(int i=0; i<num_periods; i++)begin
      for(int j=0; j<peak; j++)begin
          X[1]     = Y[0];    
          Y        = individual.evaluate_outputs(X);         
          if(i==0)
            Y_EXP[0] = j;
          else if(i==1)
            Y_EXP[0] = j*2;
          else
            Y_EXP[0] = 0;
          L1_norm = L1_norm + abs(Y[0] - Y_EXP[0]);
          if(L1_norm < 0)
            L1_norm = 2**31-1;  //Saturate to max if L1 norm overflowed        
          #1;
      end
    end
    
    out = L1_norm;
  endtask: test   
  
  /*
  //Square wave with selectable duty cycle
  task test(input comb_circuit individual, output int out);
    const int pwm_period  = 5;
    const int num_periods = 2;
    const int duty_cycle  = pwm_period/5;
        
    L1_norm = 0;      
        
    X[0] = 0;
    X[1] = 0;
    X[2] = 0;    
        
    for(int i=0; i<num_periods; i++)begin
      for(int t=0; t<pwm_period; t++)begin
        Y = individual.evaluate_outputs(X);         
        if(t < duty_cycle)begin
          Y_EXP[0] = 5;
        end else begin
          Y_EXP[0] = -2;
        end
        L1_norm = L1_norm + abs(Y[0] - Y_EXP[0]);
        if(L1_norm < 0)
          L1_norm = 2**31-1;  //Saturate to max if L1 norm overflowed        
        #1;
      end 
    end
    
    out = L1_norm;
  endtask: test  
  
  //Triangle wave
  task test(input comb_circuit individual, output int out);
    const int peak_val  = 8;
    const int num_periods = 2;
        
    L1_norm = 0;      
        
    X[0] = 0;
    X[1] = 0;
    X[2] = 0;    
        
    for(int i=0; i<num_periods; i++)begin
      for(int j=0; j<=peak_val; j++)begin
        Y_EXP[0] = j;
        Y = individual.evaluate_outputs(X);   
        L1_norm = L1_norm + abs(Y[0] - Y_EXP[0]);
        if(L1_norm < 0)
          L1_norm = 2**31-1;  //Saturate to max if L1 norm overflowed        
        #1;        
      end
      for(int j=peak_val-1; j>=0; j--)begin
        Y_EXP[0] = j;
        Y = individual.evaluate_outputs(X);   
        L1_norm = L1_norm + abs(Y[0] - Y_EXP[0]);
        if(L1_norm < 0)
          L1_norm = 2**31-1;  //Saturate to max if L1 norm overflowed        
        #1;        
      end
    end
    
    out = L1_norm;
  endtask: test   
 
  /*
  
  task stimulate_x(input bit[NUM_INPUTS-1:0] mask, input int idx);

    foreach(X[k])begin
      X[k] = mask[k];
    end
    
    X[NUM_INPUTS-1] = Y_FB[idx];

  endtask: stimulate_x  
  
  task check_result(input comb_circuit individual, input int idx, input int exp, output int result);

    Y_EXP[0] = exp;
    Y = individual.evaluate_outputs(X); 
    Y_FB[idx]= Y[0];    
    L1_norm = L1_norm + abs(Y[0] - Y_EXP[0]);
    if(L1_norm < 0)
      L1_norm = 2**31-1;  //Saturate to max if L1 norm overflowed   
      
    #1;

  endtask: check_result    
  
  //Automata counter
  task test(input comb_circuit individual, input int idx, output int out);
     
    int result;
        
    L1_norm = 0;     

    //X[0] increases DUT output by one
    //X[1] resets output
    //X[2] is a registered feedback from Y[0]
       
    //Toggle X[0] and check that Y is incremented by one after one clock cycle
    stimulate_x('b001, idx);
    check_result(individual, idx, 0, result); //Expect zero

    for(int i=0; i<6; i++)begin
      stimulate_x('b000, idx);
      check_result(individual, idx, 1, result); //Expect increment
    end
    
    //Toggle X[0] and check that Y is incremented by one after one clock cycle
    stimulate_x('b001, idx);
    check_result(individual, idx, 1, result); //Expect one 
    stimulate_x('b000, idx);
    check_result(individual, idx, 2, result); //Expect increment 
    

    for(int i=0; i<3; i++)begin
      stimulate_x('b000, idx);
      check_result(individual, idx, 2, result); //Expect two
    end
    
    //Toggle X[1] (reset) and check that Y is set to zero after one clock cycle
    stimulate_x('b010, idx); 
    check_result(individual, idx, 2, result); //Expect two     
    stimulate_x('b000, idx); 
    check_result(individual, idx, 0, result); //Expect zero (reset)     
    
    
    //Toggle X[0] for two cycles and check that Y is incremented by two
    stimulate_x('b001, idx);
    check_result(individual, idx, 0, result); //Expect zero     
    stimulate_x('b001, idx);
    check_result(individual, idx, 1, result); //Expect increment 
    stimulate_x('b000, idx);
    check_result(individual, idx, 2, result); //Expect increment 
    
    //Toggle X[0] for one cycle, check that Y is incremented by one, then reset    
    stimulate_x('b001, idx);
    check_result(individual, idx, 2, result); //Expect two     
    stimulate_x('b011, idx);
    check_result(individual, idx, 3, result); //Expect increment 
    stimulate_x('b000, idx);
    check_result(individual, idx, 0, result); //Expect zero (reset). Reset takes presedence over increment.   

 
    out = L1_norm;
  endtask: test     

  */
  
initial begin

  //Initialization phase
  assert (NUM_INPUTS  > 0 && NUM_INPUTS  < 6)                    else $fatal ("FAILURE! NUMBER OF INPUTS HAS NOT BEEN CONFIGURED WITHIN ALLOWED RANGE (1-5)");  
  assert (NUM_OUTPUTS > 0 && NUM_OUTPUTS < 6)                    else $fatal ("FAILURE! NUMBER OF OUTPUTS HAS NOT BEEN CONFIGURED WITHIN ALLOWED RANGE (1-5)");  
  assert (NUM_ROWS    > 0 && NUM_ROWS    < 17)                   else $fatal ("FAILURE! NUMBER OF ROWS HAS NOT BEEN CONFIGURED WITHIN ALLOWED RANGE (1-16)");
  assert (NUM_COLS    > 0 && NUM_COLS    < 17)                   else $fatal ("FAILURE! NUMBER OF COLUMNS HAS NOT BEEN CONFIGURED WITHIN ALLOWED RANGE (1-16)");
  assert (LEVELS_BACK > 0 && LEVELS_BACK <= NUM_COLS)            else $fatal ("FAILURE! LEVELS BACK HAS NOT BEEN CONFIGURED WITHIN ALLOWED RANGE (1-NUM_COLS)");
  assert (NUM_MUTAT   > 0 && NUM_MUTAT   <= NUM_ROWS * NUM_COLS) else $fatal ("FAILURE! NUMBER OF MUTATIONS HAS NOT BEEN CONFIGURED WITHIN ALLOWED RANGE (1-NUMBER OF NODES)");
  assert (COUNT_MAX   > 0 && COUNT_MAX   < 101)                   else $fatal ("FAILURE! MAX VALUE OF COUNTERS HAS NOT BEEN CONFIGURED WITHIN ALLOWED RANGE (1-16)");
  assert (CONST_MAX   > 0 && CONST_MAX   < 101)                   else $fatal ("FAILURE! MAX VALUE OF CONSTANTS HAS NOT BEEN CONFIGURED WITHIN ALLOWED RANGE (1-16)");
  assert (POPUL_SIZE  > 0)                                       else $fatal ("FAILURE! POPULATION SIZE MUST BE LARGER THAN 0");

  //Instantiate population of combinatorial circuits
  foreach(population[i])
    population[i] = new();

  best_solution = new();            //Create "dummy" best solution object
  
  dp = new();
 
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
      //test(population[i], i, population[i].fitness);

      //Replace current best solution with improved solution
      if(best_solution.fitness > population[i].fitness)begin 
        best_solution = population[i].copy();
        $display("An improved solution found in generation %2d, genotype %2d. Fitness is %2d", gen, i, best_solution.fitness);                      
      end  
       
      
      if(population[i].fitness == 0)begin
        population[i].calc_resource_util();
        population[i].calc_score();
        if(population[i].score < best_solution.score)begin// && population[i].score < 80)begin
          best_solution = population[i].copy();
          population[i].print_resource_util();
          //$display("Solution found in generation %2d, genotype %2d with score of %2d", gen, i, best_solution.score); 
          //$display("Resource utilization: %2d gates, %2d registers, %2d adders, %2d multipliers, %2d counters, %2d comparators and %2d muxes", best_solution.num_gates, best_solution.num_regs, best_solution.num_adders, best_solution.num_mults, best_solution.num_cnt, best_solution.num_cmp, best_solution.num_mux);           
          $display("Solution found in generation %2d, genotype %2d with number of slices: %2d", gen, i, best_solution.num_slices); 
          //$display("Resource utilization: %2d gates, %2d registers, %2d adders, %2d multipliers, %2d counters, %2d comparators and %2d muxes", best_solution.num_gates, best_solution.num_regs, best_solution.num_adders, best_solution.num_mults, best_solution.num_cnt, best_solution.num_cmp, best_solution.num_mux);           
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
        //test(offspring[k], i, offspring[k].fitness);

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