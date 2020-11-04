-----------------------------------------------------------------------------------------------------------------------------------
-- Library and Package section
-----------------------------------------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-----------------------------------------------------------------------------------------------------------------------------------
-- Entity section
-----------------------------------------------------------------------------------------------------------------------------------

entity const_func is
  generic(
    RST_ACTIVE         : std_logic := '0';
    DATA_IN_WIDTH      : integer   := 32    
  );
  port(
    Clk_in             : in  std_logic;
    Rst_in             : in  std_logic;
    Const_vld_in       : in  std_logic; 
    Const_in           : in  std_logic_vector(DATA_IN_WIDTH-1 downto 0);
    Data_out           : out std_logic_vector(DATA_IN_WIDTH-1 downto 0)
  );
    
  end const_func;  
  
architecture Behavioral of const_func is

  signal const : std_logic_vector(DATA_IN_WIDTH-1 downto 0);

begin

  Data_out <= const;

  process(Clk_in)
  
  begin
  
    if rising_edge(Clk_in)then
      if Rst_in = RST_ACTIVE then
        const <= (others => '0');
      else
        if Const_vld_in = '1' then
          const <= Const_in;
        end if;
      end if;
    end if;
  end process;
  
end Behavioral;  
    