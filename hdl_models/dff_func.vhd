-----------------------------------------------------------------------------------------------------------------------------------
-- Library and Package section
-----------------------------------------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-----------------------------------------------------------------------------------------------------------------------------------
-- Entity section
-----------------------------------------------------------------------------------------------------------------------------------

entity dff_func is
  generic(
    DATA_IN_WIDTH      : integer := 32    
  );
  port(
    Clk_in             : in std_logic;
    A                  : in std_logic_vector(DATA_IN_WIDTH -1 downto 0);
    B                  : in std_logic_vector(DATA_IN_WIDTH -1 downto 0);
    C                  : in std_logic_vector(DATA_IN_WIDTH -1 downto 0);
    Data_out           : out std_logic_vector(DATA_IN_WIDTH -1 downto 0)
    );
    
  end dff_func;  
  
architecture Behavioral of dff_func is

begin

    process(Clk_in)
    
    begin
    
      if rising_edge(Clk_in)then
        Data_out <= A;
      end if;
      
    end process;
    
end Behavioral;  
    