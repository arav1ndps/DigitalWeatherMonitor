library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

entity SPI_ADC is
    generic(READ_BITS: positive := 12;
            CLK_FREQ: positive := 100000; -- kHz
            SPI_FREQ: positive := 500); -- kHz
    port(reset_n : in STD_LOGIC;
         clk : in STD_LOGIC;
         enable : in STD_LOGIC;
         sample : in STD_LOGIC;
         CS : out STD_LOGIC;
         SPI_CLK : out STD_LOGIC;
         MOSI : out STD_LOGIC;
         MISO : in STD_LOGIC;
         data : out std_logic_vector(READ_BITS-1 downto 0));
--           data : out std_logic_vector(11 downto 0));
end SPI_ADC;

architecture arch_SPI_ADC of SPI_ADC is

--  constant READ_BITS: positive := 12;
--  constant CLK_FREQ: positive := 100000; -- kHz
--  constant SPI_FREQ: positive := 2000; -- kHz

  constant SPI_CLK_COUNTS: positive := CLK_FREQ/SPI_FREQ;
  constant READ_SHIFT: positive := SPI_CLK_COUNTS/2;
  
  constant INPUT_MODE_BIT: std_logic := '1'; -- 1 single ended / 0 differential
  constant CHANNEL_BIT: std_logic := '0'; -- 1 channel 0 / 0 channel 1
  constant OUTPUT_MODE_BIT: std_logic := '1'; -- 1 MSB first / 0 LSB first (after MSB first output)
  
  signal en_SPI_CLK : std_logic := '0';
  signal rst_SPI_CLK: std_logic := '0';
  signal done_write: std_logic := '0';
  signal done_read: std_logic := '0';
  signal en_count_data: std_logic := '0';
  signal rst_count_data: std_logic := '0';
  signal done_count_data: std_logic := '0';
  
  type SPI_state_type is (idle, en_ADC, input_mode, channel, output_mode, null_bit, read_data, done);
  signal state_signal: SPI_state_type;
  signal next_state_signal: SPI_state_type;
  
  signal bit_read: integer range 0 to READ_BITS;

  component counter is
    generic(COUNTS:integer := 10;
            SHIFT:integer := 0);
    port(reset_n:in std_logic;
         clk:in std_logic;
         enable:in std_logic;
         q:out std_logic;
         count:out integer range 0 to COUNTS);
  end component;
  
  component counter_down is
    generic(COUNTS:integer := 10);
    port(reset_n:in std_logic;
         clk:in std_logic;
         enable:in std_logic;
         q:out std_logic;
         count:out integer range 0 to COUNTS);
  end component;
  
  component clock_generator_inv is
    generic(COUNTS:integer := 10;
            SHIFT:integer := 0);
    port(reset_n:in std_logic;
         clk:in std_logic;
         enable:in std_logic;
         q:out std_logic);
  end component;
begin
  SPI_clk_gen: component clock_generator_inv
    generic map(COUNTS => SPI_CLK_COUNTS)
    port map(reset_n => rst_SPI_CLK,
             clk => clk,
             enable => en_SPI_CLK,
             q => SPI_CLK);

  write_clk: component counter
    generic map(COUNTS => SPI_CLK_COUNTS)
    port map(reset_n => rst_SPI_CLK,
             clk => clk,
             enable => en_SPI_CLK,
             q => done_write);
            
  read_clk: component counter
    generic map(COUNTS => SPI_CLK_COUNTS,
                SHIFT => READ_SHIFT)
    port map(reset_n => rst_SPI_CLK,
             clk => clk,
             enable => en_SPI_CLK,
             q => done_read);
  
  data_counter: component counter_down
    generic map(COUNTS => READ_BITS)
    port map(reset_n => rst_count_data,
             clk => clk,
             enable => done_write,
             q => done_count_data,
             count => bit_read);
             
  
  state_trans_proc: process(clk)
  begin
    if rising_edge(clk) then
      if reset_n = '0' then
        state_signal <= idle;
      elsif enable = '1' then
        state_signal <= next_state_signal;
      else
        state_signal <= state_signal;
      end if;
    end if;
  end process state_trans_proc;
  
  state_flow_proc: process(state_signal, sample, done_write, done_read, done_count_data)
  begin
    case state_signal is
      when idle =>
        if sample = '1' then
          next_state_signal <= en_ADC;
        else
          next_state_signal <= state_signal;
        end if;
      when en_ADC =>
        if done_write = '1' then
          next_state_signal <= input_mode;
        else
          next_state_signal <= state_signal;
        end if;
      when input_mode =>
        if done_write = '1' then
          next_state_signal <= channel;
        else
          next_state_signal <= state_signal;
        end if;
      when channel =>
        if done_write = '1' then
          next_state_signal <= output_mode;
        else
          next_state_signal <= state_signal;
        end if;
      when output_mode =>
        if done_write = '1' then
          next_state_signal <= null_bit;
        else
          next_state_signal <= state_signal;
        end if;
      when null_bit =>
         if done_write = '1' then
          next_state_signal <= read_data;
        else
          next_state_signal <= state_signal;
        end if;
      when read_data =>
        if done_count_data = '1' then
          next_state_signal <= done;
        else
          next_state_signal <= state_signal;
        end if;
      when done =>
        if sample = '1' then
          next_state_signal <= en_ADC;
        else
          next_state_signal <= state_signal;
        end if;
    end case;
  end process state_flow_proc;
  
  assignment_proc: process (state_signal, MISO)
  begin
    case state_signal is
      when idle =>
        CS <= '1';
        MOSI <= '0';
        en_SPI_clk <= '0';
        rst_SPI_clk <= '0';
        rst_count_data <= '0';
        data <= (others => '0');
      when en_ADC =>
        CS <= '0';
        MOSI <= '1';
        en_SPI_clk <= '1';
        rst_SPI_clk <= '1';
        rst_count_data <= '0';
        data <= (others => '0');
      when input_mode =>
        CS <= '0';
        MOSI <= INPUT_MODE_BIT;
        en_SPI_clk <= '1';
        rst_SPI_clk <= '1';
        rst_count_data <= '0';
        data <= (others => '0');
      when channel =>
        CS <= '0';
        MOSI <= CHANNEL_BIT;
        en_SPI_clk <= '1';
        rst_SPI_clk <= '1';
        rst_count_data <= '0';
        data <= (others => '0');
      when output_mode =>
        CS <= '0';
        MOSI <= OUTPUT_MODE_BIT;
        en_SPI_clk <= '1';
        rst_SPI_clk <= '1';
        rst_count_data <= '0';
        data <= (others => '0');
      when null_bit =>
        CS <= '0';
        MOSI <= '0';
        en_SPI_clk <= '1';
        rst_SPI_clk <= '1';
        rst_count_data <= '0';
        data <= (others => '0');
      when read_data =>
        CS <= '0';
        MOSI <= '0';
        en_SPI_clk <= '1';
        rst_SPI_clk <= '1';
        rst_count_data <= '1';
        if done_read = '1' then
          data(bit_read) <= MISO;
        end if;
      when done =>
        CS <= '1';
        MOSI <= '0';
        en_SPI_clk <= '0';
        rst_SPI_clk <= '0';
        rst_count_data <= '0';
    end case;
  end process assignment_proc;
  
end arch_SPI_ADC;
