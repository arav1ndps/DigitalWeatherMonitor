restart -f -nowave
add wave clk reset_n enable
add wave q
add wave -radix decimal count

force clk 1 0, 0 5ns -repeat 10ns
force reset_n 0 0, 1 10ns
force enable 0 0, 1 10ns

run 300ns