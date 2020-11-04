-----------------------------------------------------------------------------------------------------------------------------------
-- Library and Package section
-----------------------------------------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-----------------------------------------------------------------------------------------------------------------------------------
-- Entity section
-----------------------------------------------------------------------------------------------------------------------------------

entity mult_func is
  generic(
    DATA_IN_WIDTH      : integer := 32    
  );
  port(
    A_in               : in std_logic_vector(DATA_IN_WIDTH -1 downto 0);
    B_in               : in std_logic_vector(DATA_IN_WIDTH -1 downto 0);
    Data_out           : out std_logic_vector(DATA_IN_WIDTH -1 downto 0)
    );
    
  end mult_func;  
  
architecture Behavioral of mult_func is

begin
    Data_out <= std_logic_vector(resize(signed(A_in) * signed(B_in), Data_out'length));
end Behavioral;  
    