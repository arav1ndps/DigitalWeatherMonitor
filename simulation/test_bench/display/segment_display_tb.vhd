library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.segment_pack.all;

entity segment_display_tb is
end segment_display_tb;

architecture arch_segment_display_tb of segment_display_tb is

  component segment_display is
    generic(FPS: natural range 30 to 90 := 60;
            CLK_PERIOD: natural:= 10; -- ns
            DIGITS: positive range 1 to 8 := 4);
    port(reset_n: in std_logic;
         clk: in std_logic;
         enable: in std_logic;
         digit_vals: in digit_array;
         CA: out std_logic_vector(7 downto 0);
         AN: out std_logic_vector(7 downto 0));
  end component;

  signal reset_n_tb_signal: std_logic := '0';
  signal clk_tb_signal: std_logic := '0';
  signal enable_tb_signal: std_logic := '0';
  signal digit_vals_tb_signal: digit_array := (0,0,0,0,16,0,1,4);
  signal CA_tb_signal: std_logic_vector(7 downto 0) := (others => '0');
  signal AN_tb_signal: std_logic_vector(7 downto 0) := (others => '0');

begin

  segment_display_inst: component segment_display
    port map(reset_n => reset_n_tb_signal,
             clk => clk_tb_signal,
             enable => enable_tb_signal,
             digit_vals => digit_vals_tb_signal,
             CA => CA_tb_signal,
             AN => AN_tb_signal);

  clk_proc: process
  begin
    wait for 5 ns;
    clk_tb_signal <= not(clk_tb_signal);
  end process clk_proc;

  enable_tb_signal <= '1';

  reset_n_tb_signal <= '0',
                       '1' after 10 ns;

  
end arch_segment_display_tb;
