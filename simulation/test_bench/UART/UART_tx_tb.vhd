library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.UART_pack.all;
use WORK.decoder_pack.all;

entity UART_tx_tb is
end UART_tx_tb;

architecture arch_UART_tx_tb of UART_tx_tb is
  component UART_tx is
--  generic(CLK_PERIOD: positive := 10; -- ns
--          BAUDRATE: positive := 9600); -- bit/s
    port(reset_n: in std_logic;
         clk: in std_logic;
         enable: in std_logic;
         start: in std_logic;
         data_in: in str;
         tx: out std_logic);
  end component;

  signal reset_n_tb_signal: std_logic := '1';
  signal clk_tb_signal: std_logic := '0';
  signal enable_tb_signal: std_logic := '1';
  signal start_tb_signal: std_logic := '1';
  signal data_in_tb_signal: str := (x"31",x"32",x"34",x"36",x"38",x"40",x"3A",x"51",x"61",x"81",x"91",x"23",x"14",x"07",x"3F",x"3E",x"3B",x"1C",x"2E",x"35",x"32");
  signal tx_tb_signal: std_logic;
begin
  UART_inst: component UART_tx
--  generic(CLK_PERIOD: positive := 10; -- ns
--          BAUDRATE: positive := 9600); -- bit/s
    port map(reset_n => reset_n_tb_signal,
         clk => clk_tb_signal,
         enable => enable_tb_signal,
         start => start_tb_signal,
         data_in => data_in_tb_signal,
         tx => tx_tb_signal);

  clk_proc: process
  begin
    wait for 5 ns;
    clk_tb_signal <= not clk_tb_signal;
  end process clk_proc;
end arch_UART_tx_tb;