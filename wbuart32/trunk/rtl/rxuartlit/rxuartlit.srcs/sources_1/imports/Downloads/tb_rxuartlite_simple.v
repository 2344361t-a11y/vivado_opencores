`timescale 1ns/1ps
`default_nettype none

module tb_rxuartlite_simple;
    // Simulation-friendly UART settings.
    // The real default in rxuartlite.v may be CLOCKS_PER_BAUD=868,
    // but using 16 makes the simulation much shorter while preserving the behavior.
    localparam integer TIMER_BITS      = 5;
    localparam integer CLOCKS_PER_BAUD = 16;

    reg         i_clk     = 1'b0;
    reg         i_uart_rx = 1'b1; // UART idle is high
    wire        o_wr;
    wire [7:0]  o_data;

    integer errors   = 0;
    integer wr_count = 0;
    reg [7:0] last_data = 8'h00;

    // Clock generation: 10 ns period. Only the ratio to CLOCKS_PER_BAUD matters here.
    always #5 i_clk = ~i_clk;

    // Device Under Test: connect the testbench signals to rxuartlite ports.
    rxuartlite #(
        .TIMER_BITS(TIMER_BITS),
        .CLOCKS_PER_BAUD(CLOCKS_PER_BAUD)
    ) dut (
        .i_clk(i_clk),
        .i_uart_rx(i_uart_rx),
        .o_wr(o_wr),
        .o_data(o_data)
    );

    // Monitor the receiver output.
    always @(posedge i_clk) begin
        if (o_wr) begin
            wr_count = wr_count + 1;
            last_data = o_data;
            $display("%0t: RECEIVE DONE: o_data = 0x%02h", $time, o_data);
        end
    end

    task wait_posedges;
        input integer n;
        integer k;
        begin
            for (k = 0; k < n; k = k + 1)
                @(posedge i_clk);
        end
    endtask

    // Drive one UART bit on i_uart_rx for exactly one baud period.
    task drive_bit_for_one_baud;
        input value;
        integer k;
        begin
            @(negedge i_clk);
            i_uart_rx = value;
            for (k = 0; k < CLOCKS_PER_BAUD; k = k + 1)
                @(negedge i_clk);
        end
    endtask

    // Send one 8N1 UART frame: start bit, 8 data bits LSB first, stop bit.
    task send_uart_byte;
        input [7:0] value;
        integer i;
        begin
            drive_bit_for_one_baud(1'b0);        // start bit
            for (i = 0; i < 8; i = i + 1)
                drive_bit_for_one_baud(value[i]); // data bit 0 to bit 7
            drive_bit_for_one_baud(1'b1);        // stop bit
        end
    endtask

    // Send one invalid UART frame whose stop bit is 0.
    task send_uart_byte_bad_stop;
        input [7:0] value;
        integer i;
        begin
            drive_bit_for_one_baud(1'b0);        // start bit
            for (i = 0; i < 8; i = i + 1)
                drive_bit_for_one_baud(value[i]);
            drive_bit_for_one_baud(1'b0);        // bad stop bit
            drive_bit_for_one_baud(1'b1);        // return to idle
        end
    endtask

    task expect_new_byte;
        input [7:0] expected_data;
        input integer old_wr_count;
        begin
            wait_posedges(2 * CLOCKS_PER_BAUD);
            if (wr_count !== old_wr_count + 1) begin
                $display("ERROR: expected one new o_wr pulse. old=%0d now=%0d", old_wr_count, wr_count);
                errors = errors + 1;
            end
            if (last_data !== expected_data) begin
                $display("ERROR: expected data=0x%02h, got=0x%02h", expected_data, last_data);
                errors = errors + 1;
            end
        end
    endtask

    task expect_no_new_byte;
        input integer old_wr_count;
        begin
            wait_posedges(2 * CLOCKS_PER_BAUD);
            if (wr_count !== old_wr_count) begin
                $display("ERROR: expected no new o_wr pulse. old=%0d now=%0d", old_wr_count, wr_count);
                errors = errors + 1;
            end
        end
    endtask

    integer before_count;

    initial begin
        $dumpfile("tb_rxuartlite_simple.vcd");
        $dumpvars(0, tb_rxuartlite_simple);

        // Keep UART line idle before the first frame.
        i_uart_rx = 1'b1;
        wait_posedges(5 * CLOCKS_PER_BAUD);

        // Normal case: receive one byte, 0x55.
        before_count = wr_count;
        send_uart_byte(8'h55);
        expect_new_byte(8'h55, before_count);

        // Error-like case 1: stop bit is 0, so rxuartlite should not assert o_wr.
        before_count = wr_count;
        send_uart_byte_bad_stop(8'h3C);
        expect_no_new_byte(before_count);

        // Error-like case 2: a low pulse shorter than half a baud should not be accepted as a start bit.
        before_count = wr_count;
        @(negedge i_clk);
        i_uart_rx = 1'b0;
        wait_posedges(3);
        @(negedge i_clk);
        i_uart_rx = 1'b1;
        expect_no_new_byte(before_count);

        // Error-like case 3: line held low for a long time. There is no error output,
        // but a valid byte should not be reported.
        before_count = wr_count;
        @(negedge i_clk);
        i_uart_rx = 1'b0;
        wait_posedges(12 * CLOCKS_PER_BAUD);
        @(negedge i_clk);
        i_uart_rx = 1'b1;
        expect_no_new_byte(before_count);

        if (errors == 0)
            $display("PASS: rxuartlite tests passed");
        else
            $display("FAIL: %0d error(s)", errors);

        $finish;
    end
endmodule

`default_nettype wire
