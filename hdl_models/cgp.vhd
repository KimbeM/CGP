-----------------------------------------------------------------------------------------------------------------------------------
-- Library and Package section
-----------------------------------------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-----------------------------------------------------------------------------------------------------------------------------------
-- Entity section
-----------------------------------------------------------------------------------------------------------------------------------

entity cgp is
  generic(
    RST_ACTIVE         : std_logic := '0';
    CNT_MAX            : integer   := 15;
    DATA_IN_WIDTH      : integer   := 32;
    NUM_INPUTS         : integer   := 3;
    NUM_OUTPUTS        : integer   := 1;
    NUM_ROWS           : integer   := 5;
    NUM_COLS           : integer   := 5
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
    
  end cgp;  
  
architecture struct of cgp is

  
  
begin


  NODES_GEN : for idx NUM_INPUTS to NUM_INPUTS+(NUM_ROWS+NUM_COLS)-1 generate 
    entity gene is
      generic map(
        RST_ACTIVE     => RST_ACTIVE,
        CNT_MAX        => CNT_MAX,
        DATA_IN_WIDTH  => DATA_IN_WIDTH
        )
      port map(
        Clk_in         => Clk_in,    
        Rst_in         => Rst_in,
        Func_in        =>      
        Const_in       =>     
        Const_vld_in   =>     
        A_in           =>     
        B_in           =>     
        C_in           =>     
        Data_out       =>      
      );
    
    
    
    
    
    
    
    
    
    
    
    
    
 

  end generate NODES_GEN;

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
    