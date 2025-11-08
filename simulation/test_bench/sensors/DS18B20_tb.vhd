library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.DS18B20_pack.all;

entity DS18B20_tb is
end DS18B20_tb;

architecture arch_DS18B20_tb of DS18B20_tb is
  component DS18B20 is
    port(reset_n: in std_logic;
         clk: in std_logic;
         enable: in std_logic;
         data: inout std_logic;
--         state: out std_logic_vector(6 downto 0);
         temperature: out std_logic_vector(TEMP_LEN-1 downto 0));
  end component;

  constant CLK_PERIOD_TB: time := CLK_PERIOD*1 ns;
  constant TIME_1S: time := COUNTS_1S*CLK_PERIOD_TB;
  constant TIME_750MS: time := COUNTS_750MS*CLK_PERIOD_TB;
  constant TIME_480US: time := COUNTS_480US*CLK_PERIOD_TB;
  constant TIME_1US: time := COUNTS_1US*CLK_PERIOD_TB;
  constant TIME_10US: time := COUNTS_10US*CLK_PERIOD_TB;
  constant TIME_60US: time := COUNTS_60US*CLK_PERIOD_TB;
  
  signal reset_n_tb_signal: std_logic := '0';
  signal clk_tb_signal: std_logic := '0';
  signal enable_tb_signal: std_logic := '0';
  signal data_tb_signal: std_logic := 'H';
  signal temperature_tb_signal: std_logic_vector(TEMP_LEN-1 downto 0);

  signal temperature_data: std_logic_vector(TEMP_LEN-1 downto 0) := "1110001001001";

  signal test_tb_signal: std_logic;

begin
  DS18B20_inst: component DS18B20
    port map(reset_n => reset_n_tb_signal,
             clk => clk_tb_signal,
             enable => enable_tb_signal,
             data => data_tb_signal,
             temperature => temperature_tb_signal);

  clk_proc: process
  begin 
    wait for CLK_PERIOD_TB/2;
    clk_tb_signal <= not clk_tb_signal;
  end process clk_proc;

  reset_n_tb_signal <= '1' after CLK_PERIOD_TB;
  enable_tb_signal <= '1' after CLK_PERIOD_TB;

  data_proc: process
  begin
    wait for 2*CLK_PERIOD_TB;
    for i in 0 to INST_NUM-1 loop
      if i mod 2 = 0 then
        assert(data_tb_signal = '0')
        report "wrong init"
        severity error;
        wait for TIME_480US;
        assert(data_tb_signal = 'H')
        report "bus not released"
        severity error;
        wait for TIME_480US;
      end if;
      for j in 0 to INST_LEN-1 loop
        assert(data_tb_signal = 'H')
        report "No restore time"
        severity error;
        wait for TIME_1US;
        assert(data_tb_signal = '0')
        report "No initialization of write bit"
        severity error;  
        wait for TIME_1US;
        assert(data_tb_signal = INSTRUCTIONS(i)(j))
        report "wrong value" 
        severity error;
        wait for TIME_60US-2*TIME_1US;
      end loop;
    end loop;
    wait for TIME_1S-CONS_INST*2*TIME_480US-INST_LEN*CONS_INST*CONS_INST*TIME_60US-2*CLK_PERIOD_TB;
  end process data_proc;

  presence: process
  begin
    data_tb_signal <= 'H'; -- test waveform
    wait for 3*CLK_PERIOD_TB/2;
    for i in 0 to INST_NUM-1 loop
      if i mod 2 = 0 then
        if i = 2 then
          wait for TIME_750MS;
        end if;
        data_tb_signal <= 'H';
        wait for TIME_480US+TIME_60US;
        data_tb_signal <= '0';
        wait for TIME_60US;
        data_tb_signal <= 'H';
        wait for TIME_480US-TIME_60US*2;
      end if;
      for j in 0 to INST_LEN-1 loop
        wait for TIME_1US;
        wait for TIME_1US;
        wait for TIME_60US-2*TIME_1US;
      end loop;
    end loop;
    wait for TIME_1S-CONS_INST*2*TIME_480US-INST_LEN*CONS_INST*CONS_INST*TIME_60US-3*CLK_PERIOD_TB/2;
  end process presence;

  write_pattern: process
  begin
    test_tb_signal <= 'H'; -- test waveform
    wait for 3*CLK_PERIOD_TB/2;
    for i in 0 to INST_NUM-1 loop
      if i mod 2 = 0 then
        test_tb_signal <= '0';
        wait for TIME_480US;
        test_tb_signal <= '1';
        wait for TIME_480US;
      end if;
      for j in 0 to INST_LEN-1 loop
        test_tb_signal <= '1';
        wait for TIME_1US;
        test_tb_signal <= '0';
        wait for TIME_1US;
        test_tb_signal <= INSTRUCTIONS(i)(j);
        wait for TIME_60US-2*TIME_1US;
      end loop;
    end loop;
    wait for TIME_1S-CONS_INST*2*TIME_480US-INST_LEN*CONS_INST*CONS_INST*TIME_60US-3*CLK_PERIOD_TB/2;
  end process write_pattern;

--  data_input: process
--  begin
--    wait for 40355 ns;
--    for i in 0 to temperature_data'length-1 loop
--      wait for TIME_1US + TIME_10US/2;
--      data_tb_signal <= temperature_data(i);
--      wait for TIME_60US - TIME_10US/2;
--    end loop;
--  end process data_input;
end arch_DS18B20_tb;
