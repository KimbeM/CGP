class comb_circuit #(parameter X_WIDTH, Y_WIDTH, NUM_ROWS, NUM_COLS, LEVELS_BACK, NUM_MUTAT);
  typedef enum int {ZERO = 0, ONE = 1, DFF = 2, WIRE = 3, NOT = 4, AND = 5, OR = 6, XOR = 7} t_operation;
  
  parameter int     arity_lut[8] = {0, 0, 1, 1, 1, 2, 2, 2};     //Arity look-up table for "t_operation" typedef
  
  int         genotype[X_WIDTH:(X_WIDTH + NUM_ROWS * NUM_COLS)-1][];
  int         node_arity[X_WIDTH:(X_WIDTH + NUM_COLS*NUM_ROWS)-1];
  bit         eval_outputs[(X_WIDTH + NUM_ROWS * NUM_COLS)];  //Include inputs to this array, therefore indexing from 0
  bit         registers[int];
  int         conn_outputs[Y_WIDTH-1:0];
  int         num_gates;
  int         num_regs;
  int         fitness = 100;      //Initialize with arbitrarily high number for bad fitness ;

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
    copy.num_gates    = this.num_gates;
    copy.num_regs     = this.num_regs;    
    copy.fitness      = this.fitness;  
    return copy;  
  endfunction    
  
  function create_genotype();

    //Gene size is determined by maximum arity (+ 1 for storing node function) 
    foreach(genotype[i])begin
      genotype[i]   = new[int'(arity_lut.max(0)) + 1];
    end
    
    randomize_functions();
    
    randomize_connections();
    
  endfunction: create_genotype
  
  function randomize_functions(); 
    //Randomize operation for each node
    for(int i=X_WIDTH; i<NUM_ROWS * NUM_COLS + X_WIDTH; i++)begin
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
        if(node_arity[i + X_WIDTH + (NUM_ROWS * j)] > 0)begin
          for(int k=0; k<node_arity[i + (NUM_ROWS * j) + X_WIDTH]; k++)begin      
            if(k == 1)      
              conn_prev = conn;      
            do begin      
              if(j == 0)begin      
                conn               = $urandom_range(0, X_WIDTH-1);      
                genotype[i+X_WIDTH][k+1]   = conn;      
              end else if(j < LEVELS_BACK)begin      
                conn                              = $urandom_range(0, X_WIDTH+(j*NUM_ROWS)-1);      
                genotype[i + X_WIDTH + (NUM_ROWS * j)][k+1] = conn;      
              end else begin      
                conn                             = $urandom_range(X_WIDTH+((j-LEVELS_BACK)*NUM_ROWS), X_WIDTH+(j*NUM_ROWS)-1);      
                genotype[i + X_WIDTH + (NUM_ROWS * j)][k+1] = conn;      
              end      
            end while(conn == conn_prev && k == 1);      
          end
        end
      end
    end
    
    //Randomize connections for output nodes
    foreach(conn_outputs[i])
      conn_outputs[i] = $urandom_range((NUM_COLS-LEVELS_BACK)*NUM_ROWS + X_WIDTH, (NUM_COLS*NUM_ROWS) + X_WIDTH - 1);    
    
  endfunction: randomize_connections   

  function bit evaluate_node_output(int idx);
    bit input_A;
    bit input_B;
    bit out;
    
    if(node_arity[idx] == 2)begin
      input_A = eval_outputs[genotype[idx][1]]; 
      input_B = eval_outputs[genotype[idx][2]];
      if(genotype[idx][0] == AND)begin
        out   = input_A & input_B;
      end else if(genotype[idx][0] == OR)begin
        out   = input_A | input_B;
      end else if(genotype[idx][0] == XOR)begin
        out   = input_A ^ input_B;
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
      end else if(genotype[idx][0] == NOT) begin
        out   = ~input_A;
      end else if(genotype[idx][0] == ZERO)begin
        out   = 0;
      end else if(genotype[idx][0] == ONE)begin
        out   = 1;
      end
    end    
    
    return out;
  endfunction: evaluate_node_output

  function bit[Y_WIDTH-1:0] evaluate_outputs(bit[X_WIDTH-1:0] X);
    bit[Y_WIDTH-1:0] Y;
    int Y_evaluated = 0; //Counter to indicate how many bits of output Y have been evaluated
    int out_matches[$];  //Amount of matches indicate how many bits of the output Y are driven by currently evaluated node
    
    //First column of eval_outputs = comb circuit input  
    for(int i=0; i<X_WIDTH; i++)begin
      eval_outputs[i] = X[i];
    end
        
    //Evaluate outputs for comb circuit nodes
    for(int i=X_WIDTH; i<NUM_ROWS * NUM_COLS + X_WIDTH; i++)begin
      eval_outputs[i] = evaluate_node_output(i);
      out_matches     = conn_outputs.find_index with (item == i);
      if($size(out_matches) > 0)begin
        foreach(out_matches[j])
          Y[out_matches[j]] = eval_outputs[i];
        Y_evaluated = Y_evaluated + $size(out_matches); 
        if(Y_evaluated == Y_WIDTH)
          break;                    //Break loop when all bits of output Y have been evaluated
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
    int         conn_out_offset = X_WIDTH + NUM_ROWS * NUM_COLS; //Index of first output connection
  
    //Randomize which nodes get mutated
    for(int i=0; i<NUM_MUTAT; i++)begin
      mut_nodes[i] = $urandom_range(X_WIDTH, NUM_ROWS * NUM_COLS + X_WIDTH + Y_WIDTH-1);    //Include conn_outputs to possible mutated nodes
    end
  
    //Randomize functions for the chosen nodes
    foreach(mut_nodes[i])begin
      if(mut_nodes[i] < conn_out_offset)begin
        genotype[mut_nodes[i]][0] = $urandom_range(0, $size(arity_lut)-1);
        node_arity[mut_nodes[i]]  = arity_lut[genotype[mut_nodes[i]][0]]; 
      end
    end
    
    
    //for(int i=0; i<NUM_MUTAT; i++)begin
    //  genotype[i + X_WIDTH][0] = $urandom_range(0, $size(arity_lut)-1);
    //  node_arity[mut_nodes[i]]  = arity_lut[genotype[mut_nodes[i]][0]];
    //end    
    
    //Randomize connections for mutation nodes
    //If arity = 2, ensure that connections are from different nodes
    for(int i=0; i<NUM_ROWS; i++)begin
      for(int j=0; j<NUM_COLS; j++)begin
        if(mut_nodes[idx] == i + (j * NUM_ROWS) + X_WIDTH)begin
          idx = idx + 1;
          if(node_arity[i + X_WIDTH + (NUM_ROWS * j)] > 0)begin
            for(int k=0; k<node_arity[i + (j * NUM_ROWS) + X_WIDTH]; k++)begin
              if(k == 1)      
                conn_prev = conn;      
              do begin      
                if(j == 0)begin      
                  conn               = $urandom_range(0, X_WIDTH-1);      
                  genotype[i + X_WIDTH][k+1]   = conn;      
                end else if(j < LEVELS_BACK)begin      
                  conn                              = $urandom_range(0, X_WIDTH+(j*NUM_ROWS)-1);      
                  genotype[i + X_WIDTH + (NUM_ROWS * j)][k+1] = conn; 
                end else begin      
                  conn                             = $urandom_range(X_WIDTH+((j-LEVELS_BACK)*NUM_ROWS), X_WIDTH+(j*NUM_ROWS)-1);      
                  genotype[i + X_WIDTH + (NUM_ROWS * j)][k+1] = conn;    
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
        conn_outputs[mut_nodes[i] - conn_out_offset] = $urandom_range((NUM_COLS-LEVELS_BACK)*NUM_ROWS + X_WIDTH, (NUM_COLS*NUM_ROWS) + X_WIDTH - 1); 
    end        

    if(genotype[2][0] == 1 && conn_outputs[1] == 2 && genotype[3][0] == 0 && conn_outputs[0] == 3)
      $stop;

  endfunction: mutate  
  
function void calc_resource_util();  
  int              idx_q[$];              
  bit              tree[int][];         //For storing info about which nodes have been visited  
  t_operation      func          = t_operation'(genotype[conn_outputs][0]);       
  bit[Y_WIDTH-1:0] tree_complete = 0;  
   
  for(int i=0; i<Y_WIDTH; i++)begin
     
    idx_q.push_front(conn_outputs[i]);  
      
    //Traverse comb_circuit backwards from its output to its inputs.  
    //Only nodes that affect the output are added to the tree.  
    //When all nodes have been added to the tree, exit this while-loop.  
    while(~tree_complete[i])begin  
      if(idx_q[0] >= X_WIDTH)begin  
        
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
      end else if(idx_q[0] < X_WIDTH)begin  
        if(idx_q[1] == conn_outputs[i] && tree[idx_q[1]].and() == 1)  
            tree_complete[i] = 1;  
        else  
          idx_q.delete(0);  
      end   
    end  
    
  end
  
  //Check all nodes present in tree. All functions except "wire" increase the gate count  
  foreach(tree[i])begin  
    if(arity_lut[genotype[i][0]] == 0)
      $display("Node num %d: %s" , i, t_operation'(genotype[i][0]));    
    else if(arity_lut[genotype[i][0]] == 1)
      $display("Node num %d: %s %d" , i, t_operation'(genotype[i][0]), genotype[i][1]);
    else if(arity_lut[genotype[i][0]] == 2)
      $display("Node num %d: %s %d %d" , i, t_operation'(genotype[i][0]), genotype[i][1], genotype[i][2]);   
      
    if(t_operation'(genotype[i][0]) != WIRE && t_operation'(genotype[i][0]) != DFF && t_operation'(genotype[i][0]) != ZERO && t_operation'(genotype[i][0]) != ONE)        
      num_gates = num_gates + 1;  
    if(t_operation'(genotype[i][0]) == DFF)
      num_regs  = num_regs + 1;
  end  
  foreach(conn_outputs[i])
    $display("Output Y[%1d]: %d", i, conn_outputs[i]); 
    
endfunction: calc_resource_util  

 
endclass: comb_circuit