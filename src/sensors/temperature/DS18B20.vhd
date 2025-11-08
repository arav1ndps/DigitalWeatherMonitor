library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.DS18B20_pack.all;

entity DS18B20 is
  generic(CLK_PERIOD: positive := 10; -- ns
          TEMP_LEN: positive := 13);
  port(reset_n: in std_logic;
       clk: in std_logic;
       enable: in std_logic;
       data: inout std_logic;
       temperature: out std_logic_vector(TEMP_LEN-1 downto 0));
end DS18B20;


architecture arch_DS18B20 of DS18B20 is
  constant COUNTS_1S: positive := 1000000000/CLK_PERIOD; -- ns/ns
  constant COUNTS_750MS: positive := 750000000/CLK_PERIOD;
  constant COUNTS_480US: positive := 480000/CLK_PERIOD;
  constant COUNTS_1US: positive := 1000/CLK_PERIOD;
  constant COUNTS_10US: positive := 10000/CLK_PERIOD;
  constant COUNTS_60US: positive := 60000/CLK_PERIOD;

--  constant COUNTS_1S: positive := 10000000/CLK_PERIOD; -- ns/ns
--  constant COUNTS_750MS: positive := 7500000/CLK_PERIOD;
--  constant COUNTS_480US: positive := 4800/CLK_PERIOD;
--  constant COUNTS_1US: positive := 40/CLK_PERIOD;
--  constant COUNTS_10US: positive := 100/CLK_PERIOD;
--  constant COUNTS_60US: positive := 600/CLK_PERIOD;

  signal state_signal: state_type;
  signal next_state_signal: state_type;

  signal temperature_signal: std_logic_vector(TEMP_LEN-1 downto 0);

  signal rst_480us: std_logic;
  signal en_480us: std_logic;
  signal done_480us: std_logic;
  signal rst_1s: std_logic;
  signal en_1s: std_logic;
  signal done_1s: std_logic;
  signal rst_750ms: std_logic;
  signal en_750ms: std_logic;
  signal done_750ms: std_logic;
  signal rst_1us: std_logic;
  signal en_1us: std_logic;
  signal done_1us: std_logic;
  signal en_60us: std_logic;
  signal rst_60us: std_logic;
  signal done_60us: std_logic;
  signal rst_bit: std_logic;
  signal done_bit: std_logic;
  signal rst_inst: std_logic;
  signal rst_10us: std_logic;
  signal en_10us: std_logic;
  signal done_10us: std_logic;
  signal rst_data: std_logic;
  
  signal counts_inst: natural range 0 to INST_NUM;
  signal counts_bit: natural range 0 to INST_LEN;
  signal counts_data: natural range 0 to TEMP_LEN;

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
  timer_1s: component counter
    generic map(COUNTS => COUNTS_1S)
    port map(reset_n => rst_1s,
             clk => clk,
             enable => en_1s,
             q => done_1s);
             
  timer_750ms: component counter
    generic map(COUNTS => COUNTS_750MS)
    port map(reset_n => rst_750ms,
             clk => clk,
             enable => en_750ms,
             q => done_750ms);  

  timer_480us: component counter
    generic map(COUNTS => COUNTS_480US)
    port map(reset_n => rst_480us,
             clk => clk,
             enable => en_480us,
             q => done_480us);

  timer_1us: component counter
    generic map(COUNTS => COUNTS_1US)
    port map(reset_n => rst_1us,
             clk => clk,
             enable => en_1us,
             q => done_1us);

  timer_60us: component counter
    generic map(COUNTS => COUNTS_60US)
    port map(reset_n => rst_60us,
             clk => clk,
             enable => en_60us,
             q => done_60us);

  timer_10us: component counter
    generic map(COUNTS => COUNTS_10US)
    port map(reset_n => rst_10us,
             clk => clk,
             enable => en_10us,
             q => done_10us);

  counter_bit: component counter
    generic map(COUNTS => INST_LEN)
    port map(reset_n => rst_bit,
             clk => clk,
             enable => done_60us,
             count => counts_bit,
             q => done_bit);

  counter_inst: component counter
    generic map(COUNTS => INST_NUM)
    port map(reset_n => rst_inst,
             clk => clk,
             enable => done_bit,
             count => counts_inst);

  counter_data: component counter
    generic map(COUNTS => TEMP_LEN)
    port map(reset_n => rst_data,
             clk => clk,
             enable => done_60us,
             count => counts_data);

  state_trans_proc: process(clk)
  begin
    if rising_edge(clk) then
      if reset_n = '0' then
        state_signal <= idle;
      elsif enable = '1' then
        state_signal <= next_state_signal;
      end if;
    end if;
  end process state_trans_proc;

  state_flow_proc: process(state_signal, done_480us, done_1us, done_60us, done_1s, data, counts_inst, done_bit, done_10us, counts_data, done_750ms, counts_bit)
  begin
    case state_signal is
      when idle =>
        next_state_signal <= masterTx;
      when masterTx =>
        if done_480us = '1' then
          next_state_signal <= presence;
        else
          next_state_signal <= masterTx;
        end if;
      when presence =>
        if data = '0' then
          next_state_signal <= masterRx;
        else
          next_state_signal <= presence;
        end if;
      when masterRx =>
        if done_480us = '1' then
          next_state_signal <= recTime;
        else
          next_state_signal <= masterRx;
        end if;
      when recTime =>
        if done_1us = '1' then
          next_state_signal <= startTime;
        else
          next_state_signal <= recTime;
        end if;
      when startTime =>
        if done_1us = '1' then
          next_state_signal <= writeTime;
        else
          next_state_signal <= startTime;
        end if;
      when writeTime =>
        if done_60us = '1' then
          if counts_inst = INST_NUM-1 and counts_bit = INST_LEN-1 then
            next_state_signal <= recTimeRead;
          elsif counts_inst mod CONS_INST = 1 and counts_bit = INST_LEN-1 then
            next_state_signal <= waitT;
          else
            next_state_signal <= recTime;
          end if;
        else
          next_state_signal <= writeTime;
        end if;
      when waitT =>
        if done_750ms = '1' then
          next_state_signal <= masterTx;
        else
          next_state_signal <= waitT;
        end if;
      when recTimeRead =>
        if done_1us = '1' then 
          next_state_signal <= startTimeRead;
        else
          next_state_signal <= recTimeRead;
        end if;
      when startTimeRead =>
        if done_1us = '1' then 
          next_state_signal <= waitRC;
        else
          next_state_signal <= startTimeRead;
        end if;
      when waitRC =>
        if done_10us = '1' then 
          next_state_signal <= sample;
        else
          next_state_signal <= waitRC;
        end if;
      when sample =>
        next_state_signal <= readTime;
      when readTime =>
        if done_60us = '1' then 
          if counts_data = TEMP_LEN-1 then
            next_state_signal <= wait1s;
          else
            next_state_signal <= recTimeRead;
          end if;  
        else
          next_state_signal <= readTime;
        end if;
      when wait1s =>
        if done_1s = '1' then 
          next_state_signal <= idle;
        else
          next_state_signal <= wait1s;
        end if;
    end case;
  end process state_flow_proc;

  assignment_proc: process(state_signal, data, counts_data)
  begin
    case state_signal is
      when idle =>
        data <= 'Z';
        en_1s <= '0';
        rst_1s <= '0';
        en_750ms <= '0';
        rst_750ms <= '0';
        en_480us <= '0';
        rst_480us <= '0';
        en_1us <= '0';
        rst_1us <= '0';
        en_60us <= '0';
        rst_60us <= '0';
        rst_10us <= '0';
        en_10us <= '0';
        rst_bit <= '0';
        rst_inst <= '0';
        rst_data <= '0';
      when masterTx =>
        data <= '0';
        en_1s <= '1';
        rst_1s <= '1';
        en_750ms <= '0';
        rst_750ms <= '0';
        en_480us <= '1';
        rst_480us <= '1';
        en_1us <= '0';
        rst_1us <= '0';
        en_60us <= '0';
        rst_60us <= '0';
        rst_10us <= '0';
        en_10us <= '0';
        rst_bit <= '1';
        rst_inst <= '1';
        rst_data <= '0';
      when presence =>
        data <= 'Z';
        en_1s <= '1';
        rst_1s <= '1';
        en_750ms <= '0';
        rst_750ms <= '0';
        en_480us <= '1';
        rst_480us <= '1';
        en_1us <= '0';
        rst_1us <= '0';
        en_60us <= '0';
        rst_60us <= '0';
        rst_10us <= '0';
        en_10us <= '0';
        rst_bit <= '1';
        rst_inst <= '1';
        rst_data <= '0';
      when masterRx =>
        data <= 'Z';
        en_1s <= '1';
        rst_1s <= '1';
        en_750ms <= '0';
        rst_750ms <= '0';
        en_480us <= '1';
        rst_480us <= '1';
        en_1us <= '0';
        rst_1us <= '0';
        en_60us <= '0';
        rst_60us <= '0';
        rst_10us <= '0';
        en_10us <= '0';
        rst_bit <= '1';
        rst_inst <= '1';
        rst_data <= '0';
      when recTime =>
        data <= 'Z';
        en_1s <= '1';
        rst_1s <= '1';
        en_750ms <= '0';
        rst_750ms <= '0';
        en_480us <= '0';
        rst_480us <= '0';
        en_1us <= '1';
        rst_1us <= '1';
        en_60us <= '0';
        rst_60us <= '0';
        rst_10us <= '0';
        en_10us <= '0';
        rst_bit <= '1';
        rst_inst <= '1';
        rst_data <= '0';
      when startTime =>
        data <= '0';
        en_1s <= '1';
        rst_1s <= '1';
        en_750ms <= '0';
        rst_750ms <= '0';
        en_480us <= '0';
        rst_480us <= '0';
        en_1us <= '1';
        rst_1us <= '1';
        en_60us <= '1';
        rst_60us <= '1';
        rst_10us <= '0';
        en_10us <= '0';
        rst_bit <= '1';
        rst_inst <= '1';
        rst_data <= '0';
      when writeTime =>
        data <= INSTRUCTIONS(counts_inst)(counts_bit); -- LSB first
        en_1s <= '1';
        rst_1s <= '1';
        en_750ms <= '0';
        rst_750ms <= '0';
        en_480us <= '0';
        rst_480us <= '0';
        en_1us <= '0';
        rst_1us <= '0';
        en_60us <= '1';
        rst_60us <= '1';
        rst_10us <= '0';
        en_10us <= '0';
        rst_bit <= '1';
        rst_inst <= '1';
        rst_data <= '0';
      when waitT =>
        data <= 'Z';
        en_1s <= '1';
        rst_1s <= '1';
        en_750ms <= '1';
        rst_750ms <= '1';
        en_480us <= '0';
        rst_480us <= '0';
        en_1us <= '0';
        rst_1us <= '0';
        en_60us <= '0';
        rst_60us <= '0';
        rst_10us <= '0';
        en_10us <= '0';
        rst_bit <= '1';
        rst_inst <= '1';
        rst_data <= '0';
      when recTimeRead =>
        data <= 'Z';
        en_1s <= '1';
        rst_1s <= '1';
        en_750ms <= '0';
        rst_750ms <= '0';
        en_480us <= '0';
        rst_480us <= '0';
        en_1us <= '1';
        rst_1us <= '1';
        en_60us <= '0';
        rst_60us <= '0';
        rst_10us <= '0';
        en_10us <= '0';
        rst_bit <= '0';
        rst_inst <= '0';
        rst_data <= '1';       
      when startTimeRead =>
        data <= '0';
        en_1s <= '1';
        rst_1s <= '1';
        en_750ms <= '0';
        rst_750ms <= '0';
        en_480us <= '0';
        rst_480us <= '0';
        en_1us <= '1';
        rst_1us <= '1';
        en_60us <= '1';
        rst_60us <= '1';
        rst_10us <= '0';
        en_10us <= '0';
        rst_bit <= '0';
        rst_inst <= '0';
        rst_data <= '1';  
      when waitRC =>
        data <= 'Z';
        en_1s <= '1';
        rst_1s <= '1';
        en_750ms <= '0';
        rst_750ms <= '0';
        en_480us <= '0';
        rst_480us <= '0';
        en_1us <= '0';
        rst_1us <= '0';
        en_60us <= '1';
        rst_60us <= '1';
        rst_10us <= '1';
        en_10us <= '1';
        rst_bit <= '0';
        rst_inst <= '0';
        rst_data <= '1'; 
      when sample =>
        data <= 'Z';
        temperature_signal(counts_data) <= data;
        en_1s <= '1';
        rst_1s <= '1';
        en_750ms <= '0';
        rst_750ms <= '0';
        en_480us <= '0';
        rst_480us <= '0';
        en_1us <= '0';
        rst_1us <= '0';
        en_60us <= '1';
        rst_60us <= '1';
        rst_10us <= '0';
        en_10us <= '0';
        rst_bit <= '0';
        rst_inst <= '0';
        rst_data <= '1'; 
      when readTime =>
        data <= 'Z';
        en_1s <= '1';
        rst_1s <= '1';
        en_750ms <= '0';
        rst_750ms <= '0';
        en_480us <= '0';
        rst_480us <= '0';
        en_1us <= '0';
        rst_1us <= '0';
        en_60us <= '1';
        rst_60us <= '1';
        rst_10us <= '0';
        en_10us <= '0';
        rst_bit <= '0';
        rst_inst <= '0';
        rst_data <= '1';
      when wait1s =>
        data <= 'Z';
        temperature <= temperature_signal;
        en_1s <= '1';
        rst_1s <= '1';
        en_750ms <= '0';
        rst_750ms <= '0';
        en_480us <= '0';
        rst_480us <= '0';
        en_1us <= '0';
        rst_1us <= '0';
        en_60us <= '0';
        rst_60us <= '0';
        rst_10us <= '0';
        en_10us <= '0';
        rst_bit <= '0';
        rst_inst <= '0';
        rst_data <= '0';
    end case;   
  end process assignment_proc;

end arch_DS18B20;
