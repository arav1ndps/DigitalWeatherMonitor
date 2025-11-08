restart -f -nowave
add wave clk_tb_signal reset_n_tb_signal enable_tb_signal
add wave q_tb_signal
add wave -radix decimal count_tb_signal

run 160ns