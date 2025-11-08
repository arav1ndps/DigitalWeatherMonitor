restart -f -nowave
add wave clk reset_n enable start_trans done SCL SDA en_byte_write en_byte_read done_byte_read done_byte_write
add wave -hex MSB_data LSB_data
add wave -radix decimal byte_write byte_read temperature
add wave state_signal next_state_signal

force clk 0 0, 1 5ns -repeat 10ns
force reset_n 1 0
force enable 1 0
force start_trans 1 0, 0 200ns
force SDA 0 3940ns, H 5140ns, 0 5340ns, H 5540ns, 0 5940ns, H 6340ns, 0 6540ns, H 6940ns, 0 7140ns
run 9600