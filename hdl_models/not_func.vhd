-----------------------------------------------------------------------------------------------------------------------------------
-- Library and Package section
-----------------------------------------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-----------------------------------------------------------------------------------------------------------------------------------
-- Entity section
-----------------------------------------------------------------------------------------------------------------------------------

entity not_func is
  generic(
    DATA_IN_WIDTH      : integer := 32    
  );
  port(
    A_in               : in std_logic_vector(DATA_IN_WIDTH -1 downto 0);
    Data_out           : out std_logic_vector(DATA_IN_WIDTH -1 downto 0)
    );
    
  end not_func;  
  
architecture Behavioral of not_func is

begin
    Data_out(31 downto 1) <= (others => '0');
    Data_out(0) <= '1' when A_in = x"00000000" else '0';
end Behavioral;  
    