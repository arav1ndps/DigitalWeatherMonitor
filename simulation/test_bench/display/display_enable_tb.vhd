library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity display_enable is
  generic(CLK_PERIOD: positive := 10;  -- ns
          EN_PERIOD: positive := 4000; -- ns
          DELAY: positive := 1000; -- ns
          HIGH_TIME: natural := 1000); -- ns
  port(clk: in std_logic;
       reset_n: in std_logic;
       enable_in: in std_logic;
       enable_out: out std_logic);
end display_enable;

architecture arch_display_enable of display_enable is
  constant COUNTS_CYCLE: positive := EN_PERIOD/CLK_PERIOD;
  constant COUNTS_DELAY: positive := DELAY/CLK_PERIOD;
  constant COUNTS_HIGH: positive := (DELAY + HIGH_TIME)/CLK_PERIOD;
  signal counts: natural := 0;
begin
  process(clk)
  begin
    if rising_edge(clk) then
      if reset_n = '0' then
        counts <= 0;
        enable_out <= '0'
      elsif enable_in = '1' then
        if counts >= COUNTS_DELAY and counts < COUNTS_HIGH then
          enable_out <= '1';
        elsif counts >= COUNTS_CYCLE then
          
      else
        counts <= counts;
        enable_out <= enable_out;
      end if;
    end if;
  end process;
end arch_display_eanble;
