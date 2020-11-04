class cgp_circuit #(parameter NUM_INPUTS, NUM_OUTPUTS, NUM_ROWS, NUM_COLS, CONST_MAX, COUNT_MAX, LEVELS_BACK, NUM_MUTAT);
  typedef enum int {CONST_ZERO = 0, CONST = 1, COUNTER = 2, DFF = 3, NOT = 4, WIRE = 5, AND = 6, OR = 7, ADD = 8, SUB = 9, MULT = 10, COMP = 11, COMP_GT = 12, ITE = 13} t_operation;
  typedef int out_type[NUM_OUTPUTS];
  
  parameter int     arity_lut[14] = {0, 0, 0, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 3};     //Arity look-up table for "t_operation" typedef
  
  int         feedback_p  = 30; //Probability for feedback in percent
  int         genotype[NUM_INPUTS:(NUM_INPUTS + NUM_ROWS * NUM_COLS)-1][];
  int         node_arity[NUM_INPUTS:(NUM_INPUTS + NUM_COLS*NUM_ROWS)-1];
  int         eval_outputs[(NUM_INPUTS + NUM_ROWS * NUM_COLS)];  //Include inputs to this array, therefore indexing from 0
  int         registers[int];
  int         it_registers[int];
  int         constants[int];
  int         counters[int][2];  //[0] = Counter Value, [1] = Counter Max
  int         conn_outputs[NUM_OUTPUTS-1:0];
  int         num_slices = 0;
  int         sad        = 1000000;      //Initialize with arbitrarily high number for poor Sum of Absolute Differences (SAD)
  int         score      = 1000000;      //Initialize with arbitrarily high number for poor score

  //Tree structure to represent circuit. Used in resource utilization calculation.
  bit              tree[int][];

  function new();
  
    create_genotype();
        
  endfunction: new
  
  function cgp_circuit copy();  
    copy = new();  
    copy.node_arity   = this.node_arity;  
    copy.genotype     = this.genotype;  
    copy.eval_outputs = this.eval_outputs;  
    copy.conn_outputs = this.conn_outputs; 
    copy.registers    = this.registers;
    copy.it_registers = this.it_registers;
    copy.constants    = this.constants;
    copy.counters     = this.counters;
    copy.num_slices   = this.num_slices;
    copy.sad          = this.sad;  
    copy.score        = this.score;
    return copy;  
  endfunction    
  
  function create_genotype();

    //Gene size is maximum arity + 1 (for storing all input nodes + storing node function) 
    foreach(genotype[i])begin
      genotype[i]   = new[int'(arity_lut.max(0)) + 1];
    end
    
    randomize_functions();
    
    randomize_connections();
    
  endfunction: create_genotype
  
  function randomize_functions(); 

    //Column 1         : Constants and Counters
    //Column 2 to (n-1): Combinatorial
    //Column n         : DFFs
    
    //Randomize Constants and Counters of first column
    for(int i=NUM_INPUTS; i<NUM_ROWS + NUM_INPUTS; i++)begin
      genotype[i][0] = $urandom_range(0, 2); 
      node_arity[i]  = arity_lut[genotype[i][0]];
    end   
    
    //Randomize Combinatorial functions for middlemost columns
    for(int i=NUM_ROWS + NUM_INPUTS; i<NUM_ROWS * (NUM_COLS-1) + NUM_INPUTS; i++)begin
      genotype[i][0] = $urandom_range(4, 13);
      node_arity[i]  = arity_lut[genotype[i][0]];
    end     
    
    //Assign DFFs to last column
    for(int i=NUM_ROWS * (NUM_COLS-1) + NUM_INPUTS; i<NUM_ROWS * NUM_COLS + NUM_INPUTS; i++)begin
      genotype[i][0] = 3; //DFF
      node_arity[i]  = 1;
    end       
    
  endfunction: randomize_functions    

  function randomize_connections(); 
  
    int       conn;
    int       conn_prev[];
    bit       conn_ok;
    
    conn_prev = new[int'(arity_lut.max(0)) - 1];  //Size is arity - 1
  
    //Randomize connections for each node
    for(int i=0; i<NUM_ROWS; i++)begin
      for(int j=0; j<NUM_COLS; j++)begin  
        if(node_arity[i + NUM_INPUTS + (NUM_ROWS * j)] > 0)begin
          for(int k=0; k<node_arity[i + (NUM_ROWS * j) + NUM_INPUTS]; k++)begin      
            if(k > 0)      
              conn_prev[k-1] = conn;     
            do begin      
              //Connections for Constants & Counters
              //if(j == 0)begin      
              //  conn               = $urandom_range(0, NUM_INPUTS-1);      
              //  genotype[i+NUM_INPUTS][k+1]   = conn;      
              //Connections for DFFs
              if(j == NUM_COLS-1)begin
                conn               = $urandom_range(0, NUM_INPUTS+NUM_ROWS*(NUM_COLS-1)-1);      
                genotype[i + NUM_INPUTS + (NUM_ROWS * j)][k+1]   = conn; 
              //Connections for combinatorial nodes
              end else if(j > 0 && j < LEVELS_BACK)begin    
                //Connect to DFF in last column 
                if($urandom_range(0, 99) < feedback_p)
                  conn = $urandom_range(NUM_INPUTS + NUM_ROWS*(NUM_COLS-1), NUM_INPUTS + (NUM_ROWS*NUM_COLS) - 1);         
                //Connect to previous columns 
                else
                  conn = $urandom_range(0, NUM_INPUTS+(j*NUM_ROWS)-1);      
                genotype[i + NUM_INPUTS + (NUM_ROWS * j)][k+1] = conn;      
              end
              conn_ok = 1;  //Set to 0 if any of the previous connections for this node matches conn
              //for(int x=0; x<int'(arity_lut.max(0))-1; x++)begin
              //  if(conn == conn_prev[x])
              //    conn_ok = 0;
              //end
            end while(conn_ok == 0 && k > 0);
          end
        end
      end
    end
    
    //Randomize connections for output nodes
    foreach(conn_outputs[i])
      conn_outputs[i] = $urandom_range((NUM_COLS-LEVELS_BACK)*NUM_ROWS + NUM_INPUTS, (NUM_COLS*NUM_ROWS) + NUM_INPUTS - 1);    
    
    //Debugging
    foreach(genotype[i])
      assert(node_arity[i]  == arity_lut[genotype[i][0]]) else $fatal ("FAILURE IN cgp circuit randomize_connections()!");
    
  endfunction: randomize_connections   

  function int evaluate_node_output(int idx);
    int input_A;
    int input_B;
    int input_C;
    int out;
    
    if(node_arity[idx] == 3)begin
      input_A = eval_outputs[genotype[idx][1]];
      input_B = eval_outputs[genotype[idx][2]];
      input_C = eval_outputs[genotype[idx][3]];
      if(genotype[idx][0] == ITE)begin
        if(input_A)
          out = input_B;
        else
          out = input_C;
      end
    end else if(node_arity[idx] == 2)begin
      input_A = eval_outputs[genotype[idx][1]]; 
      input_B = eval_outputs[genotype[idx][2]];
      if(genotype[idx][0] == AND)begin
        out   = input_A && input_B;
      end else if(genotype[idx][0] == OR)begin
        out   = input_A || input_B;
      end else if(genotype[idx][0] == ADD)begin
        out   = input_A + input_B;
      end else if(genotype[idx][0] == SUB)begin
        out   = input_A - input_B;   
      end else if(genotype[idx][0] == MULT)begin
        out   = input_A * input_B;       
      end else if(genotype[idx][0] == COMP)begin
        if(input_A == input_B)
          out = 1;
        else
          out = 0;
      end else if(genotype[idx][0] == COMP_GT)begin
        if(input_A > input_B)
          out = 1;
        else
          out = 0;
      end
    end else if(node_arity[idx] == 1)begin
      input_A = eval_outputs[genotype[idx][1]]; 
      if(genotype[idx][0] == WIRE)begin
        out   = input_A;
      end else if(genotype[idx][0] == NOT)begin
        out   = !input_A;        
      end
    end else begin
      if(genotype[idx][0] == CONST_ZERO)begin
        out   = 0;
      end else if(genotype[idx][0] == CONST)begin
        if(constants.exists(idx))begin
          out            = constants[idx];
        end else begin
          constants[idx] = $urandom_range(1, CONST_MAX);
          out            = constants[idx];  
        end
      end else if(genotype[idx][0] == COUNTER)begin
        if(counters.exists(idx))begin
          out             = counters[idx][0];          
          if(counters[idx][0] >= counters[idx][1])
            counters[idx][0] = 0;
          else
            counters[idx][0]  = counters[idx][0] + 1;         
        end else begin
          out              = 0; 
          counters[idx][1] = $urandom_range(1, COUNT_MAX);  //Randomize range of counter
          counters[idx][0] = 1;
        end      
      end
    end    
    
    return out;
  endfunction: evaluate_node_output

  function out_type evaluate_outputs(int X[NUM_INPUTS]);
    out_type Y;
    int Y_evaluated = 0; //Counter to indicate how many bits of output Y have been evaluated
    int out_matches[$];  //Amount of matches indicate how many bits of the output Y are driven by currently evaluated node
    
    //First column of eval_outputs = cgp circuit input  
    for(int i=0; i<NUM_INPUTS; i++)begin
      eval_outputs[i] = X[i];
    end
    
    //Evaluate outputs of DFFs in last column
    for(int i=NUM_ROWS * (NUM_COLS-1) + NUM_INPUTS; i<NUM_ROWS * NUM_COLS + NUM_INPUTS; i++)begin
      if(registers.exists(i))begin
        eval_outputs[i] = registers[i];
      end else begin
        registers[i]    = 0;
        eval_outputs[i] = 0;
      end
    end      

      
    //Evaluate outputs for each node
    for(int i=NUM_INPUTS; i<NUM_ROWS * NUM_COLS + NUM_INPUTS; i++)begin
      if(i < NUM_ROWS * (NUM_COLS-1) + NUM_INPUTS)
        eval_outputs[i] = evaluate_node_output(i);
      else
        registers[i] = eval_outputs[genotype[i][1]];        
      out_matches     = conn_outputs.find_index with (item == i);
      if($size(out_matches) > 0)begin
        foreach(out_matches[j])
          Y[out_matches[j]] = eval_outputs[i];
        Y_evaluated = Y_evaluated + $size(out_matches); 
        //if(Y_evaluated == NUM_OUTPUTS)begin
        //  //Debugging 
        //  assert(int'(conn_outputs.max()) == i) else $fatal ("FAILURE IN cgp circuit evaluate_outputs()! Max output = %d, i=%d", int'(conn_outputs.max()), i);
        //end
      end
      out_matches.delete(); //Clear queue
    end
      
    return Y;
  endfunction: evaluate_outputs 
  
  function void reset();
  
    clear_registers();
    clear_counters();
  
  endfunction: reset
  
  function void clear_registers();
  
    foreach(registers[i])
      registers[i] = 0;
  
  endfunction: clear_registers
  
  function void clear_counters();
  
    foreach(counters[i])
      counters[i][0] = 0;
  
  endfunction: clear_counters  

  function void mutate();
    int         mut_nodes[NUM_MUTAT];
    int         conn;
    int         conn_prev[];
    bit         conn_ok;    
    int         idx = 0;
    int         conn_out_offset = NUM_INPUTS + NUM_ROWS * NUM_COLS; //Index of first output connection
  
    conn_prev = new[int'(arity_lut.max(0)) - 1];  //Size is arity - 1  
  
    //Randomize which nodes get mutated
    for(int i=0; i<NUM_MUTAT; i++)begin
      mut_nodes[i] = $urandom_range(NUM_INPUTS, NUM_ROWS * NUM_COLS + NUM_INPUTS + NUM_OUTPUTS-1);    //Include conn_outputs to possible mutated nodes
    end
  
    //Randomize functions for the chosen nodes
    foreach(mut_nodes[i])begin
      if(mut_nodes[i] < conn_out_offset)begin
        if(t_operation'(genotype[mut_nodes[i]][0]) == DFF)
          registers.delete(mut_nodes[i]); //Function of this node no longer register
        if(t_operation'(genotype[mut_nodes[i]][0]) == CONST)
          constants.delete(mut_nodes[i]); //Function of this node no longer constant
        if(t_operation'(genotype[mut_nodes[i]][0]) == COUNTER)
          counters.delete(mut_nodes[i]);
        //Mutation if node is in first column
        if(mut_nodes[i] < NUM_INPUTS+NUM_ROWS)
          genotype[mut_nodes[i]][0] = $urandom_range(0, 2);
        //Mutation if node is in middlemost columns (combinatorial nodes)
        else if(mut_nodes[i] >= NUM_INPUTS+NUM_ROWS && mut_nodes[i] <=conn_out_offset-(NUM_ROWS+1))
          genotype[mut_nodes[i]][0] = $urandom_range(4, 13);
        node_arity[mut_nodes[i]]  = arity_lut[genotype[mut_nodes[i]][0]]; 
        //If new function is constant or zero constant, set connections to default '0'
        if(t_operation'(genotype[i][0]) == CONST_ZERO || t_operation'(genotype[i][0]) == CONST)begin
          for(int j=1; j<int'(arity_lut.max(0))+1; j++)begin
            genotype[mut_nodes[i]][j] = 0;
          end
        end  
      end
    end
    
    //Randomize connections for mutation nodes
    //If arity > 1, ensure that connections are from different nodes
    for(int i=0; i<NUM_ROWS; i++)begin
      for(int j=0; j<NUM_COLS; j++)begin
        if(mut_nodes[idx] == i + (j * NUM_ROWS) + NUM_INPUTS)begin
          idx = idx + 1;
          if(node_arity[i + NUM_INPUTS + (NUM_ROWS * j)] > 0)begin
            for(int k=0; k<node_arity[i + (j * NUM_ROWS) + NUM_INPUTS]; k++)begin
              if(k > 0)      
                conn_prev[k-1] = conn;      
              do begin      
                //if(j == 0)begin      
                //  conn               = $urandom_range(0, NUM_INPUTS-1);      
                //  genotype[i + NUM_INPUTS][k+1]   = conn;  
                //Connections for DFFs
                if(j == NUM_COLS-1)begin
                  conn               = $urandom_range(0, NUM_INPUTS+NUM_ROWS*(NUM_COLS-1)-1);      
                  genotype[i + NUM_INPUTS + (NUM_ROWS * j)][k+1]   = conn;                   
                //Connections for combinatorial nodes
                end else if(j > 0 && j < LEVELS_BACK)begin      
                  //Connect to DFF in last column 
                  if($urandom_range(0, 99) < feedback_p)
                    conn = $urandom_range(NUM_INPUTS + NUM_ROWS*(NUM_COLS-1), NUM_INPUTS + (NUM_ROWS*NUM_COLS) - 1);         
                  //Connect to previous columns 
                  else
                    conn = $urandom_range(0, NUM_INPUTS+(j*NUM_ROWS)-1);      
                  genotype[i + NUM_INPUTS + (NUM_ROWS * j)][k+1] = conn;   
                end      
                conn_ok = 1;  //Set to 0 if any of the previous connections for this node matches conn
                //for(int x=0; x<int'(arity_lut.max(0))-1; x++)begin
                //  if(conn == conn_prev[x])
                //    conn_ok = 0;
                //end
              end while(conn_ok == 0 && k > 0);
            end
          end
        end
          if(idx == NUM_MUTAT)
            break;
      end
        if(idx == NUM_MUTAT)
          break; 
    end 
    
    //Randomize output connections if one or more are found in mut_nodes
    foreach(mut_nodes[i])begin
      if(mut_nodes[i] >= conn_out_offset)
        conn_outputs[mut_nodes[i] - conn_out_offset] = $urandom_range((NUM_COLS-LEVELS_BACK)*NUM_ROWS + NUM_INPUTS, (NUM_COLS*NUM_ROWS) + NUM_INPUTS - 1); 
    end    

    //Debugging
    foreach(genotype[i])
      assert(node_arity[i]  == arity_lut[genotype[i][0]]) else $fatal ("FAILURE IN cgp circuit mutate()! Node arity does not match arity lut");    
    
    //Debugging
    //foreach(genotype[i])begin
    //  if(node_arity[i]  == 2)
    //    assert(genotype[i][1] != genotype[i][2]) else $fatal ("FAILURE IN cgp circuit mutate()! Both inputs from same node");
    //end
    //
    ////Debugging
    //foreach(genotype[i])begin
    //  if(node_arity[i]  == 3)
    //    assert(genotype[i][1] != genotype[i][2] && genotype[i][1] != genotype[i][3] && genotype[i][2] != genotype[i][3] ) else $fatal ("FAILURE IN cgp circuit mutate()! Two inputs from same node");
    //end

  endfunction: mutate  
  
  function void calc_resource_util();  
    int              idx_q[$];              
    t_operation      func          = t_operation'(genotype[conn_outputs][0]);       
    bit[NUM_OUTPUTS-1:0] tree_complete = 0;  
     
    //Clear all entries from tree 
    foreach(tree[i])
      tree.delete(i);    
     
    for(int i=0; i<NUM_OUTPUTS; i++)begin
       
      idx_q.push_front(conn_outputs[i]);  
        
      //Traverse cgp_circuit backwards from its output to its inputs.  
      //Only nodes that affect the output are added to the tree.  
      //When all nodes have been added to the tree, exit this while-loop.  
      while(~tree_complete[i])begin  
        if(idx_q[0] >= NUM_INPUTS)begin  
          
          //Function of the node currently pointed to  
          func = t_operation'(genotype[idx_q[0]][0]);
              
      
          //Allocate memory for the dynamic dimension of the tree according to the arity of the gate currently pointed to.  
          //OBS: only if memory has not been allocated already for this node.  
          if(tree[idx_q[0]].size() == 0)begin    
            if(arity_lut[int'(func)] == 0)begin
              tree[idx_q[0]]    = new[1];  
              tree[idx_q[0]][0] = 1;      
            end else if(arity_lut[int'(func)] == 1)begin  
              tree[idx_q[0]]    = new[1];  
              tree[idx_q[0]][0] = 0;  
            end else if(arity_lut[int'(func)] == 2)begin    
              tree[idx_q[0]] = new[arity_lut[int'(func)]];  
              foreach(tree[idx_q[0]][i])  
                tree[idx_q[0]][i] = 0;  
            end else if(arity_lut[int'(func)] == 3)begin    
              tree[idx_q[0]] = new[arity_lut[int'(func)]];  
              foreach(tree[idx_q[0]][i])  
                tree[idx_q[0]][i] = 0;                  
            end  
          end  
               
          //If unvisited nodes exist in the backward direction in the circuit, traverse backwards.  
          //If all nodes in the backward direction from the current node have been visited,  
          //traverse forwards in the circuit (towards output).  
          if(tree[idx_q[0]][0] == 0)begin  
            tree[idx_q[0]][0] = 1;  
            idx_q.push_front(genotype[idx_q[0]][1]);  
          end else if(tree[idx_q[0]].size() > 1 && tree[idx_q[0]][1] == 0)begin  
            tree[idx_q[0]][1] = 1;  
            idx_q.push_front(genotype[idx_q[0]][2]);  
          end else if(tree[idx_q[0]].size() > 2 && tree[idx_q[0]][2] == 0)begin  
            tree[idx_q[0]][2] = 1;  
            idx_q.push_front(genotype[idx_q[0]][3]);              
          end else begin  
            if(idx_q[1] == conn_outputs[i] && tree[idx_q[1]].and() == 1)  
              tree_complete[i] = 1;  
            else if(idx_q[0] == conn_outputs[i] && tree[idx_q[0]].and() == 1)
              tree_complete[i] = 1;              
            else  
              idx_q.delete(0);  
          end  
        end else if(idx_q[0] < NUM_INPUTS)begin  
          if(idx_q[1] == conn_outputs[i] && tree[idx_q[1]].and() == 1)  
            tree_complete[i] = 1;  
          else  
            idx_q.delete(0);  
        end   
      end  
      
    end
  
    foreach(tree[i])begin 
      if(t_operation'(genotype[i][0]) == ADD || t_operation'(genotype[i][0] == SUB))    
        num_slices = num_slices + 8;    
      if(t_operation'(genotype[i][0]) == MULT)    
        num_slices = num_slices + 402;           
      if(t_operation'(genotype[i][0]) == AND)
        num_slices = num_slices + 15;
      if(t_operation'(genotype[i][0]) == OR)          
        num_slices = num_slices + 12;
      if(t_operation'(genotype[i][0]) == DFF)    
        num_slices = num_slices + 12;    
      if(t_operation'(genotype[i][0]) == COUNTER)    
        num_slices = num_slices + 13;      
      if(t_operation'(genotype[i][0]) == COMP)
        num_slices = num_slices + 3;    
      if(t_operation'(genotype[i][0]) == COMP_GT)    
        num_slices = num_slices + 4;    
      if(t_operation'(genotype[i][0]) == ITE)    
        num_slices = num_slices + 25;    
    end
      
  endfunction: calc_resource_util  
  
  function void print_resource_util();
  
    foreach(tree[i])begin    
      if(arity_lut[genotype[i][0]] == 0)  begin
        if(t_operation'(genotype[i][0]) == CONST)  
          $display("Node num %d: %s=%d" , i, t_operation'(genotype[i][0]), constants[i]);  
        else if(t_operation'(genotype[i][0]) == COUNTER)
          $display("Node num %d: %s=%d" , i, t_operation'(genotype[i][0]), counters[i][1]);           
        else if(t_operation'(genotype[i][0]) == CONST_ZERO)
          $display("Node num %d: %s" , i, t_operation'(genotype[i][0]));           
      end else if(arity_lut[genotype[i][0]] == 1)  
        $display("Node num %d: %s %d" , i, t_operation'(genotype[i][0]), genotype[i][1]);  
      else if(arity_lut[genotype[i][0]] == 2)  
        $display("Node num %d: %s %d %d" , i, t_operation'(genotype[i][0]), genotype[i][1], genotype[i][2]);  
      else if(arity_lut[genotype[i][0]] == 3)
        $display("Node num %d: %s %d %d %d", i, t_operation'(genotype[i][0]), genotype[i][1], genotype[i][2], genotype[i][3]);  
    end    
    foreach(conn_outputs[i])  
      $display("Output Y[%1d]: %d", i, conn_outputs[i]);   
  
  endfunction: print_resource_util

  
  function void calc_score();
    
    score = num_slices;
  
  endfunction: calc_score

 
endclass: cgp_circuit