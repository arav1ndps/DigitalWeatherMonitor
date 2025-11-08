restart -f -nowave

add wave clk_tb_signal enable_tb_signal reset_n_tb_signal
add wave data_out_tb_signal

run 100 ns;