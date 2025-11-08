library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity SPI_ADC_tb is
end SPI_ADC_tb;

architecture arch_SPI_ADC_tb of SPI_ADC_tb is
  component SPI_ADC is
--    Generic (READ_BITS: positive := 12;
--             CLK_FREQ: positive := 100000; -- kHz
--             SPI_FREQ: positive := 2000); -- kHz
    Port ( reset_n : in STD_LOGIC;
           clk : in STD_LOGIC;
           enable : in STD_LOGIC;
           sample : in STD_LOGIC;
           CS : out STD_LOGIC;
           SPI_CLK : out STD_LOGIC;
           MOSI : out STD_LOGIC;
           MISO : in STD_LOGIC;
--           data : out std_logic_vector(READ_BITS-1 downto 0));
           data : out std_logic_vector(11 downto 0));
  end component;
  
  signal reset_n_tb_signal: std_logic := '0';
  signal clk_tb_signal: std_logic := '0';
  signal enable_tb_signal: std_logic := '0';
  signal sample_tb_signal: std_logic := '0';
  signal CS_tb_signal: std_logic := '0';
  signal SPI_CLK_tb_signal: std_logic := '0';
  signal MOSI_tb_signal: std_logic := '0';
  signal MISO_tb_signal: std_logic := '0';
  signal data_tb_signal: std_logic_vector(11 downto 0) := (others => '0');
  
  constant CLK_PERIOD: time := 10 ns;        
begin
  SPI_ADC_inst: component SPI_ADC
    port map ( reset_n => reset_n_tb_signal, 
               clk => clk_tb_signal,
               enable => enable_tb_signal,
               sample => sample_tb_signal,
               CS => CS_tb_signal,
               SPI_CLK => SPI_CLK_tb_signal,
               MOSI => MOSI_tb_signal,
               MISO => MISO_tb_signal,
               data => data_tb_signal);
  
  clk_proc: process
  begin
    wait for CLK_PERIOD/2;
    clk_tb_signal <= not clk_tb_signal;
  end process clk_proc;
  
  reset_n_tb_signal <= '1';
  enable_tb_signal <= '1';
  sample_tb_signal <= '1',
                      '0' after 2*CLK_PERIOD;
  

end arch_SPI_ADC_tb;
