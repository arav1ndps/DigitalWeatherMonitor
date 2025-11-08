restart -f -nowave
add wave clk_tb_signal enable_tb_signal reset_n_tb_signal data_tb_signal test_tb_signal	
# add wave DS18B20_inst/done_60us DS18B20_inst/done_bit 
# add wave -radix decimal DS18B20_inst/counts_bit DS18B20_inst/counts_inst
# add wave DS18B20_inst/done_480us DS18B20_inst/done_1us DS18B20_inst/done_1s
# add wave DS18B20_inst/state_signal DS18B20_inst/next_state_signal
add wave -radix binary temperature_tb_signal
run 15000000 ns
