library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.segment_pack.all;

entity segment_display is
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
end segment_display;

architecture arch_segment_display of segment_display is

  constant FRAME_PERIOD: natural := SEC2NS/(FPS*DIGITS*CLK_PERIOD);
  
  signal en_digit_count: std_logic := '0';
  signal done_count: std_logic := '0';
  signal digit: natural range 0 to DIGITS-1 := 0;
  signal digit_vals: digit_array := (0,0,0,0,0,0,0,0);

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
  digit_clk: component counter
    generic map(COUNTS => FRAME_PERIOD)
    port map(reset_n => reset_n,
             clk => clk,
             enable => enable,
             q => en_digit_count);

  digit_count: component counter
    generic map(COUNTS => DIGITS)
    port map(reset_n => reset_n,
             clk => clk,
             enable => en_digit_count,
             q => done_count,
             count => digit);

  output_proc: process(clk)
  begin
    if rising_edge(clk) then
      if reset_n = '0' then
        AN <= (others=>'1');
        CA <= (others=>'1');
      else
        AN <= (others => '1');
        AN(digit) <= '0';
        CA <= segment_vals(digit_vals(digit));
      end if;
    end if;
  end process output_proc;
  
--  digit_vals <= digit_vals_in;

  update_proc: process(clk)
  begin
    if rising_edge(clk) and update = '1' then
      digit_vals <= digit_vals_in;
    else
      digit_vals <= digit_vals;
    end if;
  end process update_proc;
end arch_segment_display;
