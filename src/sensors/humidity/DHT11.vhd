library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.DHT11_pack.all;

entity DHT11 is
  generic(CLK_PERIOD: positive := 10; -- ns
          HUMIDITY_BITS: positive := 8);
  port(reset_n: in std_logic;
       clk: in std_logic;
       enable: in std_logic;
       measure: in std_logic;
       data: inout std_logic;
       humidity: out std_logic_vector(HUMIDITY_BITS-1 downto 0));
end DHT11;

architecture arch_DHT11 of DHT11 is

  constant COUNTS_18MS: positive := 18000000/CLK_PERIOD;
  constant COUNTS_40US: positive := 40000/CLK_PERIOD;
  constant COUNTS_50US: positive := 50000/CLK_PERIOD;
  constant COUNTS_80US: positive := 80000/CLK_PERIOD; 
  constant COUNTS_70US: positive := 70000/CLK_PERIOD; 
  constant COUNTS_26US: positive := 26000/CLK_PERIOD;  
  constant COUNTS_TIMER: positive := 80000/CLK_PERIOD; 
  constant THRESHOLD: positive := 50000/CLK_PERIOD;

--  constant COUNTS_18MS: positive := 180/CLK_PERIOD;
--  constant COUNTS_40US: positive := 40/CLK_PERIOD;
--  constant COUNTS_50US: positive := 50/CLK_PERIOD;
--  constant COUNTS_80US: positive := 80/CLK_PERIOD; 
--  constant COUNTS_70US: positive := 70/CLK_PERIOD;
--  constant COUNTS_26US: positive := 30/CLK_PERIOD;    
--  constant COUNTS_TIMER: positive := 80/CLK_PERIOD; 
--  constant THRESHOLD: positive := 50/CLK_PERIOD;

  signal state_signal: DHT11_state_type := idle;
  signal next_state_signal: DHT11_state_type := idle;

  signal en_18ms: std_logic := '0';
  signal rst_18ms: std_logic :='0';
  signal done_18ms: std_logic := '0';
  signal en_timer: std_logic := '0';
  signal rst_timer: std_logic := '0';
  signal count_timer: natural range 0 to COUNTS_TIMER := 0;
  signal count_bits: natural range 0 to HUMIDITY_BITS := HUMIDITY_BITS;

  signal humidity_signal: std_logic_vector(HUMIDITY_BITS-1 downto 0) := (others => '0');

  component counter is
    generic(COUNTS:integer := 10;
            SHIFT:integer := 0);
    port(reset_n:in std_logic;
         clk:in std_logic;
         enable:in std_logic;
         q:out std_logic;
         count:out integer range 0 to COUNTS);
  end component;
begin

--  counts <= count_bits;
  humidity <= humidity_signal;

  counter_18ms: component counter
    generic map(COUNTS => COUNTS_18MS)
    port map(reset_n => rst_18ms,
             clk => clk,
             enable => en_18ms,
             q => done_18ms);

  counter_timer: component counter
    generic map(COUNTS => COUNTS_TIMER)
    port map(reset_n => rst_timer,
             clk => clk,
             enable => en_timer,
             count => count_timer);
  
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

  state_flow_proc: process(state_signal, done_18ms, data, count_bits, measure)
  begin
    case state_signal is
      when idle =>
        if measure = '1' then
          next_state_signal <= start;
        else
          next_state_signal <= idle;
        end if;        
      when start =>
        if done_18ms = '1' then
          next_state_signal <= release_bus;
        else
          next_state_signal <= start;
        end if;
      when release_bus =>
        if data = HIGH_VAL then
          next_state_signal <= wait_response;
        else
          next_state_signal <= release_bus;
        end if;
      when wait_response =>
        if data = '0' then
          next_state_signal <= ack;
        else
          next_state_signal <= wait_response;
        end if;
      when ack =>
        if data = HIGH_VAL then
          next_state_signal <= wait_transmission;
        else
          next_state_signal <= ack;
        end if;
      when wait_transmission =>
        if data = '0' then
          next_state_signal <= begin_bit;
        else
          next_state_signal <= wait_transmission;
        end if;
      when begin_bit =>
        if data = HIGH_VAL then
          next_state_signal <= timer;
        else
          next_state_signal <= begin_bit;
        end if;
      when timer =>
        if data = '0' then
          next_state_signal <= decode;
        else
          next_state_signal <= timer;
        end if;
      when decode =>
        if count_bits = 1 then
          next_state_signal <= idle;
        else
          next_state_signal <= begin_bit;
        end if;
    end case;
  end process state_flow_proc;

  assignment_proc: process(state_signal, data)
  begin
    case state_signal is
      when idle =>
        data <= OPEN_DRAIN;
        rst_18ms <= '0';
        en_18ms <= '0';
        rst_timer <= '0';
        en_timer <= '0';
      when start =>
        data <= '0';
        rst_18ms <= '1';
        en_18ms <= '1';
        rst_timer <= '0';
        en_timer <= '0';
      when release_bus =>
        data <= OPEN_DRAIN;
        rst_18ms <= '0';
        en_18ms <= '0';
        rst_timer <= '0';
        en_timer <= '0';
      when wait_response =>
        data <= OPEN_DRAIN;
        rst_18ms <= '0';
        en_18ms <= '0';
        rst_timer <= '0';
        en_timer <= '0';
      when ack =>
        data <= OPEN_DRAIN;
        rst_18ms <= '0';
        en_18ms <= '0';
        rst_timer <= '0';
        en_timer <= '0';
      when wait_transmission =>
        data <= OPEN_DRAIN;
        rst_18ms <= '0';
        en_18ms <= '0';
        rst_timer <= '0';
        en_timer <= '0';
      when begin_bit =>
        data <= OPEN_DRAIN;
        rst_18ms <= '0';
        en_18ms <= '0';
        rst_timer <= '0';
        en_timer <= '0';
      when timer =>
        data <= OPEN_DRAIN;
        rst_18ms <= '0';
        en_18ms <= '0';
        rst_timer <= '1';
        en_timer <= '1';
      when decode =>
        data <= OPEN_DRAIN;
        rst_18ms <= '0';
        en_18ms <= '0';
        rst_timer <= '1';
        en_timer <= '1';
    end case;
  end process assignment_proc;

  counter_bits: process(clk)
  begin
    if rising_edge(clk) then
      if reset_n = '0' then
        humidity_signal <= (others => '0');
        count_bits <= HUMIDITY_BITS;
      elsif state_signal = start then
        count_bits <= HUMIDITY_BITS;
      elsif enable = '1' and state_signal = decode then
        if count_bits = 0 then
          count_bits <= HUMIDITY_BITS;
        else
          count_bits <= count_bits - 1;
          if count_timer < THRESHOLD then
            humidity_signal(count_bits-1) <= '0';
          else
            humidity_signal(count_bits-1) <= '1';
          end if;
        end if;
      end if;
    end if;
  end process counter_bits;

end arch_DHT11;
