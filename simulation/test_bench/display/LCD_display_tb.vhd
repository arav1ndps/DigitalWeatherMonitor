library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.LCD_pack.all;

entity LCD_display_tb is
end entity;

architecture arch_LCD_display_tb of LCD_display_tb is
  component LCD_display is
    port(reset_n: in std_logic;
         clk: in std_logic;
         enable: in std_logic;
         update: in std_logic;
         -- data: in char_array; -- comment out for testing
         E: out std_logic;
         RS: out std_logic;
         R_W: out std_logic;
         DB: out std_logic_vector(CHAR_NUM-1 downto 0));
--         state_out: out std_logic_vector(7 downto 0);
--         done_16ms_out: out std_logic;
--         done_5ms_out: out std_logic;
--         done_func_out: out std_logic;
--         done_100us_out: out std_logic;
--         done_data_out: out std_logic);
  end component;

  constant CLK_PERIOD_TB: time := CLK_PERIOD*1 ns;

  signal reset_n_tb_signal: std_logic := '0';
  signal clk_tb_signal: std_logic := '0';
  signal enable_tb_signal: std_logic := '0';
  signal update_tb_signal: std_logic := '0';
  -- signal data_tb_signal: char_array := (x"01", x"02", x"03", x"04", x"05", x"06", x"07", x"08"); -- comment out for testing
  signal E_tb_signal: std_logic := '0';
  signal RS_tb_signal: std_logic := '0';
  signal R_W_tb_signal: std_logic := '0';
  signal DB_tb_signal: std_logic_vector(CHAR_NUM-1 downto 0) := (others => '0');
  signal state_out_tb_signal: std_logic_vector(7 downto 0);
  
--  signal done_16ms_out_tb_signal: std_logic;
--  signal done_5ms_out_tb_signal: std_logic;
--  signal done_func_out_tb_signal: std_logic;
--  signal done_100us_out_tb_signal: std_logic;
--  signal done_data_out_tb_signal: std_logic;
begin
  LCD_display_inst: component LCD_display
    port map(reset_n => reset_n_tb_signal,
             clk => clk_tb_signal,
             enable => enable_tb_signal,
             update => update_tb_signal,
             -- data => data_tb_signal, -- comment out for testing
             E => E_tb_signal,
             RS => RS_tb_signal,
             R_W => R_W_tb_signal,
             DB => DB_tb_signal); --,
--             state_out => state_out_tb_signal,
--             done_16ms_out => done_16ms_out_tb_signal,
--             done_5ms_out => done_5ms_out_tb_signal,
--             done_func_out => done_func_out_tb_signal,
--             done_100us_out => done_100us_out_tb_signal,
--             done_data_out => done_data_out_tb_signal);
  
  clk_proc: process
  begin
    wait for CLK_PERIOD_TB/2;
    clk_tb_signal <= not clk_tb_signal;
  end process;

  reset_n_tb_signal <= '0',
                       '1' after 30 ns;
  enable_tb_signal <= '1';
  update_tb_signal <= '0';

end arch_LCD_display_tb;
