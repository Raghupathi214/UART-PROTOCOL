vlog -source tb.sv
vlog -source uart.sv
vsim -novopt work.tb

add wave -r /*
run -all

quit
