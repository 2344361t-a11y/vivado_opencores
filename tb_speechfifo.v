`timescale 1ns/1ps

module tb_speechfifo;
    reg clk;
    wire tx;

    // 100MHz Clock (Period: 10ns)
    initial begin
        clk = 0;
    end
    always #5 clk = ~clk;

    // Instantiate speechfifo top module
    speechfifo dut (
        .i_clk(clk),
        .o_uart_tx(tx)
    );

    // Simulation control
    initial begin
        $display("[%0d] Speech FIFO simulation started", $time);
        
        // Run for 2ms to observe transmission
        #2000000;
        
        $display("[%0d] Speech FIFO simulation finished", $time);
        $finish;
    end

endmodule
