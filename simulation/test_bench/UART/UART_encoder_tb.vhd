library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.UART_pack.all;
use WORK.decoder_pack.all;

entity UART_encoder_tb is
end UART_encoder_tb;

architecture arch_UART_encoder_tb of UART_encoder_tb is
  component UART_encoder is
    port(reset_n: in std_logic;
         clk: in std_logic;
         enable: in std_logic;
         temp_in: in symbol_array;
         hum_in: in symbol_array;
         air_in: in symbol_array;
         data_out: out str);
  end component;

  signal reset_n_tb_signal: std_logic := '0';
  signal clk_tb_signal: std_logic := '0';
  signal enable_tb_signal: std_logic := '0';
  signal temp_in_tb_signal: symbol_array := (10,5,5);
  signal hum_in_tb_signal: symbol_array := (0,4,5);
  signal air_in_tb_signal: symbol_array := (2,3,4);
  signal data_out_tb_signal: str;
begin
  encoder_inst: component UART_encoder
    port map(reset_n => reset_n_tb_signal,
             clk => clk_tb_signal,
             enable => enable_tb_signal,
             temp_in => temp_in_tb_signal,
             hum_in => hum_in_tb_signal,
             air_in => air_in_tb_signal,
             data_out => data_out_tb_signal);

  reset_n_tb_signal <= '1' after 20 ns;
  enable_tb_signal <= '1' after 20 ns;
  
  clk_proc: process
  begin
    wait for 5 ns;
    clk_tb_signal <= not clk_tb_signal;
  end process clk_proc;
end arch_UART_encoder_tb;
