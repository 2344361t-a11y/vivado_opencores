# Create project
create_project wbuart_sim ./wbuart_sim -part xc7a35tcsg324-1 -force

# Add RTL source files
add_files {
    ./wbuart32/trunk/rtl/txuart.v
    ./wbuart32/trunk/rtl/rxuart.v
}

# Add testbench file
add_files -fileset sim_1 {
    ./tb_wbuart_loopback.v
}

# Set simulation top
set_property top tb_wbuart_loopback [get_filesets sim_1]
update_compile_order -fileset sim_1

# Set simulation run time to 50us (to complete all test cases)
set_property -name {xsim.simulate.runtime} -value {50us} -objects [get_filesets sim_1]

# Launch simulation (this will automatically run for 50us)
launch_simulation

# Exit Vivado
# exit
