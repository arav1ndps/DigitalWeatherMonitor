library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity counter is
  generic(COUNTS:integer := 10;
          SHIFT:integer := 0);
  port(reset_n:in std_logic;
       clk:in std_logic;
       enable:in std_logic;
       q:out std_logic;
       count:out integer range 0 to COUNTS);
end counter;

architecture arch_counter of counter is
  signal count_signal:integer range 0 to COUNTS := SHIFT;
begin
  count <= count_signal;
  counter_proc: process(clk)
  begin
    if rising_edge(clk) then
      q <= '0';
      if reset_n = '0' then
        count_signal <= SHIFT;
      elsif enable = '1' then
        count_signal <= count_signal+1;
        if count_signal = COUNTS-1 then
          count_signal <= 0;
          q <= '1';
        end if;
      end if;
    end if;
  end process counter_proc;
end arch_counter;