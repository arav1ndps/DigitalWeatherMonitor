library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use work.DHT11_pack.all;

entity DHT11_wrapper is
  generic(CLK_PERIOD: positive := 10; -- ns
          HUMIDITY_BITS: positive := 8);
  port(reset_n: in std_logic;
       clk: in std_logic;
       enable: in std_logic;
       humidity: out std_logic_vector(HUMIDITY_BITS-1 downto 0);
       data: inout std_logic);
end DHT11_wrapper;

architecture arch_DHT11_wrapper of DHT11_wrapper is
  component DHT11 is
    generic(CLK_PERIOD: positive := 10; -- ns
            HUMIDITY_BITS: positive := 8);
    port(reset_n: in std_logic;
         clk: in std_logic;
         enable: in std_logic;
         measure: in std_logic;
         data: inout std_logic;
         humidity: out std_logic_vector(HUMIDITY_BITS-1 downto 0));
  end component;
  
  signal measure_signal: std_logic;
  signal reset_signal: std_logic;
  
  signal humidity_signal: std_logic_vector(HUMIDITY_BITS-1 downto 0);
  
  constant COUNTS_1S: positive := 1000000000/CLK_PERIOD;
  constant COUNTS_100NS: positive := 100/CLK_PERIOD;
  constant COUNTS_500NS: positive := 500/CLK_PERIOD;
begin

  sensor: component DHT11
    generic map(CLK_PERIOD => CLK_PERIOD,
                HUMIDITY_BITS => HUMIDITY_BITS)
    port map(reset_n => reset_signal,
            clk => clk,
            enable => enable,
            measure => measure_signal,
            humidity => humidity_signal,
            data => data); 
  
  counter_1s: process(clk)
    variable counts: natural range 0 to COUNTS_1S;
  begin
    if rising_edge(clk) then
      if reset_n = '0' then
        counts := 0;
        measure_signal <= '0';
        reset_signal <= '0';
        humidity <= (others => '0');
      elsif enable = '1' then
        counts := counts+1;
        if counts = COUNTS_1S-1 then
          measure_signal <= '0';
          counts := 0;
        elsif counts = COUNTS_1S/2-1 then
          humidity <= humidity_signal;
        elsif counts = COUNTS_1S-COUNTS_500NS then
          reset_signal <= '0';
        elsif counts = COUNTS_1S-COUNTS_100NS then
          measure_signal <= '1';
          reset_signal <= '1';
        end if;
      end if;
    end if;
  end process counter_1s;
              
end arch_DHT11_wrapper;
