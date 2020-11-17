library ieee; 
use ieee.std_logic_1164.all;

entity lfsr is 
  generic(
    RST_ACTIVE  : std_logic := '0'
  );
  port (
    Clk_in      : in  std_logic;
    Rst_in      : in  std_logic;
    Ena_in      : in  std_logic;
    Seed_in     : in  std_logic_vector (15 downto 0);
    Lfsr_out    : out std_logic_vector (15 downto 0)
   );
  end entity lfsr;

architecture rtl of lfsr is  

  signal lfsr_i           : std_logic_vector (15 downto 0);

begin  
  
  Lfsr_out  <= lfsr_i;
  
  process (Clk_in) 
  
  begin 
  
    if rising_edge(Clk_in) then 
      if Rst_in = RST_ACTIVE then
        lfsr_i   <= (others => '0');
      else
        if Ena_in = '1' then
          lfsr_i(0) <= lfsr_i(15) xor lfsr_i(14) xor lfsr_i(12) xor lfsr_i(3);
          for i in lfsr_i'length-1 downto 1 loop
            lfsr_i(i) <= lfsr_i(i-1);
          end loop;
        else
          lfsr_i <= Seed_in;
        end if;
      end if; 
    end if;
    
  end process; 

end architecture rtl;