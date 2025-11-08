library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity counter_down is
  generic(COUNTS:integer := 10);
  port(reset_n:in std_logic;
       clk:in std_logic;
       enable:in std_logic;
       q:out std_logic;
       count:out integer range 0 to COUNTS);
end counter_down;

architecture arch_counter_down of counter_down is
  signal count_signal:integer range 0 to COUNTS := COUNTS-1;
begin
  count <= count_signal;
  counter_proc: process(clk)
  begin
    if rising_edge(clk) then
      q <= '0';
      if reset_n = '0' then
        count_signal <= COUNTS-1;
      elsif enable = '1' then
        if count_signal <= 0 then
          count_signal <= COUNTS-1;
          q <= '1';
        else
          count_signal <= count_signal-1;
        end if;
      end if;
    end if;
  end process counter_proc;
end arch_counter_down;