library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity counter_tb is
  
end counter_tb;

architecture arch_counter_tb of counter_tb is
  component counter is
    generic(COUNTS:integer := 10;
            SHIFT:integer := 0);
    port(reset_n:in std_logic;
         clk:in std_logic;
         enable:in std_logic;
         q:out std_logic;
         count:out integer range 0 to COUNTS);
  end component counter;
  signal reset_n_tb_signal: std_logic := '0';
  signal clk_tb_signal: std_logic := '0';
  signal enable_tb_signal: std_logic := '0';
  signal q_tb_signal: std_logic := '0';
  signal count_tb_signal: integer := 0;
  constant COUNTS_TB: integer := 10;
  constant SHIFT_TB: integer := 0;
  constant CLK_PERIOD: time := 10 ns;
begin
  counter_inst: component counter
    generic map(COUNTS => COUNTS_TB,
                SHIFT => SHIFT_TB)
    port map(reset_n => reset_n_tb_signal,
             clk => clk_tb_signal,
             enable => enable_tb_signal,
             q => q_tb_signal,
             count => count_tb_signal);
  
  clk_proc: process
  begin
    wait for CLK_PERIOD/2;
    clk_tb_signal <= not(clk_tb_signal);
  end process clk_proc;

  reset_n_tb_signal <= '0',
                       '1' after 20 ns;
  
  enable_tb_signal <= '0',
                      '1' after 40 ns;

  test_proc_count: process
  begin
    wait for 36 ns;
    for i in 0 to COUNTS_TB-1 loop
      assert(count_tb_signal = i)
      report "wrong value for count"
      severity error;
      wait for 10 ns;
    end loop;
  end process test_proc_count;

  test_proc_q: process
  begin
    wait for 36 ns;
    for i in 0 to COUNTS_TB - 1 loop
      wait for 100 ns;
      assert(count_tb_signal = i)
      report "wrong value for q"
      severity error;      
    end loop;
  end process test_proc_q;

end arch_counter_tb;