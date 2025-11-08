restart -f -nowave

add wave reset_n_tb_signal clk_tb_signal enable_tb_signal
add wave -hex CA_tb_signal AN_tb_signal
add wave segment_display_inst/digit

run 800