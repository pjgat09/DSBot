library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use IEEE.NUMERIC_STD.ALL;

entity command_responder is
    Port ( clk : in  STD_LOGIC;
           x_val : in  STD_LOGIC_VECTOR (15 downto 0);
           y_val : in  STD_LOGIC_VECTOR (15 downto 0);
           frame_flag : out  STD_LOGIC;
           
           sclk : in  STD_LOGIC;
           en : in  STD_LOGIC;
           di : in  STD_LOGIC;
           do : out  STD_LOGIC;
           l : out STD_LOGIC_VECTOR(3 downto 0));
end command_responder;

architecture Behavioral of command_responder is
  signal in_buffer : std_logic_vector(7 downto 0) := "00000000";
  
  signal out_buffer : std_logic_vector(16 downto 0) := "00000000000000000";
  
  signal prev_en : std_logic := '1';
  signal prev_sclk : std_logic := '1';
  
  signal en_buf : std_logic_vector(2 downto 0) := "111";
  signal sclk_buf : std_logic_vector(2 downto 0) := "111";
  
  signal y_counter : integer range 0 to 5 := 0;
  
  signal frame_completed : std_logic := '0';
  
  signal debug : std_logic := '0';
begin
  process (clk) is
  begin
    
    if (clk'event and clk = '1') then
      -- On falling edge of enable
      en_buf <= en_buf(1 downto 0) & en;
      if (en_buf = "000" and prev_en = '1') then
        -- Clear the buffers
        in_buffer <= "00000000";
        out_buffer <= "00000000000000000";
        prev_en <= '0';
      elsif (en_buf = "111" and prev_en = '0') then
        y_counter <= 0;
        frame_completed <= '0';
        prev_en <= '1';
      end if;
      
      if (en = '0') then
        sclk_buf <= sclk_buf(1 downto 0) & sclk;
      
        -- Falling edge of sclk
        if (sclk_buf= "000" and prev_sclk = '1') then
          prev_sclk <= '0';
          out_buffer <= out_buffer(15 downto 0) & '0';
          
        -- Rising edge of sclk
        elsif (sclk_buf = "111" and prev_sclk = '0') then
          in_buffer <= in_buffer(6 downto 0) & di;
          prev_sclk <= '1';
          debug <= not debug;
        end if;

        if (in_buffer = X"84") then
          in_buffer <= "00000000";
          out_buffer <= '0' & "0001011101000000";
        elsif (in_buffer = X"D1") then
          in_buffer <= "00000000";
          out_buffer <= '0' & "0101110110011000";
        elsif (in_buffer = X"91") then
          in_buffer <= "00000000";
          out_buffer <= '0' & "0100010101011000";
          if (frame_completed = '0') then
            if (y_counter = 5) then
              frame_completed <= '1';
            else
              y_counter <= y_counter + 1;
            end if;
          end if;
        end if;
      end if;
    end if;
  end process;

  do <= out_buffer(16) when en = '0'
        else '1';
        
  l <= debug & in_buffer(2 downto 0);
        
  frame_flag <= frame_completed;
end Behavioral;

