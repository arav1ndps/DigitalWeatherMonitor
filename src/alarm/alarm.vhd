library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity alarm is
    Generic (CLK_PERIOD: positive := 10;
             FREQ1: positive := 400; -- Hz
             FREQ2: positive := 1200); -- Hz
    Port ( reset_n : in STD_LOGIC;
           clk : in STD_LOGIC;
           enable : in STD_LOGIC;
           speaker_out : out STD_LOGIC);
end alarm;

architecture arch_alarm of alarm is
  constant COUNTS_FREQ1: positive := 1000000000/(CLK_PERIOD*FREQ1);
  constant COUNTS_FREQ2: positive := 1000000000/(CLK_PERIOD*FREQ2);
  
  signal freq1_signal: std_logic;
  signal freq2_signal: std_logic;
  
  component clock_generator is
    generic(COUNTS:integer := 10;
            SHIFT:integer := 0);
    port(reset_n:in std_logic;
         clk:in std_logic;
         enable:in std_logic;
         q:out std_logic);
  end component;
  
begin
  clk_freq1: component clock_generator
    generic map(COUNTS => COUNTS_FREQ1)
    port map(reset_n => reset_n,
             clk => clk,
             enable => enable,
             q => freq1_signal);

  clk_freq2: component clock_generator
    generic map(COUNTS => COUNTS_FREQ2)
    port map(reset_n => reset_n,
             clk => clk,
             enable => enable,
             q => freq2_signal);
             
  speaker_out <= freq1_signal xor freq2_signal;

end arch_alarm;
