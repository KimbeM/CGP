-----------------------------------------------------------------------------------------------------------------------------------
-- Library and Package section
-----------------------------------------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-----------------------------------------------------------------------------------------------------------------------------------
-- Entity section
-----------------------------------------------------------------------------------------------------------------------------------

entity ite_func is
  generic(
    DATA_IN_WIDTH      : integer := 32    
  );
  port(
    A_in               : in std_logic_vector(DATA_IN_WIDTH -1 downto 0);
    B_in               : in std_logic_vector(DATA_IN_WIDTH -1 downto 0);
    C_in               : in std_logic_vector(DATA_IN_WIDTH -1 downto 0);
    Data_out           : out std_logic_vector(DATA_IN_WIDTH -1 downto 0)
    );
    
  end ite_func;  
  
architecture Behavioral of ite_func is

begin
    Data_out <= B_in when A_in /= x"00000000" else C_in;
end Behavioral;  
    