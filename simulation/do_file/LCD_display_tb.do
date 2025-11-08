restart -f -nowave
add wave reset_n_tb_signal enable_tb_signal clk_tb_signal update_tb_signal
add wave E_tb_signal RS_tb_signal R_W_tb_signal
add wave -hex DB_tb_signal
# add wave -radix binary state_out_tb_signal
# add wave done_16ms_out_tb_signal done_5ms_out_tb_signal done_func_out_tb_signal done_100us_out_tb_signal done_data_out_tb_signal

run 50000000 ns