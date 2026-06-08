`timescale 1ns/1ps
`default_nettype none

module tb_txuartlite_5cases_20260608_003847;

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
    integer idle_errors;
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

    task start_write;
        input [7:0] data;
        input [8*40-1:0] case_name;
        begin
            wait_idle();
            tx_data = data;
            tx_wr   = 1'b1;
            @(posedge tb_clk);
            #1;
            $display("[%0t] TB_CASE: %0s pulse_write tx_data=0x%02h", $time, case_name, data);
            $display("[%0t] TB_INFO: tx_wr=1 tx_data=0x%02h tx_line=%0b tx_busy=%0b", $time, data, tx_line, tx_busy);
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
                tb_fail("tx_busy must stay 1 during transmission");
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
        input [8*40-1:0] case_name;
        begin
            @(negedge tb_clk);
            tx_wr = 1'b0;
            if (tx_line !== 1'b0) begin
                frame_errors = frame_errors + 1;
                tb_fail({case_name, " start bit must be 0"});
                $display("[%0t] TB_INFO: start bit expected 0 actual %0b", $time, tx_line);
            end
            if (tx_busy !== 1'b1) begin
                busy_errors = busy_errors + 1;
                tb_fail({case_name, " tx_busy must be 1 during start bit"});
            end
            @(posedge tb_clk);
            #1;

            for (k = 1; k < CLOCKS_PER_BAUD; k = k + 1)
                sample_bit(1'b0, {case_name, " start bit must stay 0 for one bit period"});
        end
    endtask

    task check_idle_for_bit_periods;
        input integer periods;
        input [8*120-1:0] label;
        integer p;
        integer q;
        begin
            idle_errors = 0;
            for (p = 0; p < periods; p = p + 1) begin
                for (q = 0; q < CLOCKS_PER_BAUD; q = q + 1) begin
                    @(negedge tb_clk);
                    if (tx_line !== 1'b1) begin
                        idle_errors = idle_errors + 1;
                        tb_fail(label);
                        $display("[%0t] TB_INFO: idle expected 1 actual %0b", $time, tx_line);
                    end
                    if (tx_busy !== 1'b0) begin
                        idle_errors = idle_errors + 1;
                        tb_fail(label);
                        $display("[%0t] TB_INFO: idle tx_busy expected 0 actual %0b", $time, tx_busy);
                    end
                    @(posedge tb_clk);
                    #1;
                end
            end
            if (idle_errors == 0)
                tb_pass(label);
        end
    endtask

    task run_normal_case;
        input [7:0] data;
        input [8*40-1:0] case_name;
        integer before_frame_errors;
        integer before_busy_errors;
        begin
            $display("[%0t] TB_PATH: %0s normal transmit start", $time, case_name);
            frame_errors = 0;
            busy_errors  = 0;
            before_frame_errors = frame_errors;
            before_busy_errors  = busy_errors;

            start_write(data, case_name);
            check_start_period_after_write(case_name);

            for (b = 0; b < 8; b = b + 1)
                check_bit_period(data[b], {case_name, " data bits must be LSB first"});

            check_bit_period(1'b1, {case_name, " stop bit must be 1"});

            if (frame_errors == before_frame_errors)
                tb_pass({case_name, " 8N1 frame must match expected bit sequence"});
            if (busy_errors == before_busy_errors)
                tb_pass({case_name, " tx_busy must stay 1 during frame"});

            expect_signal(tx_busy, 1'b0, {case_name, " tx_busy must clear after stop bit"});
            expect_signal(tx_line, 1'b1, {case_name, " tx_line must return to idle high"});
        end
    endtask

    task check_bit_period_with_busy_write;
        input expected_bit;
        input [7:0] busy_data;
        input [8*120-1:0] label;
        begin
            for (k = 0; k < CLOCKS_PER_BAUD; k = k + 1) begin
                @(negedge tb_clk);
                if (k == 0) begin
                    tx_data = busy_data;
                    tx_wr   = 1'b1;
                    $display("[%0t] TB_CASE: CASE5 busy_write_attempt tx_data=0x%02h while tx_busy=%0b", $time, busy_data, tx_busy);
                end else if (k == 1) begin
                    tx_wr = 1'b0;
                end

                if (tx_line !== expected_bit) begin
                    frame_errors = frame_errors + 1;
                    tb_fail(label);
                    $display("[%0t] TB_INFO: expected_tx_line=%0b actual_tx_line=%0b", $time, expected_bit, tx_line);
                end
                if (tx_busy !== 1'b1) begin
                    busy_errors = busy_errors + 1;
                    tb_fail("CASE5 tx_busy must stay 1 during original frame");
                    $display("[%0t] TB_INFO: tx_busy dropped during busy-write test", $time);
                end
                @(posedge tb_clk);
                #1;
            end
            tx_wr = 1'b0;
        end
    endtask

    task run_busy_write_case;
        integer before_frame_errors;
        integer before_busy_errors;
        reg [7:0] original_data;
        reg [7:0] attempted_data;
        begin
            original_data = 8'h55;
            attempted_data = 8'hAA;

            $display("[%0t] TB_PATH: CASE5 busy write ignored start", $time);
            frame_errors = 0;
            busy_errors  = 0;
            before_frame_errors = frame_errors;
            before_busy_errors  = busy_errors;

            start_write(original_data, "CASE5");
            check_start_period_after_write("CASE5");

            check_bit_period(original_data[0], "CASE5 original data bit0 must be preserved");
            check_bit_period(original_data[1], "CASE5 original data bit1 must be preserved");
            check_bit_period_with_busy_write(original_data[2], attempted_data, "CASE5 original data bit2 must remain valid during busy write");

            for (b = 3; b < 8; b = b + 1)
                check_bit_period(original_data[b], "CASE5 remaining original data bits must be preserved");

            check_bit_period(1'b1, "CASE5 stop bit must be 1");

            if (frame_errors == before_frame_errors)
                tb_pass("CASE5 busy write must not alter current 0x55 frame");
            if (busy_errors == before_busy_errors)
                tb_pass("CASE5 tx_busy must stay 1 during original frame");

            expect_signal(tx_busy, 1'b0, "CASE5 tx_busy must clear after original frame");
            expect_signal(tx_line, 1'b1, "CASE5 tx_line must return to idle high after original frame");
            check_idle_for_bit_periods(2, "CASE5 no second frame must start after ignored busy write");
        end
    endtask

    initial begin
        pass_count   = 0;
        fail_count   = 0;
        frame_errors = 0;
        busy_errors  = 0;
        idle_errors  = 0;
        last_state   = 4'hx;
        tx_wr        = 1'b0;
        tx_data      = 8'h00;

        $display("[%0t] TB_PATH: simulation start", $time);

        repeat (3) @(posedge tb_clk);
        #1;
        $display("[%0t] TB_PATH: initial settle done", $time);
        expect_signal(tx_line, 1'b1, "IDLE tx_line must be 1 before tests");
        expect_signal(tx_busy, 1'b0, "IDLE tx_busy must be 0 before tests");

        run_normal_case(8'h00, "CASE1");
        run_normal_case(8'hFF, "CASE2");
        run_normal_case(8'h55, "CASE3");
        run_normal_case(8'hAA, "CASE4");
        run_busy_write_case();

        $display("[%0t] TB_SUMMARY: pass=%0d fail=%0d", $time, pass_count, fail_count);
        if (fail_count == 0)
            $display("[%0t] TB_RESULT: PASS", $time);
        else
            $display("[%0t] TB_RESULT: FAIL", $time);
        $finish;
    end

endmodule

`default_nettype wire
