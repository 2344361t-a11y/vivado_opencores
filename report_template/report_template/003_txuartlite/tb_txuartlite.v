`timescale 1ns/1ps
`default_nettype none

module tb_txuartlite_case1_only_20260605_1330;

    localparam integer CLK_PERIOD_NS   = 10;
    localparam [4:0]   TIMING_BITS_TB  = 5'd5;
    localparam [4:0]   CLOCKS_PER_BAUD = 5'd10;

    // Testbench-side signal names based on the block diagram.
    reg         tb_clk;
    reg         tx_wr;
    reg  [7:0]  tx_data;
    wire        tx_line;
    wire        tx_busy;

    integer pass_count;
    integer fail_count;
    integer frame_errors;
    integer busy_errors;
    integer k;
    integer b;
    reg [3:0] last_state;

    txuartlite #(
        .TIMING_BITS(TIMING_BITS_TB),
        .CLOCKS_PER_BAUD(CLOCKS_PER_BAUD)
    ) dut (
        .i_clk(tb_clk),
        .i_wr(tx_wr),
        .i_data(tx_data),
        .o_uart_tx(tx_line),
        .o_busy(tx_busy)
    );

    initial begin
        tb_clk = 1'b0;
        forever #(CLK_PERIOD_NS/2) tb_clk = ~tb_clk;
    end

    function [127:0] state_name;
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
                4'h9: state_name = "STOP_HOLD";
                4'hf: state_name = "IDLE";
                default: state_name = "UNKNOWN";
            endcase
        end
    endfunction

    always @(posedge tb_clk) begin
        #1;
        if (last_state !== dut.state) begin
            $display("[%0t] TB_DUT_PATH: %0s -> %0s", $time, state_name(last_state), state_name(dut.state));
            last_state <= dut.state;
        end
    end

    task tb_pass;
        input [8*120-1:0] msg;
        begin
            pass_count = pass_count + 1;
            $display("[%0t] TB_PASS: %0s", $time, msg);
        end
    endtask

    task tb_fail;
        input [8*120-1:0] msg;
        begin
            fail_count = fail_count + 1;
            $display("[%0t] TB_FAIL: %0s", $time, msg);
        end
    endtask

    task expect_signal;
        input actual;
        input expected;
        input [8*120-1:0] msg;
        begin
            if (actual === expected)
                tb_pass(msg);
            else begin
                tb_fail(msg);
                $display("[%0t] TB_INFO: expected=%0b actual=%0b", $time, expected, actual);
            end
        end
    endtask

    task wait_idle;
        begin
            while (tx_busy !== 1'b0)
                @(posedge tb_clk);
            @(negedge tb_clk);
        end
    endtask

    task start_write_55;
        begin
            wait_idle();
            tx_data = 8'h55;
            tx_wr   = 1'b1;
            @(posedge tb_clk);
            #1;
            $display("[%0t] TB_CASE: CASE1 pulse_write tx_data=0x55", $time);
            $display("[%0t] TB_INFO: tx_wr=1 tx_data=0x%02h tx_line=%0b tx_busy=%0b", $time, tx_data, tx_line, tx_busy);
        end
    endtask

    task sample_bit;
        input expected_bit;
        input [8*120-1:0] label;
        begin
            @(negedge tb_clk);
            if (tx_line !== expected_bit) begin
                frame_errors = frame_errors + 1;
                tb_fail(label);
                $display("[%0t] TB_INFO: expected_tx_line=%0b actual_tx_line=%0b", $time, expected_bit, tx_line);
            end
            if (tx_busy !== 1'b1) begin
                busy_errors = busy_errors + 1;
                tb_fail("CASE1 tx_busy must stay 1 during transmission");
                $display("[%0t] TB_INFO: tx_busy dropped during frame", $time);
            end
            @(posedge tb_clk);
            #1;
        end
    endtask

    task check_bit_period;
        input expected_bit;
        input [8*120-1:0] label;
        begin
            for (k = 0; k < CLOCKS_PER_BAUD; k = k + 1)
                sample_bit(expected_bit, label);
        end
    endtask

    task check_start_period_after_write;
        begin
            @(negedge tb_clk);
            tx_wr = 1'b0;
            if (tx_line !== 1'b0) begin
                frame_errors = frame_errors + 1;
                tb_fail("CASE1 start bit must be 0");
                $display("[%0t] TB_INFO: start bit expected 0 actual %0b", $time, tx_line);
            end
            if (tx_busy !== 1'b1) begin
                busy_errors = busy_errors + 1;
                tb_fail("CASE1 tx_busy must be 1 during start bit");
            end
            @(posedge tb_clk);
            #1;

            for (k = 1; k < CLOCKS_PER_BAUD; k = k + 1)
                sample_bit(1'b0, "CASE1 start bit must stay 0 for one bit period");
        end
    endtask

    task run_case1_55;
        integer before_frame_errors;
        integer before_busy_errors;
        begin
            $display("[%0t] TB_PATH: CASE1 normal transmit start", $time);
            frame_errors = 0;
            busy_errors  = 0;
            before_frame_errors = frame_errors;
            before_busy_errors  = busy_errors;

            start_write_55();
            check_start_period_after_write();

            for (b = 0; b < 8; b = b + 1)
                check_bit_period(tx_data[b], "CASE1 data bits must be 1,0,1,0,1,0,1,0 in LSB first order");

            check_bit_period(1'b1, "CASE1 stop bit must be 1");

            if (frame_errors == before_frame_errors)
                tb_pass("CASE1 8N1 frame must be 0,1,0,1,0,1,0,1,0,1");
            if (busy_errors == before_busy_errors)
                tb_pass("CASE1 tx_busy must stay 1 during frame");

            expect_signal(tx_busy, 1'b0, "CASE1 tx_busy must clear after stop bit");
            expect_signal(tx_line, 1'b1, "CASE1 tx_line must return to idle high");
        end
    endtask

    initial begin
        pass_count   = 0;
        fail_count   = 0;
        frame_errors = 0;
        busy_errors  = 0;
        last_state   = 4'hx;
        tx_wr        = 1'b0;
        tx_data      = 8'h55;

        $display("[%0t] TB_PATH: simulation start", $time);

        repeat (3) @(posedge tb_clk);
        #1;
        $display("[%0t] TB_PATH: initial settle done", $time);
        expect_signal(tx_line, 1'b1, "IDLE tx_line must be 1 before CASE1");
        expect_signal(tx_busy, 1'b0, "IDLE tx_busy must be 0 before CASE1");

        run_case1_55();

        $display("[%0t] TB_SUMMARY: pass=%0d fail=%0d", $time, pass_count, fail_count);
        if (fail_count == 0)
            $display("[%0t] TB_RESULT: PASS", $time);
        else
            $display("[%0t] TB_RESULT: FAIL", $time);
        $finish;
    end

endmodule

`default_nettype wire
