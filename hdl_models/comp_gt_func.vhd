-----------------------------------------------------------------------------------------------------------------------------------
-- Library and Package section
-----------------------------------------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-----------------------------------------------------------------------------------------------------------------------------------
-- Entity section
-----------------------------------------------------------------------------------------------------------------------------------

entity comp_gt_func is
  generic(
    DATA_IN_WIDTH      : integer := 32    
  );
  port(
    A_in               : in std_logic_vector(DATA_IN_WIDTH -1 downto 0);
    B_in               : in std_logic_vector(DATA_IN_WIDTH -1 downto 0);
    Data_out           : out std_logic_vector(DATA_IN_WIDTH -1 downto 0)
    );
    
  end comp_gt_func;  
  
architecture Behavioral of comp_gt_func is

begin
    Data_out(31 downto 1) <= (others => '0');
    Data_out(0) <= '1' when signed(A_in) > signed(B_in) else '0';
end Behavioral;  
    