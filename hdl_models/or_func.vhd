-----------------------------------------------------------------------------------------------------------------------------------
-- Library and Package section
-----------------------------------------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-----------------------------------------------------------------------------------------------------------------------------------
-- Entity section
-----------------------------------------------------------------------------------------------------------------------------------

entity or_func is
  generic(
    DATA_IN_WIDTH      : integer := 32    
  );
  port(
    A                  : in std_logic_vector(DATA_IN_WIDTH -1 downto 0);
    B                  : in std_logic_vector(DATA_IN_WIDTH -1 downto 0);
    C                  : in std_logic_vector(DATA_IN_WIDTH -1 downto 0);
    Data_out           : out std_logic_vector(DATA_IN_WIDTH -1 downto 0)
    );
    
  end or_func;  
  
architecture Behavioral of or_func is

begin
    Data_out(31 downto 1) <= (others => '0');
    Data_out(0) <= '1' when A /= x"00000000" or B /= x"00000000" else '0';
end Behavioral;  
    