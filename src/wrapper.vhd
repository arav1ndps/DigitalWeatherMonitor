library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.segment_pack.all;
use WORK.UART_pack.all;

entity wrapper is
  port(reset_n: in std_logic;
       clk: in std_logic;
       enable: in std_logic;
       data_temp: inout std_logic;
       data_hum: inout std_logic;
       disp_anodes: out std_logic_vector(7 downto 0);
       disp_cathodes: out std_logic_vector(7 downto 0);
       CS: out std_logic;
       SPI_CLK: out std_logic;
       MISO: in std_logic;
       MOSI: out std_logic;
       up_but: in std_logic;
       down_but: in std_logic;
       plus_but: in std_logic;
       minus_but: std_logic;
       tx: out std_logic;
       speaker_out: out std_logic;
--       leds_temp: out std_logic_vector(12 downto 0);
--       leds_hum: out std_logic_vector(7 downto 0);
--       leds_air_q: out std_logic_vector(11 downto 0);
       leds_option: out std_logic_vector(3 downto 0));
end wrapper;

architecture arch_wrapper of wrapper is
  component counter is
    generic(COUNTS:integer := 10;
            SHIFT:integer := 0);
    port(reset_n:in std_logic;
         clk:in std_logic;
         enable:in std_logic;
         q:out std_logic;
         count:out integer range 0 to COUNTS);
  end component;

  component DS18B20 is
    generic(CLK_PERIOD: positive := 10; -- ns
            TEMP_LEN: positive := 13);
    port(reset_n: in std_logic;
         clk: in std_logic;
         enable: in std_logic;
         data: inout std_logic;
         temperature: out std_logic_vector(TEMP_LEN-1 downto 0));
  end component;
  
  component DHT11_wrapper is
    generic(CLK_PERIOD: positive := 10; -- ns
            HUMIDITY_BITS: positive := 8);
    port(reset_n: in std_logic;
         clk: in std_logic;
         enable: in std_logic;
         humidity: out std_logic_vector(HUMIDITY_BITS-1 downto 0);
         data: inout std_logic);
  end component;
  
  component SPI_ADC is
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
  end component; 
  
  component segment_display is
    generic(FPS: natural range 30 to 100000 := 60;
            CLK_PERIOD: natural:= 10; -- ns
            DIGITS: positive range 1 to 8 := 8);
    port(reset_n: in std_logic;
         clk: in std_logic;
         enable: in std_logic;
         update: in std_logic;
         digit_vals_in: in digit_array;
         CA: out std_logic_vector(7 downto 0);
         AN: out std_logic_vector(7 downto 0));
  end component;
  
  component UART_tx is
    generic(CLK_PERIOD: positive := 10; -- ns
            BAUDRATE: positive := 9600); -- bit/s
    port(reset_n: in std_logic;
         clk: in std_logic;
         enable: in std_logic;
         start: in std_logic;
         data_in: in str;
         tx: out std_logic);
  end component;
  
  component alarm is
    Generic (CLK_PERIOD: positive := 10;
             FREQ1: positive := 400; -- Hz
             FREQ2: positive := 1200); -- Hz
    Port ( reset_n : in STD_LOGIC;
           clk : in STD_LOGIC;
           enable : in STD_LOGIC;
           speaker_out : out STD_LOGIC);
  end component;
  
  constant COUNTS_1S: positive := 100000000;
--  constant COUNTS_BUT: positive := 20000000;
  constant OPTIONS: positive := 4;
  constant MAX_THR: positive := 500;
  
  constant FACTOR_TEMP: positive := 16;
  constant FACTOR_HUM: integer := 4;
  constant OFFSET_HUM: integer := 20;
  constant FACTOR_AIR_Q: integer := 4;
  constant OFFSET_AIR_Q: integer := 20;
  
  signal bin_temp: std_logic_vector(12 downto 0);
  signal signal_temp: integer;
  
  signal bin_hum: std_logic_vector(7 downto 0);
  signal signal_hum: integer;
  
  signal bin_air_q: std_logic_vector(11 downto 0);
  signal signal_air_q: integer;
 
  signal seg_temp: digit_array;
  signal seg_hum: digit_array;
  signal seg_air_q: digit_array;
  signal seg_signal: digit_array;
  signal seg_alarm: digit_array;
  
  signal done_1s: std_logic; 
  signal option: integer;
  
  signal val_up: std_logic;
  signal old_val_up: std_logic;
  signal val_down: std_logic;
  signal old_val_down: std_logic;
  
  signal val_plus: std_logic;
  signal old_val_plus: std_logic;
  signal val_minus: std_logic;
  signal old_val_minus: std_logic;
  
  signal UART_string: str;
  
  signal alarm_signal: std_logic;
  signal alarm_thr: integer;
  
begin
  counter_1s: component counter 
    generic map(COUNTS => COUNTS_1S)
    port map(reset_n => reset_n,
             clk => clk,
             enable => enable,
             q => done_1s);          

  sensor_temperature: component DS18B20
    port map(reset_n => reset_n,
             clk => clk,
             enable => enable,
             data => data_temp,
             temperature => bin_temp);
             
  sensor_humdity: component DHT11_wrapper
    port map(reset_n => reset_n,
             clk => clk,
             enable => enable,
             humidity => bin_hum,
             data => data_hum); 
             
  sensor_air_q: component SPI_ADC
    port map(reset_n => reset_n,
             clk => clk,
             enable => enable,
             sample => done_1s,
             CS => CS,
             SPI_CLK => SPI_CLK,
             MOSI => MOSI,
             MISO => MISO,
             data => bin_air_q);
   
  display_7_seg: component segment_display
    port map(reset_n => reset_n,
             clk => clk,
             enable => enable,
             update => done_1s,
             digit_vals_in => seg_signal,
             CA => disp_cathodes,
             AN => disp_anodes);
             
  UART_transmitter: component UART_tx
    port map(reset_n => reset_n,
             clk => clk,
             enable => enable,
             start => done_1s,
             data_in => UART_string,
             tx => tx);
             
  alarm_inst: component alarm
    port map(reset_n => reset_n,
             clk => clk,
             enable => alarm_signal,
             speaker_out => speaker_out);
             
--  leds_temp <= bin_temp;
--  leds_hum <= bin_hum;
--  leds_air_q <= bin_air_q;

  conv_proc_temp: process(clk)
  begin
    if rising_edge(clk) then
      if reset_n = '0' then
        seg_temp <= (18,18,18,18,18,18,18,18); -- Blank space
      elsif enable = '1' then
        signal_temp <= to_integer(signed(bin_temp))/FACTOR_TEMP;
        seg_temp(0) <= 12; -- C
        if signal_temp >= 0 then
          seg_temp(4) <= signal_temp/100;
          seg_temp(3) <= (signal_temp mod 100)/10;
          seg_temp(2) <= signal_temp mod 10;
        else 
          seg_temp(4) <= 16; -- -
          seg_temp(3) <= ((0-signal_temp) mod 100)/10;
          seg_temp(2) <= (0-signal_temp) mod 10;
        end if;
      else
        seg_temp <= (18,18,18,18,18,18,18,18); -- Blank space
      end if;
    end if;
  end process conv_proc_temp;
  
  conv_proc_hum: process(clk)
  begin
    if rising_edge(clk) then
      if reset_n = '0' then
        seg_hum <= (18,18,18,18,18,18,18,18); -- Blank space
      elsif enable = '1' then
        signal_hum <= to_integer(unsigned(bin_hum))/FACTOR_HUM + OFFSET_HUM;
        seg_hum(0) <= 19; -- H 
        seg_hum(4) <= signal_hum /100;
        seg_hum(3) <= (signal_hum mod 100)/10;
        seg_hum(2) <= signal_hum mod 10;
      else
        seg_hum <= (18,18,18,18,18,18,18,18); -- Blank space
      end if;
    end if;
  end process conv_proc_hum;
  
  conv_proc_air_q: process(clk)
  begin
    if rising_edge(clk) then
      if reset_n = '0' then
        seg_air_q <= (18,18,18,18,18,18,18,18); -- Blank space
      elsif enable = '1' then
        signal_air_q <= to_integer(unsigned(bin_air_q))/FACTOR_AIR_Q;
        seg_air_q(0) <= 20; -- P 
        seg_air_q(4) <= signal_air_q /100;
        seg_air_q(3) <=(signal_air_q mod 100)/10;
        seg_air_q(2) <= signal_air_q mod 10;
      else
        seg_air_q <= (18,18,18,18,18,18,18,18); -- Blank space
      end if;
    end if;
  end process conv_proc_air_q;  
  
  conv_proc_alarm_thr: process(clk)
  begin
    if rising_edge(clk) then
      if reset_n = '0' then
        seg_alarm <= (18,18,18,18,18,18,18,18); -- Blank space
      elsif enable = '1' then
        seg_alarm(0) <= 10; -- A
        seg_alarm(4) <= alarm_thr /100;
        seg_alarm(3) <=(alarm_thr mod 100)/10;
        seg_alarm(2) <= alarm_thr mod 10;
      else
        seg_alarm <= (18,18,18,18,18,18,18,18); -- Blank space
      end if;
    end if;
  end process conv_proc_alarm_thr;  
  
  button_proc: process(clk)
  begin
    if rising_edge(clk) then
      val_up <= up_but;
      old_val_up <= val_up;
      val_down <= down_but;
      old_val_down <= val_down;
      val_plus <= plus_but;
      old_val_plus <= val_plus;
      val_minus <= minus_but;
      old_val_minus <= val_minus;
    end if;
  end process button_proc;
  
  menu_proc: process(clk)
  begin
      if rising_edge(clk) then
      if reset_n = '0' then
        option <= 0;
      elsif enable = '1' then
        if val_up = '0' and old_val_up = '1' then
          option <= option+1;
          if option = OPTIONS-1 then
            option <= 0;
          end if;
        elsif val_down = '0' and old_val_down = '1' then
          option <= option-1;
          if option = 0 then
            option <= OPTIONS-1;
          end if;
        end if;  
      end if;
    end if;
  end process menu_proc;
  
  thr_proc: process(clk)
  begin
      if rising_edge(clk) then
      if reset_n = '0' then
        alarm_thr <= 0;
      elsif enable = '1' then
        if val_plus = '0' and old_val_plus = '1' then
          alarm_thr <= alarm_thr+10;
          if alarm_thr = MAX_THR-10 then
            alarm_thr <= 0;
          end if;
        elsif val_minus = '0' and old_val_minus = '1' then
          alarm_thr <= alarm_thr-10;
          if alarm_thr = 0 then
            alarm_thr <= MAX_THR-10;
          end if;
        end if;  
      end if;
    end if;
  end process thr_proc;
  
  option_proc: process(clk)
  begin
    if rising_edge(clk)then
      case option is
        when 0 =>
          seg_signal <= seg_temp;
          leds_option <= (0 => '1', others => '0');
          alarm_signal <= '0';
        when 1 =>
          seg_signal <= seg_hum;
          leds_option <= (1 => '1', others => '0');
          alarm_signal <= '0';
        when 2 =>
          seg_signal <= seg_air_q;
          leds_option <= (2 => '1', others => '0');
          alarm_signal <= '0';
        when 3 =>
          seg_signal <= seg_alarm;
          leds_option <= (3 => '1', others => '0');
          if signal_air_q > alarm_thr then
            alarm_signal <= '1';
          else 
            alarm_signal <= '0';
          end if;
        when others =>
          null;
      end case;
    end if;
  end process option_proc;
  
  UART_encode_proc: process(clk)
  begin
    if rising_edge(clk) then
      if reset_n = '0' then
        UART_string <= (CHAR_T,CHAR_COL,x"00",x"00",x"00",CHAR_C,CHAR_LF,CHAR_CR,
                        CHAR_H,CHAR_COL,x"00",x"00",x"00",CHAR_PER,CHAR_LF,CHAR_CR,
                        CHAR_A,CHAR_COL,x"00",x"00",x"00",CHAR_p,CHAR_LF,CHAR_CR);
      elsif enable = '1' then
        if signal_temp >= 0 then
          UART_string(2) <= conv_table(signal_temp/100);
          UART_string(3) <= conv_table((signal_temp mod 100)/10);
          UART_string(4) <= conv_table(signal_temp mod 10);
        else 
          UART_string(2) <= conv_table(10); -- -
          UART_string(3) <= conv_table(((0-signal_temp) mod 100)/10);
          UART_string(4) <= conv_table((0-signal_temp) mod 10);
        end if;
        UART_string(10) <= conv_table(signal_hum /100);
        UART_string(11) <= conv_table((signal_hum mod 100)/10);
        UART_string(12) <= conv_table(signal_hum mod 10);
        UART_string(18) <= conv_table(signal_air_q /100);
        UART_string(19) <= conv_table((signal_air_q mod 100)/10);
        UART_string(20) <= conv_table(signal_air_q mod 10);    
      end if;    
    end if;
  end process UART_encode_proc;


end arch_wrapper;
