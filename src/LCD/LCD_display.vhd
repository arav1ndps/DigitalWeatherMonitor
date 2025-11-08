library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.LCD_pack.all;

entity LCD_display is
--  generic(CLK_PERIOD: positive := 10); -- ns -- comment out for testing
  port(reset_n: in std_logic;
       clk: in std_logic;
       enable: in std_logic;
       update: in std_logic;
       -- data: in char_array; -- comment out for testing
       E: out std_logic;
       RS: out std_logic;
       R_W: out std_logic;
       DB: out std_logic_vector(CHAR_NUM-1 downto 0));
--       state_out: out std_logic_vector(7 downto 0);
--       done_16ms_out: out std_logic;
--       done_5ms_out: out std_logic;
--       done_func_out: out std_logic;
--       done_100us_out: out std_logic;
--       done_data_out: out std_logic);
end entity;

architecture arch_LCD_display of LCD_display is
  
  signal state_signal: LCD_state_type := idle;
  signal next_state_signal: LCD_state_type := idle;

--  signal counts: natural := 0;

  signal en_16ms: std_logic := '0';
  signal rst_16ms: std_logic := '0';
  signal done_16ms: std_logic := '0';
  signal en_5ms: std_logic := '0';
  signal rst_5ms: std_logic := '0';
  signal done_5ms: std_logic := '0';
  signal en_100us: std_logic := '0';
  signal rst_100us: std_logic := '0';
  signal done_100us: std_logic := '0';
  signal rst_func: std_logic := '0';
  signal done_func: std_logic := '0';
  signal rst_data: std_logic := '0';
  signal done_data: std_logic := '0';
  signal rst_en: std_logic := '0';
  signal en_en: std_logic := '0';
  
  signal char_pos : natural range 0 to COUNTS_DATA := 0;

  component counter is
    generic(COUNTS:integer := 10;
            SHIFT:integer := 0);
    port(reset_n:in std_logic;
         clk:in std_logic;
         enable:in std_logic;
         q:out std_logic;
         count:out integer range 0 to COUNTS);
  end component;  

  component display_enable is
  generic(CLK_PERIOD: positive := 10;  -- ns
          EN_PERIOD: positive := 4000; -- ns
          DELAY: positive := 1000; -- ns
          HIGH_TIME: natural := 1000); -- ns
  port(clk: in std_logic;
       reset_n: in std_logic;
       enable_in: in std_logic;
       enable_out: out std_logic);
  end component;
begin

--  done_16ms_out <= done_16ms;
--  done_5ms_out <= done_5ms;
--  done_func_out <= done_func;
--  done_100us_out <= done_100us;
--  done_data_out <= done_data;

  timer_16ms: component counter
    generic map(COUNTS => COUNTS_16MS)
    port map(reset_n => rst_16ms,
             clk => clk,
             enable => en_16ms,
            -- count => counts,
             q => done_16ms);

  timer_5ms: component counter
    generic map(COUNTS => COUNTS_5MS)
    port map(reset_n => rst_5ms,
             clk => clk,
             enable => en_5ms,
             q => done_5ms);

  timer_100us: component counter
    generic map(COUNTS => COUNTS_100US)
    port map(reset_n => rst_100us,
             clk => clk,
             enable => en_100us,
             q => done_100us);
             
  func_count: component counter
    generic map(COUNTS => COUNTS_FUNC)
    port map(reset_n => rst_func,
             clk => clk,
             enable => done_5ms,
             q => done_func);
             
  data_count: component counter
    generic map(COUNTS => COUNTS_DATA)
    port map(reset_n => rst_data,
             clk => clk,
             enable => done_100us,
             count => char_pos,
             q => done_data);

  enable_gen: component display_enable
    generic map(CLK_PERIOD => CLK_PERIOD,
                EN_PERIOD => EN_PERIOD,
                DELAY => DELAY,
                HIGH_TIME => HIGH_TIME)
    port map(clk => clk,
             reset_n => rst_en,
             enable_in => en_en,
             enable_out => E);

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

  state_flow_proc: process(state_signal, next_state_signal, done_16ms, done_func, done_100us, done_data, update)
  begin
    case state_signal is
      when idle =>
        if done_16ms = '1' then
          next_state_signal <= func_set;
        else
          next_state_signal <= next_state_signal;
        end if;
      when func_set =>
        if done_func = '1' then
          next_state_signal <= disp_off;
        else
          next_state_signal <= next_state_signal;
        end if;
      when disp_off =>
        if done_100us = '1' then
          next_state_signal <= disp_clear;
        else
          next_state_signal <= next_state_signal;
        end if;
      when disp_clear =>
        if done_16ms = '1' then
          next_state_signal <= entry_mode;
        else
          next_state_signal <= next_state_signal;
        end if;
      when entry_mode =>
        if done_100us = '1' then
          next_state_signal <= disp_on;
        else
          next_state_signal <= next_state_signal;
        end if;
      when disp_on =>
        if done_100us = '1' then
          next_state_signal <= data_out;
        else
          next_state_signal <= next_state_signal;
        end if;
      when data_out =>
        if done_data = '1' then
          next_state_signal <= disp_update;
        else
          next_state_signal <= next_state_signal;
        end if;
      when disp_update =>
        if update = '1' then
          next_state_signal <= disp_off;
        else
          next_state_signal <= next_state_signal;
        end if;
    end case;
  end process state_flow_proc;

  assignment_proc: process(state_signal, char_pos, done_5ms, done_100us, done_16ms)
  begin
    case state_signal is
      when idle =>
        en_16ms <= '1';
        rst_16ms <= '1';
        en_5ms <= '0';
        rst_5ms <= '0';
        en_100us <= '0';
        rst_100us <= '0';
        rst_func <= '0';
        rst_data <= '0';
        rst_en <= '0';
        en_en <= '0';
        RS <= '0';
        R_W <= '0';
        DB <= (others => '0');
--        state_out <= (others => '0');
--        state_out(0) <= '1';
      when func_set =>
        en_16ms <= '0';
        rst_16ms <= '0';
        en_5ms <= '1';
        rst_5ms <= '1';
        en_100us <= '0';
        rst_100us <= '0';
        rst_func <= '1';
        rst_data <= '0';
        rst_en <= not done_5ms;
        en_en <= '1';
        RS <= '0';
        R_W <= '0';
        DB <= FUNC_SET_INST;
--        state_out <= (others => '0');
--        state_out(1) <= '1';
      when disp_off =>
        en_16ms <= '0';
        rst_16ms <= '0';
        en_5ms <= '0';
        rst_5ms <= '0';
        en_100us <= '1';
        rst_100us <= '1';
        rst_func <= '0';
        rst_data <= '0';
        rst_en <= not done_100us;
        en_en <= '1';
        RS <= '0';
        R_W <= '0';
        DB <= DISP_OFF_INST;
--        state_out <= (others => '0');
--        state_out(2) <= '1';
      when disp_clear =>
        en_16ms <= '1';
        rst_16ms <= '1';
        en_5ms <= '0';
        rst_5ms <= '0';
        en_100us <= '0';
        rst_100us <= '0';
        rst_func <= '0';
        rst_data <= '0';
        rst_en <= not done_16ms;
        en_en <= '1';
        RS <= '0';
        R_W <= '0';
        DB <= DISP_CLEAR_INST;
--        state_out <= (others => '0');
--        state_out(3) <= '1';
      when entry_mode =>
        en_16ms <= '0';
        rst_16ms <= '0';
        en_5ms <= '0';
        rst_5ms <= '0';
        en_100us <= '1';
        rst_100us <= '1';
        rst_func <= '0';
        rst_data <= '0';
        rst_en <= not done_100us;
        en_en <= '1';
        RS <= '0';
        R_W <= '0';
        DB <= ENTRY_MODE_INST;
--        state_out <= (others => '0');
--        state_out(4) <= '1';
      when disp_on =>
        en_16ms <= '0';
        rst_16ms <= '0';
        en_5ms <= '0';
        rst_5ms <= '0';
        en_100us <= '1';
        rst_100us <= '1';
        rst_func <= '0';
        rst_data <= '0';
        rst_en <= not done_100us;
        en_en <= '1';
        RS <= '0';
        R_W <= '0';
        DB <= DISP_ON_INST;
--        state_out <= (others => '0');
--        state_out(5) <= '1';
      when data_out =>
        en_16ms <= '0';
        rst_16ms <= '0';
        en_5ms <= '0';
        rst_5ms <= '0';
        en_100us <= '1';
        rst_100us <= '1';
        rst_func <= '0';
        rst_data <= '1';
        rst_en <= not done_100us;
        en_en <= '1';
        RS <= '1';
        R_W <= '0';
        DB <= DATA(char_pos);
--        state_out <= (others => '0');
--        state_out(6) <= '1';
      when disp_update =>
        en_16ms <= '0';
        rst_16ms <= '0';
        en_5ms <= '0';
        rst_5ms <= '0';
        en_100us <= '0';
        rst_100us <= '0';
        rst_func <= '0';
        rst_data <= '0';
        rst_en <= '0';
        en_en <= '0';
        RS <= '0';
        R_W <= '0';
        DB <= (others => '0');
--        state_out <= (others => '0');
--        state_out(7) <= '1';
    end case;
  end process assignment_proc;
end arch_LCD_display;
