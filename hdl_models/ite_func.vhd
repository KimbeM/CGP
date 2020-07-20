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
    A                  : in std_logic_vector(DATA_IN_WIDTH -1 downto 0);
    B                  : in std_logic_vector(DATA_IN_WIDTH -1 downto 0);
    C                  : in std_logic_vector(DATA_IN_WIDTH -1 downto 0);
    Data_out           : out std_logic_vector(DATA_IN_WIDTH -1 downto 0)
    );
    
  end ite_func;  
  
architecture Behavioral of ite_func is

begin
    Data_out <= B when A /= x"00000000" else C;
end Behavioral;  
    