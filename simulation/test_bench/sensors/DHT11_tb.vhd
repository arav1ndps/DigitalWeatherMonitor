library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.DHT11_pck.all;

entity DHT11_tb is
end DHT11_tb;

architecture arch_DHT11_tb of DHT11_tb is
  component DHT11 is
--  generic(CLK_PERIOD: positive := 10; -- ns
--          HUMIITY_BITS: postive := 8);
  port(reset_n: in std_logic;
       clk: in std_logic;
       enable: in std_logic;
       measure: in std_logic;
       data: inout std_logic;
       state: out std_logic_vector(8 downto 0);
       counts: out natural range 0 to COUNTS_TIMER;
       humidity: out std_logic_vector(HUMIDITY_BITS-1 downto 0));
  end component;
 
  signal reset_n_tb_signal: std_logic := '0';
  signal clk_tb_signal: std_logic := '0';
  signal enable_tb_signal: std_logic := '0';
  signal measure_tb_signal: std_logic := '0';
  signal data_tb_signal: std_logic := 'H';
  signal state_tb_signal: std_logic_vector(8 downto 0) := (others => '0');
  signal counts_tb_signal: natural := HUMIDITY_BITS;
  signal humidity_tb_signal: std_logic_vector(HUMIDITY_BITS-1 downto 0) := (others => '0');

  constant CLK_PERIOD_TB: time := CLK_PERIOD*1 ns;
  constant PER_18MS_TB: time := COUNTS_18MS*CLK_PERIOD_TB + CLK_PERIOD_TB;
  constant PER_40US_TB: time := COUNTS_40US*CLK_PERIOD_TB;
  constant PER_80US_TB: time := COUNTS_80US*CLK_PERIOD_TB;
  constant PER_50US_TB: time := COUNTS_50US*CLK_PERIOD_TB;
  constant PER_70US_TB: time := COUNTS_70US*CLK_PERIOD_TB;
  constant PER_26US_TB: time := COUNTS_26US*CLK_PERIOD_TB;

  type input_array is array (0 to 7) of std_logic_vector(HUMIDITY_BITS-1 downto 0);
  signal test_vectors: input_array := ("11111111", "10101010", "00000000", "11010010", "11110000", "10010110", "10000000", "01010101");
begin
  DHT11_inst: component DHT11
--  generic(CLK_PERIOD: positive := 10; -- ns
--          HUMIITY_BITS: postive := 8);
    port map(reset_n => reset_n_tb_signal,
             clk => clk_tb_signal,
             enable => enable_tb_signal,
             measure => measure_tb_signal,
             data => data_tb_signal,
             state => state_tb_signal,
             counts => counts_tb_signal,
             humidity => humidity_tb_signal);

  clk_proc: process
  begin
    wait for CLK_PERIOD_TB/2;
    clk_tb_signal <= not clk_tb_signal;
  end process clk_proc;

  reset_n_tb_signal <= '1' after CLK_PERIOD_TB;
  enable_tb_signal <= '1' after CLK_PERIOD_TB;

  data_proc: process
  begin
    wait for CLK_PERIOD_TB;
    measure_tb_signal <= '1';
    wait for 105 ns;
    for i in 0 to test_vectors'length-1 loop 
      measure_tb_signal <= '0';
      data_tb_signal <= 'H';
      wait for PER_18MS_TB;
      data_tb_signal <= 'H';
      wait for PER_40US_TB;
      data_tb_signal <= '0';
      wait for PER_80US_TB;
      data_tb_signal <= 'H';
      wait for PER_80US_TB;
      for j in test_vectors(i)'length-1 downto 0 loop
        data_tb_signal <= '0'; 
        wait for PER_50US_TB;
        data_tb_signal <= 'H';
        if test_vectors(i)(j) = '1' then        
          wait for PER_70US_TB;
        else
          wait for PER_26US_TB;
        end if;
      end loop;
      data_tb_signal <= '0';
      measure_tb_signal <= '1'; 
      wait for PER_50US_TB;
      assert(humidity_tb_signal = test_vectors(i))
      report "wrong output"
      severity error;
    end loop;
  end process data_proc;   
end arch_DHT11_tb;
