`timescale 1ns/1ps
`default_nettype none

module tb_txuartlite;

    localparam integer CLK_PERIOD_NS   = 10;
    localparam [4:0]   TIMING_BITS_TB  = 5'd5;
    localparam [4:0]   CLOCKS_PER_BAUD = 5'd10;

    reg         i_clk;
    reg         i_wr;
    reg  [7:0]  i_data;
    wire        o_uart_tx;
    wire        o_busy;

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
        .i_clk(i_clk),
        .i_wr(i_wr),
        .i_data(i_data),
        .o_uart_tx(o_uart_tx),
        .o_busy(o_busy)
    );

    initial begin
        i_clk = 1'b0;
        forever #(CLK_PERIOD_NS/2) i_clk = ~i_clk;
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

    always @(posedge i_clk) begin
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
            else
                tb_fail(msg);
        end
    endtask

    task wait_idle;
        begin
            while (o_busy !== 1'b0)
                @(posedge i_clk);
            @(negedge i_clk);
        end
    endtask

    task start_write;
        input [7:0] data;
        begin
            wait_idle();
            i_data = data;
            i_wr   = 1'b1;
            @(posedge i_clk);
            #1;
            $display("[%0t] TB_CASE: pulse_write data=0x%02h", $time, data);
            $display("[%0t] TB_INFO: accepted i_wr=1 i_data=0x%02h o_uart_tx=%0b o_busy=%0b", $time, data, o_uart_tx, o_busy);
        end
    endtask

    task sample_bit;
        input expected_bit;
        input [8*120-1:0] label;
        begin
            @(negedge i_clk);
            if (o_uart_tx !== expected_bit) begin
                frame_errors = frame_errors + 1;
                tb_fail(label);
                $display("[%0t] TB_INFO: expected_tx=%0b actual_tx=%0b", $time, expected_bit, o_uart_tx);
            end
            if (o_busy !== 1'b1) begin
                busy_errors = busy_errors + 1;
                tb_fail("o_busy must stay 1 during transmission");
                $display("[%0t] TB_INFO: o_busy dropped during frame", $time);
            end
            @(posedge i_clk);
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

    task check_bit_period_with_busy_write;
        input expected_bit;
        input [7:0] busy_data;
        input [8*120-1:0] label;
        begin
            for (k = 0; k < CLOCKS_PER_BAUD; k = k + 1) begin
                @(negedge i_clk);
                if (k == 0) begin
                    i_data = busy_data;
                    i_wr   = 1'b1;
                    $display("[%0t] TB_CASE: busy_write_attempt data=0x%02h while o_busy=%0b", $time, busy_data, o_busy);
                end else if (k == 1) begin
                    i_wr = 1'b0;
                end

                if (o_uart_tx !== expected_bit) begin
                    frame_errors = frame_errors + 1;
                    tb_fail(label);
                    $display("[%0t] TB_INFO: expected_tx=%0b actual_tx=%0b", $time, expected_bit, o_uart_tx);
                end
                if (o_busy !== 1'b1) begin
                    busy_errors = busy_errors + 1;
                    tb_fail("o_busy must stay 1 during transmission");
                    $display("[%0t] TB_INFO: o_busy dropped during frame", $time);
                end
                @(posedge i_clk);
                #1;
            end
            i_wr = 1'b0;
        end
    endtask

    task check_start_period_after_write;
        input [8*120-1:0] label;
        begin
            // Deassert i_wr after one clock while also sampling the first half of the start bit.
            @(negedge i_clk);
            i_wr = 1'b0;
            if (o_uart_tx !== 1'b0) begin
                frame_errors = frame_errors + 1;
                tb_fail(label);
                $display("[%0t] TB_INFO: start bit expected 0 actual %0b", $time, o_uart_tx);
            end
            if (o_busy !== 1'b1) begin
                busy_errors = busy_errors + 1;
                tb_fail("o_busy must be 1 during start bit");
            end
            @(posedge i_clk);
            #1;

            for (k = 1; k < CLOCKS_PER_BAUD; k = k + 1)
                sample_bit(1'b0, label);
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
                    @(negedge i_clk);
                    if (o_uart_tx !== 1'b1) begin
                        idle_errors = idle_errors + 1;
                        tb_fail(label);
                        $display("[%0t] TB_INFO: idle expected 1 actual %0b", $time, o_uart_tx);
                    end
                    @(posedge i_clk);
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

            start_write(data);
            check_start_period_after_write({case_name, " start bit must be 0"});

            for (b = 0; b < 8; b = b + 1)
                check_bit_period(data[b], {case_name, " data bits must be LSB first"});

            check_bit_period(1'b1, {case_name, " stop bit must be 1"});

            if (frame_errors == before_frame_errors)
                tb_pass({case_name, " 8N1 frame must match expected bit sequence"});
            if (busy_errors == before_busy_errors)
                tb_pass({case_name, " o_busy must stay 1 during frame"});

            expect_signal(o_busy, 1'b0, {case_name, " o_busy must clear after stop bit"});
            expect_signal(o_uart_tx, 1'b1, {case_name, " o_uart_tx must return to idle high"});
        end
    endtask

    task run_busy_ignore_case;
        integer before_frame_errors;
        integer before_busy_errors;
        begin
            $display("[%0t] TB_PATH: CASE4 busy write ignored start", $time);
            frame_errors = 0;
            busy_errors  = 0;
            before_frame_errors = frame_errors;
            before_busy_errors  = busy_errors;

            start_write(8'hA5);
            check_start_period_after_write("CASE4 original start bit must be 0");

            // Check bit0 and bit1 of 0xA5, then try another write while busy during bit2.
            check_bit_period(1'b1, "CASE4 original data bit0 must be 1");
            check_bit_period(1'b0, "CASE4 original data bit1 must be 0");
            check_bit_period_with_busy_write(1'b1, 8'h3C, "CASE4 original data bit2 must remain 1 during busy write");

            // Continue checking that the transmitted frame is still 0xA5.
            check_bit_period(1'b0, "CASE4 original data bit3 must remain 0");
            check_bit_period(1'b0, "CASE4 original data bit4 must remain 0");
            check_bit_period(1'b1, "CASE4 original data bit5 must remain 1");
            check_bit_period(1'b0, "CASE4 original data bit6 must remain 0");
            check_bit_period(1'b1, "CASE4 original data bit7 must remain 1");
            check_bit_period(1'b1, "CASE4 stop bit must be 1");

            if (frame_errors == before_frame_errors)
                tb_pass("CASE4 busy write must not alter current 0xA5 frame");
            if (busy_errors == before_busy_errors)
                tb_pass("CASE4 o_busy must stay 1 during original frame");

            expect_signal(o_busy, 1'b0, "CASE4 o_busy must clear after original frame");
            check_idle_for_bit_periods(2, "CASE4 no second frame must start after ignored busy write");
        end
    endtask

    initial begin
        pass_count = 0;
        fail_count = 0;
        frame_errors = 0;
        busy_errors = 0;
        idle_errors = 0;
        last_state = 4'hx;
        i_wr = 1'b0;
        i_data = 8'h00;

        $display("[%0t] TB_PATH: simulation start", $time);

        repeat (3) @(posedge i_clk);
        #1;
        $display("[%0t] TB_PATH: initial settle done", $time);
        expect_signal(o_uart_tx, 1'b1, "CASE0 idle o_uart_tx must be 1");
        expect_signal(o_busy, 1'b0, "CASE0 idle o_busy must be 0");

        run_normal_case(8'h55, "CASE1");
        run_normal_case(8'h00, "CASE2");
        run_normal_case(8'hff, "CASE3");
        run_busy_ignore_case();

        $display("[%0t] TB_SUMMARY: pass=%0d fail=%0d", $time, pass_count, fail_count);
        if (fail_count == 0)
            $display("[%0t] TB_RESULT: PASS", $time);
        else
            $display("[%0t] TB_RESULT: FAIL", $time);
        $finish;
    end

endmodule

`default_nettype wire
