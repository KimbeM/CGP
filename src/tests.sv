class tests#(parameter NUM_INPUTS, NUM_OUTPUTS);

  typedef int out_type[NUM_INPUTS];

  int rand_delay;
  int reg_addr = 5;

  int X[NUM_INPUTS]; 
  int Y[NUM_OUTPUTS];
  int Y_EXP[NUM_OUTPUTS]; //Expected output
  
  int L1_norm; //Sum of absolute differences

  task write_reg(input int address, output int writedata);

    X[0] = 1;  //Write enable
    X[1] = $urandom_range(1, 10);
    X[2] = address;
    
    writedata = X[1];
   
  endtask: write_reg
  
  task read_reg(input int address);

    X[0] = 0;  //Read enable
    X[1] = $urandom_range(0, 100); //Randomize data field 
    X[2] = address;
    
  endtask: read_reg  

  //Register interface
  task register_test(input cgp_circuit individual, output int out);
    
    int addr      = 0;
    int data      = 0;
    int exp_data  = 0;
    
    L1_norm = 0;    
   
    //Write then read. Check that expected data matches actual data.
    while(addr < 10)begin
      
      write_reg(addr, data);  
      
      if(addr == reg_addr)
        exp_data = data;
      
      Y = individual.evaluate_outputs(X);
      Y_EXP[0] = 0; //Write is set, expect zero data
      L1_norm = L1_norm + abs(Y[0] - Y_EXP[0]);        
      #1;      
            
      read_reg(addr);
      
      Y = individual.evaluate_outputs(X);
      if(addr == reg_addr)
        Y_EXP[0] = exp_data; //Read is set, expect previously written data
      else
        Y_EXP[0] = 0;        //Expect zero data from wrong address
      L1_norm = L1_norm + abs(Y[0] - Y_EXP[0]);        
      #1;
            
      addr++;
    end 
    
    addr    = 0;
    
    //Write for random num cycles, then read. Check that expected data matches actual data.
    while(addr < 10)begin
      
      write_reg(addr, data);  
      
      if(addr == reg_addr)
        exp_data = data; 
      
      rand_delay = $urandom_range(1,3);
      
      for(int i=0; i<rand_delay; i++)begin
        Y = individual.evaluate_outputs(X);
        Y_EXP[0] = 0; //Write is set, expect zero data
        L1_norm = L1_norm + abs(Y[0] - Y_EXP[0]);        
        #1;      
      
      end
      
      read_reg(addr);
      
      Y = individual.evaluate_outputs(X);
      if(addr == reg_addr)
        Y_EXP[0] = exp_data; //Read is set, expect previously written data
      else
        Y_EXP[0] = 0;        //Expect zero data from wrong address
      L1_norm = L1_norm + abs(Y[0] - Y_EXP[0]);        
      #1;
            
      addr++;
    end  

    addr    = 0;    
    
    //Write then read for random num cycles. Check that expected data matches actual data.
    while(addr < 10)begin
      
      write_reg(addr, data);  
      
      if(addr == reg_addr)
        exp_data = data;  
      
      Y = individual.evaluate_outputs(X);
      Y_EXP[0] = 0; //Write is set, expect zero data
      L1_norm = L1_norm + abs(Y[0] - Y_EXP[0]);        
      #1;      
            
      read_reg(addr);
      
      rand_delay = $urandom_range(1,3);
      
      for(int i=0; i<rand_delay; i++)begin
        Y = individual.evaluate_outputs(X);
        if(addr == reg_addr)
          Y_EXP[0] = exp_data; //Read is set, expect previously written data
        else
          Y_EXP[0] = 0;        //Expect zero data from wrong address
        L1_norm = L1_norm + abs(Y[0] - Y_EXP[0]);        
        #1;      
      end
      
      addr++;
    end  

    addr    = 0;     

    //Randomize data without setting WE then read. Check that nothing is written and that read data is zero.
    while(addr < 10)begin
      
      X[1] = $urandom_range(0, 10);
      
      Y = individual.evaluate_outputs(X);
      if(addr == reg_addr)
        Y_EXP[0] = exp_data; //Read is set, expect previously written data
      else
        Y_EXP[0] = 0;        //Expect zero data from wrong address
      L1_norm = L1_norm + abs(Y[0] - Y_EXP[0]);        
      #1;      
            
      read_reg(addr);
      
      Y = individual.evaluate_outputs(X);
      if(addr == reg_addr)
        Y_EXP[0] = exp_data; //Read is set, expect previously written data
      else
        Y_EXP[0] = 0;        //Expect zero data from wrong address
      L1_norm = L1_norm + abs(Y[0] - Y_EXP[0]);        
      #1;
            
      addr++;
    end    
    
    
    out = L1_norm;
  endtask: register_test 

  //PWM with enable input
  task pwm_test(input cgp_circuit individual, input int pwm_period, input int duty_cycle, input int num_periods, output int out);
    
    L1_norm = 0;    
    
    X[0] = 0;
    X[1] = duty_cycle;
    
    
    for(int t=0; t<pwm_period; t++)begin
      for(int t=0; t<pwm_period; t++)begin      
        Y = individual.evaluate_outputs(X);
        X[0] = Y[0];
        if(t < X[1])
          Y_EXP[0] = 1;
        else
          Y_EXP[0] = 0;
        L1_norm = L1_norm + abs(Y[0] - Y_EXP[0]);
        #1;
      end
    end 
    
    X[1] = duty_cycle + 2;    

    for(int t=0; t<pwm_period; t++)begin
      for(int t=0; t<pwm_period; t++)begin      
        Y = individual.evaluate_outputs(X);
        X[0] = Y[0];
        if(t < X[1])
          Y_EXP[0] = 1;
        else
          Y_EXP[0] = 0;
        L1_norm = L1_norm + abs(Y[0] - Y_EXP[0]);
        #1;
      end
    end   
    
    out = L1_norm;
  endtask: pwm_test 

  //Triangle wave
  task tri_wave_test(input cgp_circuit individual, input int peak_val, input int num_periods, output int out);
    //const int peak_val  = 8;
    //const int num_periods = 2;
        
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
    end
    
    out = L1_norm;
  endtask: tri_wave_test  

endclass: tests