`timescale 1ns/1ps

module tb_echotest;
    reg clk;
    reg rx;
    wire tx;

    // 100MHz Clock (Period: 10ns)
    initial begin
        clk = 0;
        rx = 1;
    end
    always #5 clk = ~clk;

    // Instantiate echotest top module
    echotest dut (
        .i_clk(clk),
        .i_uart_rx(rx),
        .o_uart_tx(tx)
    );

    // Drive rx and observe tx
    initial begin
        $display("[%0d] Echo Test simulation started", $time);
        
        #100;
        @(posedge clk);
        $display("[%0d] Driving RX to 0", $time);
        rx <= 0;
        @(posedge clk);
        $display("[%0d] Driving RX to 1", $time);
        rx <= 1;
        @(posedge clk);
        $display("[%0d] Driving RX to 0", $time);
        rx <= 0;
        @(posedge clk);
        $display("[%0d] Driving RX to 1", $time);
        rx <= 1;
        
        #200;
        $display("[%0d] Echo Test simulation finished", $time);
        $finish;
    end

endmodule
