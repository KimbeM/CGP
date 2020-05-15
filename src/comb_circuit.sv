class comb_circuit #(parameter NUM_INPUTS, NUM_OUTPUTS, NUM_ROWS, NUM_COLS, CONST_MAX, LEVELS_BACK, NUM_MUTAT);
  typedef enum int {CONST_ZERO = 0, CONST = 1, DFF = 2, WIRE = 3, AND = 4, OR = 5, ADD = 6, SUB = 7, MULT = 8} t_operation;
  typedef int out_type[NUM_OUTPUTS];
  
  parameter int     arity_lut[9] = {0, 0, 1, 1, 2, 2, 2, 2, 2};     //Arity look-up table for "t_operation" typedef
  
  int         genotype[NUM_INPUTS:(NUM_INPUTS + NUM_ROWS * NUM_COLS)-1][];
  int         node_arity[NUM_INPUTS:(NUM_INPUTS + NUM_COLS*NUM_ROWS)-1];
  int         eval_outputs[(NUM_INPUTS + NUM_ROWS * NUM_COLS)];  //Include inputs to this array, therefore indexing from 0
  int         registers[int];
  int         constants[int];
  int         conn_outputs[NUM_OUTPUTS-1:0];
  int         num_adders = 0;
  int         num_mults  = 0;
  int         num_gates  = 0;
  int         num_regs   = 0;
  int         fitness    = 100;      //Initialize with arbitrarily high number for poor fitness
  int         score      = 1000;     //Initialize with arbitrarily high number for poor score

  //Tree structure to represent circuit. Used in resource utilization calculation.
  bit              tree[int][];

  function new();
  
    create_genotype();
        
  endfunction: new
  
  function comb_circuit copy();  
    copy = new();  
    copy.node_arity   = this.node_arity;  
    copy.genotype     = this.genotype;  
    copy.eval_outputs = this.eval_outputs;  
    copy.conn_outputs = this.conn_outputs; 
    copy.registers    = this.registers;
    copy.constants    = this.constants;
    copy.num_adders   = this.num_adders;
    copy.num_mults    = this.num_mults;
    copy.num_gates    = this.num_gates;
    copy.num_regs     = this.num_regs;    
    copy.fitness      = this.fitness;  
    copy.score        = this.score;
    return copy;  
  endfunction    
  
  function create_genotype();

    //Gene size is maximum arity + 1 (for storing node function) 
    foreach(genotype[i])begin
      genotype[i]   = new[int'(arity_lut.max(0)) + 1];
    end
    
    randomize_functions();
    
    randomize_connections();
    
  endfunction: create_genotype
  
  function randomize_functions(); 
    //Randomize operation for each node
    for(int i=NUM_INPUTS; i<NUM_ROWS * NUM_COLS + NUM_INPUTS; i++)begin
      genotype[i][0] = $urandom_range(0, $size(arity_lut)-1);
      node_arity[i]  = arity_lut[genotype[i][0]];
    end   
  endfunction: randomize_functions    

  function randomize_connections(); 
  
    int       conn;
    int       conn_prev;
  
    //Randomize connections for each node
    for(int i=0; i<NUM_ROWS; i++)begin
      for(int j=0; j<NUM_COLS; j++)begin  
        if(node_arity[i + NUM_INPUTS + (NUM_ROWS * j)] > 0)begin
          for(int k=0; k<node_arity[i + (NUM_ROWS * j) + NUM_INPUTS]; k++)begin      
            if(k == 1)      
              conn_prev = conn;      
            do begin      
              if(j == 0)begin      
                conn               = $urandom_range(0, NUM_INPUTS-1);      
                genotype[i+NUM_INPUTS][k+1]   = conn;      
              end else if(j < LEVELS_BACK)begin      
                conn                              = $urandom_range(0, NUM_INPUTS+(j*NUM_ROWS)-1);      
                genotype[i + NUM_INPUTS + (NUM_ROWS * j)][k+1] = conn;      
              end else begin      
                conn                             = $urandom_range(NUM_INPUTS+((j-LEVELS_BACK)*NUM_ROWS), NUM_INPUTS+(j*NUM_ROWS)-1);      
                genotype[i + NUM_INPUTS + (NUM_ROWS * j)][k+1] = conn;      
              end      
            end while(conn == conn_prev && k == 1);      
          end
        end
      end
    end
    
    //Randomize connections for output nodes
    foreach(conn_outputs[i])
      conn_outputs[i] = $urandom_range((NUM_COLS-LEVELS_BACK)*NUM_ROWS + NUM_INPUTS, (NUM_COLS*NUM_ROWS) + NUM_INPUTS - 1);    
    
    //Debugging
    foreach(genotype[i])
      assert(node_arity[i]  == arity_lut[genotype[i][0]]) else $fatal ("FAILURE IN COMB CIRCUIT randomize_connections()!");
    
  endfunction: randomize_connections   

  function int evaluate_node_output(int idx);
    int input_A;
    int input_B;
    int out;
    
    if(node_arity[idx] == 2)begin
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
      end
    end else begin
      input_A = eval_outputs[genotype[idx][1]]; 
      if(genotype[idx][0] == WIRE)begin
        out   = input_A;
      end else if(genotype[idx][0] == DFF)begin
        if(registers.exists(idx))begin
          out            = registers[idx];
          registers[idx] = input_A;
        end else begin
          registers[idx] = input_A;
          out            = 0;  //Assume that all registers are initialized with value 0
        end
      end else if(genotype[idx][0] == CONST_ZERO)begin
        out   = 0;
      end else if(genotype[idx][0] == CONST)begin
        if(constants.exists(idx))begin
          out            = constants[idx];
        end else begin
          constants[idx] = $urandom_range(1, CONST_MAX);;
          out            = constants[idx];  
        end
      end
    end    
    
    return out;
  endfunction: evaluate_node_output

  function out_type evaluate_outputs(int X[NUM_INPUTS]);
    out_type Y;
    int Y_evaluated = 0; //Counter to indicate how many bits of output Y have been evaluated
    int out_matches[$];  //Amount of matches indicate how many bits of the output Y are driven by currently evaluated node
    
    //First column of eval_outputs = comb circuit input  
    for(int i=0; i<NUM_INPUTS; i++)begin
      eval_outputs[i] = X[i];
    end
        
    //Evaluate outputs for comb circuit nodes
    for(int i=NUM_INPUTS; i<NUM_ROWS * NUM_COLS + NUM_INPUTS; i++)begin
      eval_outputs[i] = evaluate_node_output(i);
      out_matches     = conn_outputs.find_index with (item == i);
      if($size(out_matches) > 0)begin
        foreach(out_matches[j])
          Y[out_matches[j]] = eval_outputs[i];
        Y_evaluated = Y_evaluated + $size(out_matches); 
        if(Y_evaluated == NUM_OUTPUTS)begin
          //Debugging 
          assert(int'(conn_outputs.max()) == i) else $fatal ("FAILURE IN COMB CIRCUIT evaluate_outputs()! Max output = %d, i=%d", int'(conn_outputs.max()), i);
          break;                    //Break loop when all outputs Y have been evaluated
        end
      end
      out_matches.delete(); //Clear queue
    end
  
    return Y;
  endfunction: evaluate_outputs 
  
  function void clear_registers();
  
    foreach(registers[i])
      registers[i] = 0;
  
  endfunction: clear_registers

  function void mutate();
    int         mut_nodes[NUM_MUTAT];
    int         conn;
    int         conn_prev;
    int         idx = 0;
    int         conn_out_offset = NUM_INPUTS + NUM_ROWS * NUM_COLS; //Index of first output connection
  
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
        genotype[mut_nodes[i]][0] = $urandom_range(0, $size(arity_lut)-1);
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
    //If arity = 2, ensure that connections are from different nodes
    for(int i=0; i<NUM_ROWS; i++)begin
      for(int j=0; j<NUM_COLS; j++)begin
        if(mut_nodes[idx] == i + (j * NUM_ROWS) + NUM_INPUTS)begin
          idx = idx + 1;
          if(node_arity[i + NUM_INPUTS + (NUM_ROWS * j)] > 0)begin
            for(int k=0; k<node_arity[i + (j * NUM_ROWS) + NUM_INPUTS]; k++)begin
              if(k == 1)      
                conn_prev = conn;      
              do begin      
                if(j == 0)begin      
                  conn               = $urandom_range(0, NUM_INPUTS-1);      
                  genotype[i + NUM_INPUTS][k+1]   = conn;      
                end else if(j < LEVELS_BACK)begin      
                  conn                              = $urandom_range(0, NUM_INPUTS+(j*NUM_ROWS)-1);      
                  genotype[i + NUM_INPUTS + (NUM_ROWS * j)][k+1] = conn; 
                end else begin      
                  conn                             = $urandom_range(NUM_INPUTS+((j-LEVELS_BACK)*NUM_ROWS), NUM_INPUTS+(j*NUM_ROWS)-1);      
                  genotype[i + NUM_INPUTS + (NUM_ROWS * j)][k+1] = conn;    
                end      
              end while(conn == conn_prev && k == 1); 
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
      assert(node_arity[i]  == arity_lut[genotype[i][0]]) else $fatal ("FAILURE IN COMB CIRCUIT mutate()! Node arity does not match arity lut");    
    
    //Debugging
    foreach(genotype[i])begin
      if(node_arity[i]  == 2)
        assert(genotype[i][1] != genotype[i][2]) else $fatal ("FAILURE IN COMB CIRCUIT mutate()! Both inputs from same node");
    end

  endfunction: mutate  
  
  function void calc_resource_util();  
    int              idx_q[$];              
    //bit              tree[int][];         //For storing info about which nodes have been visited  
    t_operation      func          = t_operation'(genotype[conn_outputs][0]);       
    bit[NUM_OUTPUTS-1:0] tree_complete = 0;  
     
    //Clear all entries from tree 
    foreach(tree[i])
      tree.delete(i);    
     
    for(int i=0; i<NUM_OUTPUTS; i++)begin
       
      idx_q.push_front(conn_outputs[i]);  
        
      //Traverse comb_circuit backwards from its output to its inputs.  
      //Only nodes that affect the output are added to the tree.  
      //When all nodes have been added to the tree, exit this while-loop.  
      while(~tree_complete[i])begin  
        if(idx_q[0] >= NUM_INPUTS)begin  
          
          //Function of the node currently pointed to  
          func = t_operation'(genotype[idx_q[0]][0]);
              
      
          //Allocate memory for the dynamic dimension of the tree according to the arity of the gate currently pointed to.  
          //OBS: only if memory has not been allocated already for this node.  
          if(tree[idx_q[0]].size() == 0)begin    
            if(arity_lut[int'(func)] == 1)begin  
              tree[idx_q[0]]    = new[1];  
              tree[idx_q[0]][0] = 0;  
            end else begin  
              tree[idx_q[0]] = new[2];  
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
          end else if(tree[idx_q[0]].size() == 2 && tree[idx_q[0]][1] == 0)begin  
            tree[idx_q[0]][1] = 1;  
            idx_q.push_front(genotype[idx_q[0]][2]);  
          end else begin  
            if(idx_q[1] == conn_outputs[i] && tree[idx_q[1]].and() == 1)  
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
    
    //Check all nodes present in tree. All functions except "wire" increase the gate count  
    //foreach(tree[i])begin  
    //  if(arity_lut[genotype[i][0]] == 0)
    //    if(t_operation'(genotype[i][0]) == CONST)
    //      $display("Node num %d: %s=%d" , i, t_operation'(genotype[i][0]), constants[i]);
    //    else
    //      $display("Node num %d: %s" , i, t_operation'(genotype[i][0]));    
    //  else if(arity_lut[genotype[i][0]] == 1)
    //    $display("Node num %d: %s %d" , i, t_operation'(genotype[i][0]), genotype[i][1]);
    //  else if(arity_lut[genotype[i][0]] == 2)
    //    $display("Node num %d: %s %d %d" , i, t_operation'(genotype[i][0]), genotype[i][1], genotype[i][2]);   
    //  
    foreach(tree[i])begin 
      if(t_operation'(genotype[i][0]) == ADD || t_operation'(genotype[i][0] == SUB))
        num_adders = num_adders + 1;
      if(t_operation'(genotype[i][0]) == MULT)
        num_mults  = num_mults + 1;       
      if(t_operation'(genotype[i][0]) == AND || t_operation'(genotype[i][0]) == OR)        
        num_gates = num_gates + 1;  
      if(t_operation'(genotype[i][0]) == DFF)
        num_regs  = num_regs + 1;
    end
    //end  
    //foreach(conn_outputs[i])
    //  $display("Output Y[%1d]: %d", i, conn_outputs[i]); 
      
  endfunction: calc_resource_util  
  
  function void print_resource_util();
  
    foreach(tree[i])begin    
      if(arity_lut[genotype[i][0]] == 0)  
        if(t_operation'(genotype[i][0]) == CONST)  
          $display("Node num %d: %s=%d" , i, t_operation'(genotype[i][0]), constants[i]);  
        else  
          $display("Node num %d: %s" , i, t_operation'(genotype[i][0]));      
      else if(arity_lut[genotype[i][0]] == 1)  
        $display("Node num %d: %s %d" , i, t_operation'(genotype[i][0]), genotype[i][1]);  
      else if(arity_lut[genotype[i][0]] == 2)  
        $display("Node num %d: %s %d %d" , i, t_operation'(genotype[i][0]), genotype[i][1], genotype[i][2]);  
    end    
    foreach(conn_outputs[i])  
      $display("Output Y[%1d]: %d", i, conn_outputs[i]);   
  
  endfunction: print_resource_util

  
  function void calc_score();
    
    score = num_gates + num_regs + 5*num_adders + 15*num_mults;
  
  endfunction: calc_score

 
endclass: comb_circuit