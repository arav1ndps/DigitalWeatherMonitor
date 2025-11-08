library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity clock_generator_inv is
  generic(COUNTS:integer := 10;
          SHIFT:integer := 0);
  port(reset_n:in std_logic;
       clk:in std_logic;
       enable:in std_logic;
       q:out std_logic);
end clock_generator_inv;

architecture arch_clock_generator_inv of clock_generator_inv is
  signal count_signal:integer range 0 to COUNTS := SHIFT;
  signal q_signal: std_logic := '0';
begin
  q <= q_signal;
  clock_proc: process(clk)
  begin
    if rising_edge(clk) then
      if reset_n = '0' then
        count_signal <= SHIFT;
        q_signal <= '0';
      elsif enable = '1' then
        count_signal <= count_signal+1;
        if count_signal = COUNTS/2-1 then
          count_signal <= 0;
          q_signal <= not q_signal;
        end if;
      end if;
    end if;
  end process clock_proc;
end arch_clock_generator_inv;
