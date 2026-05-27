`timescale 1ns/1ps

module tb_linetest;
    reg clk;
    reg rx;
    wire tx;

    // 100MHz Clock (Period: 10ns)
    initial begin
        clk = 0;
        rx = 1;
    end
    always #5 clk = ~clk;

    // Instantiate linetest top module
    linetest dut (
        .i_clk(clk),
        .i_uart_rx(rx),
        .o_uart_tx(tx)
    );

    // Task to transmit a character over UART RX line at 115200 Baud (868 clocks = 8680ns per bit)
    task send_char(input [7:0] char);
        integer i;
        begin
            $display("[%0d] TB: Sending character '%c' (0x%0h)", $time, char, char);
            // Start bit (0)
            rx <= 0;
            #8680;
            // 8 data bits (LSB first)
            for (i = 0; i < 8; i = i + 1) begin
                rx <= char[i];
                #8680;
            end
            // Stop bit (1)
            rx <= 1;
            #8680;
        end
    endtask

    // Simulation control
    initial begin
        $display("[%0d] Line Test simulation started", $time);
        
        // Wait for receiver power-on reset synchronization (break_condition = 13888 clocks = 138.88us)
        #150000;
        
        // Send a line of text: "Hi\n"
        send_char("H");
        send_char("i");
        send_char("\n"); // Carriage return / newline triggers the echo
        
        // Wait for the echo to be transmitted back
        // "Hi\n" has 3 characters. Each character takes ~86.8us to transmit.
        // Total transmission time is ~260us. Let's wait 500us (500000ns).
        $display("[%0d] TB: Sent full line, waiting for echo...", $time);
        #500000;
        
        $display("[%0d] Line Test simulation finished", $time);
        $finish;
    end

    // Monitor tx activity
    always @(negedge tx) begin
        $display("[%0d] TB_MONITOR: tx line started toggling! (Sending data back)", $time);
    end

endmodule
