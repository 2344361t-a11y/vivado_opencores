# Copy speech.hex to the current directory so that the tb_speechfifo simulation can find it
if {[file exists ./wbuart32/trunk/bench/verilog/speech.hex]} {
    file copy -force ./wbuart32/trunk/bench/verilog/speech.hex ./speech.hex
}

# Compile each Verilog file individually to reset compiler state (like default_nettype) between files
exec xvlog ./wbuart32/trunk/rtl/txuart.v
exec xvlog ./wbuart32/trunk/rtl/rxuart.v
exec xvlog ./wbuart32/trunk/rtl/wbuart.v
exec xvlog ./wbuart32/trunk/rtl/ufifo.v
exec xvlog ./wbuart32/trunk/bench/verilog/helloworld.v
exec xvlog ./wbuart32/trunk/bench/verilog/echotest.v
exec xvlog ./wbuart32/trunk/bench/verilog/linetest.v
exec xvlog ./wbuart32/trunk/bench/verilog/speechfifo.v
exec xvlog ./tb_helloworld.v
exec xvlog ./tb_echotest.v
exec xvlog ./tb_linetest.v
exec xvlog ./tb_speechfifo.v

# Elaborate snapshots for each testbench (using --relax to convert timescale errors to warnings)
exec xelab -top tb_helloworld -snapshot tb_helloworld_behav --relax
exec xelab -top tb_echotest -snapshot tb_echotest_behav --relax
exec xelab -top tb_linetest -snapshot tb_linetest_behav --relax
exec xelab -top tb_speechfifo -snapshot tb_speechfifo_behav --relax

# Run simulations and output to individual logs
puts "=================== RUNNING HELLOWORLD ==================="
exec xsim tb_helloworld_behav -R -log helloworld_sim.log

puts "=================== RUNNING ECHOTEST ==================="
exec xsim tb_echotest_behav -R -log echotest_sim.log

puts "=================== RUNNING LINETEST ==================="
exec xsim tb_linetest_behav -R -log linetest_sim.log

puts "=================== RUNNING SPEECHFIFO ==================="
exec xsim tb_speechfifo_behav -R -log speechfifo_sim.log

puts "=================== ALL SIMULATIONS COMPLETED ==================="
exit
