`timescale 1ns/1ps
`default_nettype none

module tb_rxuartlite;
    // Simulation settings
    localparam integer CLK_PERIOD_NS = 10;
    localparam integer TIMER_BITS    = 5;
    localparam integer BAUD          = 16;
    localparam [TIMER_BITS-1:0] CLOCKS_PER_BAUD = 5'd16;

    reg         tb_clk;
    reg         rx_line;
    wire        rx_wr;
    wire [7:0]  rx_data;

    integer pass_count;
    integer fail_count;
    integer idx;
    integer path_log_enable;
    reg [3:0] prev_state;

    rxuartlite #(
        .TIMER_BITS(TIMER_BITS),
        .CLOCKS_PER_BAUD(CLOCKS_PER_BAUD)
    ) dut (
        .i_clk(tb_clk),
        .i_uart_rx(rx_line),
        .o_wr(rx_wr),
        .o_data(rx_data)
    );

    initial tb_clk = 1'b0;
    always #(CLK_PERIOD_NS/2) tb_clk = ~tb_clk;

    function [8*12-1:0] state_name;
        input [3:0] s;
        begin
            case (s)
                4'h0: state_name = "BIT_ZERO";
                4'h1: state_name = "BIT_ONE";
                4'h2: state_name = "BIT_TWO";
                4'h3: state_name = "BIT_THREE";
                4'h4: state_name = "BIT_FOUR";
                4'h5: state_name = "BIT_FIVE";
                4'h6: state_name = "BIT_SIX";
                4'h7: state_name = "BIT_SEVEN";
                4'h8: state_name = "STOP";
                4'h9: state_name = "WAIT";
                4'hf: state_name = "IDLE";
                default: state_name = "UNKNOWN";
            endcase
        end
    endfunction

    // Observe DUT internal state transitions for the report's execution-path log.
    // This is for simulation only; the DUT itself is not modified.
    always @(posedge tb_clk) begin
        if (dut.state !== prev_state) begin
            if (path_log_enable) begin
                $display("[%0t] TB_DUT_PATH: %0s -> %0s",
                         $time, state_name(prev_state), state_name(dut.state));
            end
            prev_state <= dut.state;
        end
    end

    task check;
        input condition;
        input [8*120-1:0] message;
        begin
            if (condition) begin
                pass_count = pass_count + 1;
                $display("[%0t] TB_PASS: %0s", $time, message);
            end else begin
                fail_count = fail_count + 1;
                $display("[%0t] TB_FAIL: %0s", $time, message);
            end
        end
    endtask

    task uart_bit;
        input bit_value;
        begin
            @(negedge tb_clk);
            rx_line = bit_value;
            repeat (BAUD) @(posedge tb_clk);
        end
    endtask

    task send_8n1;
        input [7:0] data;
        integer b;
        begin
            $display("[%0t] TB_CASE: send_8n1 data=0x%02h", $time, data);
            uart_bit(1'b0);              // start bit
            for (b = 0; b < 8; b = b + 1) begin
                uart_bit(data[b]);       // data bits, LSB first
            end
            uart_bit(1'b1);              // stop bit
            @(negedge tb_clk);
            rx_line = 1'b1;            // keep idle high
        end
    endtask

    task expect_receive;
        input [7:0] expected;
        integer timeout;
        integer got_wr;
        begin
            timeout = 14 * BAUD + 50;
            got_wr = 0;

            while ((timeout > 0) && (got_wr == 0)) begin
                @(posedge tb_clk);
                #1;
                if (rx_wr) begin
                    got_wr = 1;
                end
                timeout = timeout - 1;
            end

            check(got_wr == 1, "rx_wr must assert after a valid 8N1 frame");

            if (got_wr == 1) begin
                $display("[%0t] TB_INFO: rx_wr=1 rx_data=0x%02h expected=0x%02h",
                         $time, rx_data, expected);
                check(rx_data === expected, "rx_data must match transmitted byte");

                @(posedge tb_clk);
                #1;
                check(rx_wr == 1'b0, "rx_wr must be a one-clock pulse");
            end
        end
    endtask

    task run_case;
        input [7:0] data;
        begin
            fork
                send_8n1(data);
                expect_receive(data);
            join
            repeat (3 * BAUD) @(posedge tb_clk);
        end
    endtask

    initial begin
        rx_line         = 1'b1;          // UART idle level
        pass_count      = 0;
        fail_count      = 0;
        path_log_enable = 1;
        prev_state      = 4'hx;

        $display("[%0t] TB_PATH: simulation start", $time);
        repeat (4 * BAUD) @(posedge tb_clk);
        check(rx_wr == 1'b0, "rx_wr must stay 0 during idle before reception");

        // Representative normal-operation tests
        // 0x55: alternating pattern, 0x00: all low data bits,
        // 0xff: all high data bits, 0xa5: mixed non-symmetric pattern.
        run_case(8'h55);
        path_log_enable = 0;
        run_case(8'h00);
        run_case(8'hff);
        run_case(8'ha5);

        // Optional exhaustive normal-operation sweep.
        // Uncomment this block if you want to verify all 256 byte values.
        // for (idx = 0; idx < 256; idx = idx + 1) begin
        //     run_case(idx);
        // end

        $display("[%0t] TB_SUMMARY: pass=%0d fail=%0d", $time, pass_count, fail_count);
        if (fail_count == 0)
            $display("[%0t] TB_RESULT: PASS", $time);
        else
            $display("[%0t] TB_RESULT: FAIL", $time);
        $finish;
    end
endmodule

`default_nettype wire
