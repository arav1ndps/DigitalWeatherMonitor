restart -f -nowave
add wave clk_tb_signal reset_n_tb_signal enable_in_tb_signal enable_out_tb_signal
add wave -radix decimal display_enable_inst/counts
run 8000
