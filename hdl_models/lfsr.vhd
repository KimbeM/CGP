library ieee; 
use ieee.std_logic_1164.all;

entity lfsr is 
  generic(
    RST_ACTIVE  : std_logic := '0';
  );
  port (
    Clk_in      : in  std_logic;
    Rst_in      : in  std_logic;
    Seed_in     : in  std_logic_vector (6 downto 0);
    Lfsr_out    : out std_logic_vector (6 downto 0));
  end lfsr;

architecture rtl of lfsr is  

  signal lfsr_i           : std_logic_vector (7 downto 1);

begin  
  
  Lfsr_out  <= lfsr_i(7 downto 1);
  
  process (Clk_in) 
  
  begin 
  
    if rising_edge(Clk_in) then 
      if Rst_in = RST_ACTIVE then
        lfsr_i   <= Seed_in;
      elsif (i_en = '1') then 
        lfsr_i(7) <= lfsr_i(1);
        lfsr_i(6) <= lfsr_i(7) xor lfsr_i(1);
        lfsr_i(5) <= lfsr_i(6);
        lfsr_i(4) <= lfsr_i(5);
        lfsr_i(3) <= lfsr_i(4);
        lfsr_i(2) <= lfsr_i(3);
        lfsr_i(1) <= lfsr_i(2);
      end if; 
    end if;
    
  end process; 

end architecture rtl;