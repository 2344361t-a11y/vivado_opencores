# Create project
create_project wbuart_original_benches ./wbuart_original_benches -part xc7a35tcsg324-1 -force

# Add RTL source files
add_files {
    ./wbuart32/trunk/rtl/txuart.v
    ./wbuart32/trunk/rtl/rxuart.v
    ./wbuart32/trunk/rtl/wbuart.v
    ./wbuart32/trunk/rtl/ufifo.v
}

# Add testbench and design bench files
add_files -fileset sim_1 {
    ./wbuart32/trunk/bench/verilog/helloworld.v
    ./wbuart32/trunk/bench/verilog/echotest.v
    ./wbuart32/trunk/bench/verilog/linetest.v
    ./wbuart32/trunk/bench/verilog/speechfifo.v
    ./tb_helloworld.v
    ./tb_echotest.v
    ./tb_linetest.v
    ./tb_speechfifo.v
}

update_compile_order -fileset sim_1

# ----------------- Simulate helloworld -----------------
puts "=================== SIMULATING HELLOWORLD ==================="
set_property top tb_helloworld [get_filesets sim_1]
set_property -name {xsim.simulate.runtime} -value {2.5ms} -objects [get_filesets sim_1]
update_compile_order -fileset sim_1
launch_simulation
close_sim

# ----------------- Simulate echotest -----------------
puts "=================== SIMULATING ECHOTEST ==================="
set_property top tb_echotest [get_filesets sim_1]
set_property -name {xsim.simulate.runtime} -value {500ns} -objects [get_filesets sim_1]
update_compile_order -fileset sim_1
launch_simulation
close_sim

# ----------------- Simulate linetest -----------------
puts "=================== SIMULATING LINETEST ==================="
set_property top tb_linetest [get_filesets sim_1]
set_property -name {xsim.simulate.runtime} -value {600us} -objects [get_filesets sim_1]
update_compile_order -fileset sim_1
launch_simulation
close_sim

# ----------------- Simulate speechfifo -----------------
puts "=================== SIMULATING SPEECHFIFO ==================="
# Copy speech.hex to the simulation directory so the simulator can read it
file mkdir ./wbuart_original_benches/wbuart_original_benches.sim/sim_1/behav/xsim
file copy -force ./wbuart32/trunk/bench/verilog/speech.hex ./wbuart_original_benches/wbuart_original_benches.sim/sim_1/behav/xsim/speech.hex

set_property top tb_speechfifo [get_filesets sim_1]
set_property -name {xsim.simulate.runtime} -value {2ms} -objects [get_filesets sim_1]
update_compile_order -fileset sim_1
launch_simulation
close_sim

puts "=================== ALL SIMULATIONS COMPLETED ==================="
exit
