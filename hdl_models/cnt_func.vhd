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
    RST_ACTIVE         : std_logic := '0';
    CNT_MAX            : integer   := 15;
    DATA_IN_WIDTH      : integer   := 32    
  );
  port(
    Clk_in             : in std_logic;
    Rst_in             : in std_logic;
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
      if Rst_in = RST_ACTIVE then
        cnt <= (others => '0');
      else
        if cnt < CNT_MAX then 
          cnt <= cnt + 1;
        else
          cnt <= (others => '0');
        end if;
      end if;
    end if;
      
  end process;
    
end Behavioral;  
    