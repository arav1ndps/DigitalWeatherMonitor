library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity clock_generator_tb is
  
end clock_generator_tb;

architecture arch_clock_generator_tb of clock_generator_tb is
  component clock_generator is
    generic(COUNTS:integer := 10;
            SHIFT:integer := 0);
    port(reset_n:in std_logic;
         clk:in std_logic;
         enable:in std_logic;
         q: out std_logic);
  end component clock_generator;
  signal reset_n_tb_signal: std_logic := '0';
  signal clk_tb_signal: std_logic := '0';
  signal enable_tb_signal: std_logic := '0';
  signal q_tb_signal: std_logic := '1';
  constant COUNTS_TB: integer := 10;
  constant SHIFT_TB: integer := 0;
  constant CYCLES: integer := 20;
  constant CLK_PERIOD: time := 10 ns;
begin
  clock_generator_inst: component clock_generator
    generic map(COUNTS => COUNTS_TB,
                SHIFT => SHIFT_TB)
    port map(reset_n => reset_n_tb_signal,
             clk => clk_tb_signal,
             enable => enable_tb_signal,
             q => q_tb_signal);
  
  clk_proc: process
  begin
    wait for CLK_PERIOD/2;
    clk_tb_signal <= not(clk_tb_signal);
  end process clk_proc;

  reset_n_tb_signal <= '0',
                       '1' after 20 ns;
  
  enable_tb_signal <= '0',
                      '1' after 40 ns;

  test_proc_q: process
    variable q_test: std_logic := '0';
  begin
    wait for 33 ns;
    for i in 0 to CYCLES - 1 loop
      wait for 50 ns;
      q_test := not q_test;
      assert(q_tb_signal = q_test)
      report "wrong value for q"
      severity error;     
    end loop;
  end process test_proc_q;

end arch_clock_generator_tb;
