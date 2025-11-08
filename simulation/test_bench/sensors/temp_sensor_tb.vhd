library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity temp_sensor_tb is
end temp_sensor_tb;

architecture arch_temp_sensor_tb of temp_sensor_tb is
  component temp_sensor is
    port(SDA: inout std_logic;
         SCL: inout std_logic;
         clk: in std_logic;
         enable: in std_logic;
         reset_n: in std_logic;
         start_trans: in std_logic;
--       done: out std_logic;
         temperature: out signed(15 downto 0));
  end component;
  
  constant CLK_PERIOD: time := 10 ns;
  
  signal SDA_tb_signal: std_logic := '0';
  signal SCL_tb_signal: std_logic := '0';
  signal clk_tb_signal: std_logic := '0';
  signal enable_tb_signal: std_logic := '0';
  signal reset_n_tb_signal: std_logic := '0';
  signal start_trans_tb_signal: std_logic := '0';
  signal done_tb_signal: std_logic := '0';
  signal temperature_tb_signal: signed(15 downto 0) := (others => '0');
begin
  temp_sensor_inst: component temp_sensor
    port map(SDA => SDA_tb_signal,
             SCL => SCL_tb_signal,
             clk => clk_tb_signal,
             enable => enable_tb_signal,
             reset_n => reset_n_tb_signal,
             start_trans => start_trans_tb_signal,
             temperature => temperature_tb_signal);
             
   clock_proc: process 
   begin
     wait for CLK_PERIOD/2;
     clk_tb_signal <= not clk_tb_signal;
   end process clock_proc;
   
    reset_n_tb_signal <= '1';
    enable_tb_signal <= '1';
    start_trans_tb_signal <= '1';
end arch_temp_sensor_tb;
