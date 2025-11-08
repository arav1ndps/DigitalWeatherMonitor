restart -f -nowave
add wave clk_tb_signal enable_tb_signal reset_n_tb_signal sample_tb_signal CS_tb_signal SPI_CLK_tb_signal MOSI_tb_signal MISO_tb_signal
add wave -radix binary state_tb_signal
# add wave SPI_ADC_inst/state_signal SPI_ADC_inst/next_state_signal
# add wave SPI_ADC_inst/done_write SPI_ADC_inst/done_read SPI_ADC_inst/bit_read
run 100000 ns