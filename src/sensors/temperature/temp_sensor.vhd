library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity temp_sensor is
--  generic(REG_SIZE: positive := 8;
--          I2C_ADDR: unsigned := x"4B";
--          I2C_FREQ: positive := 100; -- MHz
--          CLK_PERIOD: positive := 10); -- ns
  port(SDA: inout std_logic;
       SCL: inout std_logic;
       clk: in std_logic;
       enable: in std_logic;
       reset_n: in std_logic;
       start_trans: in std_logic;
--       done: out std_logic;
       temperature: out signed(15 downto 0));
end temp_sensor;

architecture arch_temp_sensor of temp_sensor is
  constant REG_SIZE: positive := 8;
  constant I2C_ADDR: unsigned := x"4B";
  constant I2C_FREQ: positive := 100; -- kHz
  constant CLK_PERIOD: positive := 10; -- ns
  
  constant MS2NS: positive := 1000000;
  
  constant I2C_PERIOD: positive := MS2NS/I2C_FREQ;
  
  constant SCL_COUNTS: positive range 1 to 10000 := I2C_PERIOD/CLK_PERIOD;
  constant WRITE_OFFSET: positive range 1 to 10000 := SCL_COUNTS/4;
  constant READ_OFFSET: positive range 1 to 10000 := 3*SCL_COUNTS/4;
  constant ADDR: unsigned(REG_SIZE-1 downto 0) := shift_left(I2C_ADDR, 1) + "1"; -- 1 read
  constant REG: unsigned(REG_SIZE-1 downto 0) := x"E8";

  function std_vect_inout (input: unsigned) return std_logic_vector is
    variable output: std_logic_vector(REG_SIZE-1 downto 0) := (others => '0');
  begin
    for i in 0 to output'length-1 loop
      if input(i) = '1' then
        output(i) := 'H';
      else
        output(i) := '0';
      end if;
    end loop;
    return output;
  end function;
  
  constant ADDR_INOUT: std_logic_vector(REG_SIZE-1 downto 0) := std_vect_inout(addr);
  constant REG_INOUT: std_logic_vector(REG_SIZE-1 downto 0) := std_vect_inout(reg);

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

  component clock_generator is
    generic(COUNTS:integer := 10;
            SHIFT:integer := 0);
    port(reset_n:in std_logic;
         clk:in std_logic;
         enable:in std_logic;
         q:out std_logic);
  end component;

--  type state_type is (idle, en_clocks, start, write_addr, ack_addr, write_reg, ack_reg, wait_clk, re_start, write_addr_2, ack_addr_2, wait_read_MSB, read_MSB, ack, read_LSB, nack, stop);
  type state_type is (idle, en_clocks, start, write_addr, ack_addr, write_reg, ack_reg, wait_clk, re_start, write_addr_2, ack_addr_2, read_MSB, ack, read_LSB, nack, stop);
  signal state_signal: state_type;
  signal next_state_signal: state_type;

  signal rst_SCL: std_logic := '1';
  signal en_SCL: std_logic := '1';
  signal rst_read: std_logic := '1';
  signal en_read: std_logic := '1';
  signal rst_write: std_logic := '1';
  signal en_write: std_logic := '1';
  signal rst_byte_write: std_logic := '1';
  signal en_byte_write: std_logic := '1';
  signal done_byte_write: std_logic := '1';
  signal rst_byte_read: std_logic := '1';
  signal en_byte_read: std_logic := '1';
  signal done_byte_read: std_logic := '1';

  signal byte_write: natural range 0 to REG_SIZE := 0;
  signal byte_read: natural range 0 to REG_SIZE := 0;

  signal MSB_data: signed (REG_SIZE-1 downto 0) := (others => '0');
  signal LSB_data: signed (REG_SIZE-1 downto 0) := (others => '0');
begin
  SCL_clk: component clock_generator
    generic map(COUNTS => SCL_COUNTS)
    port map(reset_n => rst_SCL,
         clk => clk,
         enable => en_SCL,
         q => SCL);
  
  write_clk: component counter
    generic map(COUNTS => SCL_COUNTS,
                SHIFT => WRITE_OFFSET)
    port map(reset_n => rst_write,
             clk => clk,
             enable => en_write,
             q => en_byte_write);
  
  read_clk: component counter
    generic map(COUNTS => SCL_COUNTS,
                SHIFT => READ_OFFSET)
    port map(reset_n => rst_read,
             clk => clk,
             enable => en_read,
             q => en_byte_read);

  write_count: component counter_down
    generic map(COUNTS => REG_SIZE)
    port map(reset_n => rst_byte_write,
             clk => clk,
             enable => en_byte_write,
             q => done_byte_write,
             count => byte_write);

  read_count: component counter_down
    generic map(COUNTS => REG_SIZE)
    port map(reset_n => rst_byte_read,
         clk => clk,
         enable => en_byte_read,
         q => done_byte_read,
         count => byte_read);

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

  state_flow_proc: process(state_signal, start_trans, en_byte_read, en_byte_write, SDA, SCL, done_byte_write)
  begin
    case state_signal is
      when idle =>
        if start_trans = '1' then
          next_state_signal <= en_clocks;
        else
          next_state_signal <= state_signal;
        end if;
      when en_clocks =>
        if en_byte_read = '1' then
          next_state_signal <= start;
        else
          next_state_signal <= state_signal;
        end if;
      when start =>
        if en_byte_write = '1' then
          next_state_signal <= write_addr;
        else
          next_state_signal <= state_signal;
        end if;
      when write_addr =>
        if done_byte_write = '1' then
          next_state_signal <= ack_addr;
        else
          next_state_signal <= state_signal;
        end if;
      when ack_addr =>
        if en_byte_write = '1' then
          next_state_signal <= write_reg;
        else
          next_state_signal <= state_signal;
        end if;
      when write_reg =>
        if done_byte_write = '1' then
          next_state_signal <= ack_reg;
        else
          next_state_signal <= state_signal;
        end if;
      when ack_reg =>
        if en_byte_read = '1' then
          next_state_signal <= wait_clk;
        else
          next_state_signal <= state_signal;
        end if; 
      when wait_clk =>
        if en_byte_read = '1' then
          next_state_signal <= re_start;
        else
          next_state_signal <= state_signal;
        end if; 
      when re_start =>
        if en_byte_write = '1' then
          next_state_signal <= write_addr_2;
--        if SCL = '0' then
--          next_state_signal <= wait_read_MSB;
        else
          next_state_signal <= state_signal;
        end if;
--      when wait_read_MSB =>
--        if en_byte_write = '1' then
--          next_state_signal <= write_addr_2;
--        else
--          next_state_signal <= state_signal;
--        end if; 
      when write_addr_2 =>
        if done_byte_write = '1' then
          next_state_signal <= ack_addr_2;
        else
          next_state_signal <= state_signal;
        end if;
      when ack_addr_2 =>
        if en_byte_write = '1' then
          next_state_signal <= read_MSB;
        else
          next_state_signal <= state_signal;
        end if;
      when read_MSB =>
        if done_byte_write = '1' then
          next_state_signal <= ack;
        else
          next_state_signal <= state_signal;
        end if;
      when ack =>
        if en_byte_write = '1' then
          next_state_signal <= read_LSB;
        else
          next_state_signal <= state_signal;
        end if;
      when read_LSB =>
        if done_byte_write = '1' then
          next_state_signal <= nack;
        else
          next_state_signal <= state_signal;
        end if;
      when nack =>
        if en_byte_write = '1' then
          next_state_signal <= stop;
        else
          next_state_signal <= state_signal;
        end if;
      when stop =>
        if en_byte_read = '1' then
          next_state_signal <= idle;
        else
          next_state_signal <= state_signal;
        end if;
    end case;
  end process state_flow_proc;

  assignment_proc: process(state_signal, byte_read, byte_write, SDA, SCL, en_byte_read, MSB_data, LSB_data)
  begin
    case state_signal is
      when idle =>
        temperature <= (others => '0');
        SDA <= 'H';
--        done <= '0';
        rst_SCL <='0';
        en_SCL <= '0';
        rst_read <= '0';
        en_read <= '0';
        rst_write <= '0';
        en_write <= '0';
        rst_byte_write <= '0';
        rst_byte_read <= '0';  
        MSB_data <= (others => '1');
        LSB_data <= (others => '1'); 
      when en_clocks =>
        rst_SCL <='1';
        en_SCL <= '1';
        rst_read <= '1';
        en_read <= '1';
        rst_write <= '1';
        en_write <= '1';
        rst_byte_write <= '0';
        rst_byte_read <= '0';  
        SDA <= 'H';
      when start =>
        rst_SCL <='1';
        en_SCL <= '1';
        rst_read <= '1';
        en_read <= '1';
        rst_write <= '1';
        en_write <= '1';
        rst_byte_write <= '0';
        rst_byte_read <= '0'; 
        SDA <= '0';
      when write_addr =>
        rst_SCL <='1';
        en_SCL <= '1';
        rst_read <= '1';
        en_read <= '1';
        rst_write <= '1';
        en_write <= '1';
        rst_byte_write <= '1';
        rst_byte_read <= '0'; 
        SDA <= ADDR_INOUT(byte_write);
      when ack_addr =>
        rst_SCL <='1';
        en_SCL <= '1';
        rst_read <= '1';
        en_read <= '1';
        rst_write <= '1';
        en_write <= '1';
        rst_byte_write <= '0';
        rst_byte_read <= '0';  
      when write_reg =>
        rst_SCL <='1';
        en_SCL <= '1';
        rst_read <= '1';
        en_read <= '1';
        rst_write <= '1';
        en_write <= '1';
        rst_byte_write <= '1';
        rst_byte_read <= '0'; 
        SDA <= REG_INOUT(byte_write);
      when ack_reg => 
        rst_SCL <='1';
        en_SCL <= '1';
        rst_read <= '1';
        en_read <= '1';
        rst_write <= '1';
        en_write <= '1';
        rst_byte_write <= '0';
        rst_byte_read <= '0'; 
        SDA <= 'H';
      when wait_clk =>
        rst_SCL <='1';
        en_SCL <= '1';
        rst_read <= '1';
        en_read <= '1';
        rst_write <= '1';
        en_write <= '1';
        rst_byte_write <= '0';
        rst_byte_read <= '0';   
        SDA <= 'H';
      when re_start =>
        rst_SCL <='1';
        en_SCL <= '1';
        rst_read <= '1';
        en_read <= '1';
        rst_write <= '1';
        en_write <= '1';
        rst_byte_write <= '0';
        rst_byte_read <= '0'; 
        SDA <= '0';
--      when wait_read_MSB =>
--        rst_SCL <='1';
--        en_SCL <= '1';
--        rst_read <= '1';
--        en_read <= '1';
--        rst_write <= '1';
--        en_write <= '1';
--        rst_byte_write <= '0';
--        rst_byte_read <= '0'; 
--        SDA <= 'H';
      when write_addr_2 =>
        rst_SCL <='1';
        en_SCL <= '1';
        rst_read <= '1';
        en_read <= '1';
        rst_write <= '1';
        en_write <= '1';
        rst_byte_write <= '1';
        rst_byte_read <= '0'; 
        SDA <= ADDR_INOUT(byte_write);
      when ack_addr_2 =>
        rst_SCL <='1';
        en_SCL <= '1';
        rst_read <= '1';
        en_read <= '1';
        rst_write <= '1';
        en_write <= '1';
        rst_byte_write <= '0';
        rst_byte_read <= '0';  
      when read_MSB =>
        rst_SCL <='1';
        en_SCL <= '1';
        rst_read <= '1';
        en_read <= '1';
        rst_write <= '1';
        en_write <= '1';
        rst_byte_write <= '1';
        rst_byte_read <= '1'; 
        SDA <= 'H';
        if en_byte_read = '1' then
          MSB_data(byte_read) <= SDA;
        end if;
      when ack =>
        rst_SCL <='1';
        en_SCL <= '1';
        rst_read <= '1';
        en_read <= '1';
        rst_write <= '1';
        en_write <= '1';
        rst_byte_write <= '0';
        rst_byte_read <= '0'; 
        SDA <= '0';
      when read_LSB =>
        rst_SCL <='1';
        en_SCL <= '1';
        rst_read <= '1';
        en_read <= '1';
        rst_write <= '1';
        en_write <= '1';
        rst_byte_write <= '1';
        rst_byte_read <= '1'; 
        SDA <= 'H';
        if en_byte_read = '1' then
          LSB_data(byte_read) <= SDA;
        end if;
      when nack =>
        rst_SCL <='1';
        en_SCL <= '1';
        rst_read <= '1';
        en_read <= '1';
        rst_write <= '1';
        en_write <= '1';
        rst_byte_write <= '1';
        rst_byte_read <= '1'; 
        SDA <= 'H';
      when stop =>
        rst_SCL <='1';
        en_SCL <= '1';
        rst_read <= '1';
        en_read <= '1';
        rst_write <= '1';
        en_write <= '1';
        rst_byte_write <= '1';
        rst_byte_read <= '1'; 
        SDA <= '0';
--        done <= '1';
        temperature <= MSB_data & LSB_data;
    end case;
  end process assignment_proc;
end arch_temp_sensor;
