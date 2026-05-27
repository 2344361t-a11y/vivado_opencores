`timescale 1ns/1ps

module tb_helloworld;
    reg clk;
    wire tx;

    // 100MHz Clock (Period: 10ns)
    initial begin
        clk = 0;
    end
    always #5 clk = ~clk;

    // Instantiate helloworld top module
    helloworld dut (
        .i_clk(clk),
        .o_uart_tx(tx)
    );

    // Simulation control
    initial begin
        $display("[%0d] Simulation started", $time);
        
        // Run for 2.5ms to allow the complete "Hello, World!\r\n" string to transmit.
        // 115200 Baud with 8N1 takes ~86.8us per character.
        // 16 characters take ~1.39ms to transmit.
        #2500000;
        
        $display("[%0d] Simulation finished", $time);
        $finish;
    end

endmodule
