library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.UART_pack.all;

entity UART_tx is
  generic(CLK_PERIOD: positive := 10; -- ns
          BAUDRATE: positive := 9600); -- bit/s
  port(reset_n: in std_logic;
       clk: in std_logic;
       enable: in std_logic;
       start: in std_logic;
       data_in: in str;
       tx: out std_logic);
end UART_tx;

architecture arch_UART_tx of UART_tx is
--  constant CLK_PERIOD: positive := 10; --ns
--  constant BAUDRATE: positive := 9600;
  constant COUNTS_1S: positive := 1000000000/CLK_PERIOD;
  constant COUNTS_BAUD: positive := COUNTS_1S/BAUDRATE;
--  constant COUNTS_1S: positive := 50000/CLK_PERIOD;
--  constant COUNTS_BAUD: positive := 10; -- test 

  type UART_state_type is (idle, start_bit, write_data, stop_bit0, stop_bit1);

  signal state_signal: UART_state_type;
  signal next_state_signal: UART_state_type; 

  signal en_clk: std_logic;
  signal rst_clk: std_logic;
  signal done_clk: std_logic;
  signal rst_bit: std_logic;
  signal done_bit: std_logic;
  signal rst_char: std_logic;

  signal counts_bit: natural range 0 to CHAR_LEN;
  signal counts_char: natural range 0 to STRING_LEN+1;
  signal counts_control: natural range 0 to COUNTS_1S;
  
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
  UART_clk: component counter
    generic map(COUNTS => COUNTS_BAUD)
    port map(reset_n => rst_clk,
             clk => clk,
             enable => en_clk,
             q => done_clk);

  counter_bit: component counter
    generic map(COUNTS => CHAR_LEN)
    port map(reset_n => rst_bit,
             clk => clk,
             enable => done_clk,
             q => done_bit,
             count => counts_bit);

  counter_char: component counter
    generic map(COUNTS => STRING_LEN+1)
    port map(reset_n => rst_char,
             clk => clk,
             enable => done_bit,
             count => counts_char);

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

  state_flow_proc: process (state_signal, start, done_clk, counts_char)
  begin
    case state_signal is
      when idle =>
        if start = '1' then
          next_state_signal <= start_bit;
        else
          next_state_signal <= idle;
        end if;
      when start_bit =>
        if done_clk = '1' then
          next_state_signal <= write_data;
        else
          next_state_signal <= start_bit;
        end if;
      when write_data =>
        if counts_bit = CHAR_LEN-1 and done_clk = '1' then
          next_state_signal <= stop_bit0;
        else
          next_state_signal <= write_data;
        end if;
      when stop_bit0 =>
        if done_clk = '1' then
          next_state_signal <= stop_bit1;
        else
          next_state_signal <= stop_bit0;
        end if;
      when stop_bit1 =>
        if done_clk = '1' then
          if counts_char = STRING_LEN then
            next_state_signal <= idle;
          else 
            next_state_signal <= start_bit;
          end if;
        else
          next_state_signal <= stop_bit1;
        end if;
    end case;
  end process state_flow_proc; 

  assignment_proc: process (state_signal, counts_char, counts_bit)
  begin
    case state_signal is
      when idle =>
        tx <= '1';
        en_clk <= '0';
        rst_clk <= '0';
        rst_bit <= '0';
        rst_char <= '0';
      when start_bit =>
        tx <= '0';
        en_clk <= '1';
        rst_clk <= '1';
        rst_bit <= '0';
        rst_char <= '1';
      when write_data =>
        tx <= data_in(counts_char)(counts_bit);
        en_clk <= '1';
        rst_clk <= '1';
        rst_bit <= '1';
        rst_char <= '1';
      when stop_bit0 =>
        tx <= '1';
        en_clk <= '1';
        rst_clk <= '1';
        rst_bit <= '0';
        rst_char <= '1';
      when stop_bit1 =>
        tx <= '1';
        en_clk <= '1';
        rst_clk <= '1';
        rst_bit <= '0';
        rst_char <= '1';
    end case;
  end process assignment_proc;
end arch_UART_tx;
