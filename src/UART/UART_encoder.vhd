library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.UART_pack.all;
use WORK.decoder_pack.all;

entity UART_encoder is
  port(reset_n: in std_logic;
       clk: in std_logic;
       enable: in std_logic;
       temp_in: in symbol_array;
       hum_in: in symbol_array;
       air_in: in symbol_array;
       data_out: out str);
end UART_encoder;

architecture arch_UART_encoder of UART_encoder is
  
begin
  encoder_proc: process(clk)
  begin
    if rising_edge(clk) then
      if reset_n = '0' then
        data_out <= (CHAR_T, CHAR_COL, x"30", x"30", x"30",CHAR_C,CHAR_NEW,
                     CHAR_H, CHAR_COL, x"30", x"30", x"30",CHAR_PERCENT,CHAR_NEW,
                     CHAR_A, CHAR_COL, x"30", x"30", x"30",CHAR_p,CHAR_NEW);
      elsif enable = '1' then
        data_out(2) <= conv_table(temp_in(0));
        data_out(3) <= conv_table(temp_in(1));
        data_out(4) <= conv_table(temp_in(2));
        data_out(9) <= conv_table(hum_in(0));
        data_out(10) <= conv_table(hum_in(1));
        data_out(11) <= conv_table(hum_in(2));
        data_out(16) <= conv_table(air_in(0));
        data_out(17) <= conv_table(air_in(1));
        data_out(18) <= conv_table(air_in(2));
      end if;
    end if;
  end process encoder_proc;
end arch_UART_encoder;
