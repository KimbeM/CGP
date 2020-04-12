class fitness_func #(parameter X_WIDTH, Y_WIDTH);


  function bit[Y_WIDTH-1:0] evaluate_fitness(bit[X_WIDTH-1:0] X);

    bit[Y_WIDTH-1:0] Y;

    Y = X + 1; //Fitness function

    return Y;
  endfunction: evaluate_fitness
  
endclass: fitness_func