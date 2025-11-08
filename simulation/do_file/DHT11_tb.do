restart -f -nowave
add wave reset_n_tb_signal enable_tb_signal clk_tb_signal measure_tb_signal data_tb_signal
add wave -radix binary humidity_tb_signal state_tb_signal
add wave -radix decimal counts_tb_signal
# add wave DHT11_inst/state_signal DHT11_inst/next_state_signal DHT11_inst/count_bits DHT11_inst/count_timer
 
run 12000 ns