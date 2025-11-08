restart -f -nowave
add wave clk_tb_signal tx_tb_signal UART_inst/done_clk
add wave UART_inst/state_signal UART_inst/next_state_signal
add wave -radix decimal UART_inst/counts_control UART_inst/counts_bit UART_inst/counts_char

run 30000 ns