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
    RST_ACTIVE         : std_logic := '0';
    DATA_IN_WIDTH      : integer   := 32    
  );
  port(
    Clk_in             : in  std_logic;
    Rst_in             : in  std_logic;
    A_in               : in  std_logic_vector(DATA_IN_WIDTH -1 downto 0);
    Data_out           : out std_logic_vector(DATA_IN_WIDTH -1 downto 0)
    );
    
  end dff_func;  
  
architecture Behavioral of dff_func is

begin

    process(Clk_in)
    
    begin
    
      if rising_edge(Clk_in)then
        if Rst_in = RST_ACTIVE then
          Data_out <= (others => '0');
        else
          Data_out <= A_in;
        end if;
      end if;
      
    end process;
    
end Behavioral;  
    