-----------------------------------------------------------------------------------------------------------------------------------
-- Library and Package section
-----------------------------------------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-----------------------------------------------------------------------------------------------------------------------------------
-- Entity section
-----------------------------------------------------------------------------------------------------------------------------------

entity gene is
  generic(
    RST_ACTIVE         : std_logic := '0';
    CNT_MAX            : integer   := 15;
    DATA_IN_WIDTH      : integer   := 32    
  );
  port(
    Clk_in             : in  std_logic;
    Rst_in             : in  std_logic;
    Func_in            : in  std_logic_vector(3 downto 0);               -- for 12 functions
    Const_in           : in  std_logic_vector(DATA_IN_WIDTH-1 downto 0); 
    Const_vld_in       : in  std_logic;
    A_in               : in  std_logic_vector(DATA_IN_WIDTH -1 downto 0);
    B_in               : in  std_logic_vector(DATA_IN_WIDTH -1 downto 0);
    C_in               : in  std_logic_vector(DATA_IN_WIDTH -1 downto 0);
    Data_out           : out std_logic_vector(DATA_IN_WIDTH -1 downto 0)
    );
    
  end gene;  
  
architecture struct of gene is

  signal const_map   : std_logic_vector(DATA_IN_WIDTH-1 downto 0);
  signal cnt_map     : std_logic_vector(DATA_IN_WIDTH-1 downto 0);
  signal dff_map     : std_logic_vector(DATA_IN_WIDTH-1 downto 0);
  signal not_map     : std_logic_vector(DATA_IN_WIDTH-1 downto 0);
  signal and_map     : std_logic_vector(DATA_IN_WIDTH-1 downto 0);
  signal or_map      : std_logic_vector(DATA_IN_WIDTH-1 downto 0);
  signal add_map     : std_logic_vector(DATA_IN_WIDTH-1 downto 0);
  signal subtr_map   : std_logic_vector(DATA_IN_WIDTH-1 downto 0);
  signal mult_map    : std_logic_vector(DATA_IN_WIDTH-1 downto 0);  
  signal comp_map    : std_logic_vector(DATA_IN_WIDTH-1 downto 0);
  signal comp_gt_map : std_logic_vector(DATA_IN_WIDTH-1 downto 0);
  signal ite_map     : std_logic_vector(DATA_IN_WIDTH-1 downto 0);    
  
begin

  
  Data_out <= const_map   when unsigned(Func_in) = 0  else
              cnt_map     when unsigned(Func_in) = 1  else
              dff_map     when unsigned(Func_in) = 2  else
              not_map     when unsigned(Func_in) = 3  else
              and_map     when unsigned(Func_in) = 4  else
              or_map      when unsigned(Func_in) = 5  else
              add_map     when unsigned(Func_in) = 6  else
              subtr_map   when unsigned(Func_in) = 7  else
              mult_map    when unsigned(Func_in) = 8  else
              comp_map    when unsigned(Func_in) = 9  else
              comp_gt_map when unsigned(Func_in) = 10 else
              ite_map     when unsigned(Func_in) = 11 else
              A_in; -- = Wire function
              
  inst_const : entity work.const_func
  generic map(
    RST_ACTIVE      => RST_ACTIVE,    
    DATA_IN_WIDTH   => DATA_IN_WIDTH
  )
  port map(
    Clk_in          => Clk_in,
    Rst_in          => Rst_in,
    Const_vld_in    => Const_vld_in,
    Const_in        => Const_in, 
    Data_out        => const_map
  );
  
  inst_cnt : entity work.cnt_func
  generic map(
    RST_ACTIVE      => RST_ACTIVE,    
    CNT_MAX         => CNT_MAX,
    DATA_IN_WIDTH   => DATA_IN_WIDTH
  )
  port map(
    Clk_in          => Clk_in,
    Rst_in          => Rst_in,
    Data_out        => cnt_map
  );  
  
  inst_dff : entity work.dff_func
  generic map(
    RST_ACTIVE      => RST_ACTIVE,    
    DATA_IN_WIDTH   => DATA_IN_WIDTH
  )
  port map(
    Clk_in          => Clk_in,
    Rst_in          => Rst_in,
    A_in            => A_in,
    Data_out        => dff_map
  );    

  inst_not : entity work.not_func
  generic map(
    DATA_IN_WIDTH   => DATA_IN_WIDTH
  )
  port map(
    A_in            => A_in,
    Data_out        => not_map
  );     

  inst_and : entity work.and_func
  generic map(
    DATA_IN_WIDTH   => DATA_IN_WIDTH
  )
  port map(
    A_in            => A_in,
    B_in            => B_in,
    Data_out        => and_map
  );  
  
  inst_or : entity work.or_func
  generic map(
    DATA_IN_WIDTH   => DATA_IN_WIDTH
  )
  port map(
    A_in            => A_in,
    B_in            => B_in,
    Data_out        => or_map
  );    
  
  inst_add : entity work.add_func
  generic map(
    DATA_IN_WIDTH   => DATA_IN_WIDTH
  )
  port map(
    A_in            => A_in,
    B_in            => B_in,
    Data_out        => add_map
  );  

  inst_subtr : entity work.subtr_func
  generic map(
    DATA_IN_WIDTH   => DATA_IN_WIDTH
  )
  port map(
    A_in            => A_in,
    B_in            => B_in,
    Data_out        => subtr_map
  );  

  inst_mult : entity work.mult_func
  generic map(
    DATA_IN_WIDTH   => DATA_IN_WIDTH
  )
  port map(
    A_in            => A_in,
    B_in            => B_in,
    Data_out        => mult_map
  );   


  inst_comp : entity work.comp_func
  generic map(
    DATA_IN_WIDTH   => DATA_IN_WIDTH
  )
  port map(
    A_in            => A_in,
    B_in            => B_in,
    Data_out        => comp_map
  );    
  
  inst_comp_gt : entity work.comp_gt_func
  generic map(
    DATA_IN_WIDTH   => DATA_IN_WIDTH
  )
  port map(
    A_in            => A_in,
    B_in            => B_in,
    Data_out        => comp_gt_map
  );  
  
  inst_ite : entity work.ite_func
  generic map(
    DATA_IN_WIDTH   => DATA_IN_WIDTH
  )
  port map(
    A_in            => A_in,
    B_in            => B_in,
    C_in            => C_in,
    Data_out        => ite_map
  );    


end struct;  
    