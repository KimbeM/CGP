-----------------------------------------------------------------------------------------------------------------------------------
-- Library and Package section
-----------------------------------------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-----------------------------------------------------------------------------------------------------------------------------------
-- Entity section
-----------------------------------------------------------------------------------------------------------------------------------

entity cnt_func is
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
    
  end cnt_func;  
  
architecture Behavioral of cnt_func is

  signal cnt : signed(DATA_IN_WIDTH -1 downto 0) := (others => '0');

begin

  Data_out <= std_logic_vector(cnt);

  process(Clk_in)
    
  begin
    
    if rising_edge(Clk_in)then
      if cnt < 2**(DATA_IN_WIDTH-1)-1 then 
        cnt <= cnt + 1;
      else
        cnt <= (others => '0');
      end if;
    end if;
      
  end process;
    
end Behavioral;  
    