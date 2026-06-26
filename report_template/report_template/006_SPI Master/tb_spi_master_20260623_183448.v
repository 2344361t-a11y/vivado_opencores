`timescale 1ns/1ps

module tb_spi_master;

    // 10 ns clock period
    reg tb_clk;
    reg tb_rstb;
    reg tb_mlb;
    reg tb_start;
    reg [7:0] tb_tdat;
    reg [1:0] tb_cdiv;
    reg tb_din;

    wire tb_ss;
    wire tb_sck;
    wire tb_dout;
    wire tb_done;
    wire [7:0] tb_rdata;

    integer pass_count;
    integer fail_count;

    // DUT
    spi_master dut (
        .rstb  (tb_rstb),
        .clk   (tb_clk),
        .mlb   (tb_mlb),
        .start (tb_start),
        .tdat  (tb_tdat),
        .cdiv  (tb_cdiv),
        .din   (tb_din),
        .ss    (tb_ss),
        .sck   (tb_sck),
        .dout  (tb_dout),
        .done  (tb_done),
        .rdata (tb_rdata)
    );

    always #5 tb_clk = ~tb_clk;

    function ordered_bit;
        input [7:0] value;
        input bit_order_mlb;
        input integer idx;
        begin
            if (bit_order_mlb == 1'b0)
                ordered_bit = value[idx];      // LSB first
            else
                ordered_bit = value[7-idx];    // MSB first
        end
    endfunction

    task check_cond;
        input condition;
        input [8*96-1:0] message;
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


    task check_case;
        input [8*32-1:0] case_name;
        input condition;
        input [8*80-1:0] message;
        begin
            if (condition) begin
                pass_count = pass_count + 1;
                $display("[%0t] TB_PASS: %0s %0s", $time, case_name, message);
            end else begin
                fail_count = fail_count + 1;
                $display("[%0t] TB_FAIL: %0s %0s", $time, case_name, message);
            end
        end
    endtask

    task print_case_seq;
        input [8*32-1:0] case_name;
        input [8*32-1:0] label_name;
        input [7:0] seq;
        integer j;
        begin
            $write("[%0t] TB_INFO: %0s %0s = ", $time, case_name, label_name);
            for (j = 0; j < 8; j = j + 1) begin
                $write("%0d", seq[j]);
                if (j != 7) $write(",");
            end
            $write("\n");
        end
    endtask

    task print_seq;
        input [8*32-1:0] label_name;
        input [7:0] seq;
        integer j;
        begin
            $write("[%0t] TB_INFO: %0s = ", $time, label_name);
            for (j = 0; j < 8; j = j + 1) begin
                $write("%0d", seq[j]);
                if (j != 7) $write(",");
            end
            $write("\n");
        end
    endtask

    task pulse_start;
        begin
            @(posedge tb_clk);
            #1 tb_start = 1'b1;
            $display("[%0t] TB_CASE: pulse_start tdat=0x%02h mlb=%0d cdiv=%02b", $time, tb_tdat, tb_mlb, tb_cdiv);
            @(posedge tb_clk);
            #1 tb_start = 1'b0;
        end
    endtask

    task pulse_mid_start_with_new_tdat;
        input [7:0] new_tdat;
        begin
            @(posedge tb_clk);
            #1 tb_tdat = new_tdat;
            tb_start = 1'b1;
            $display("[%0t] TB_CASE: mid_start pulse, tdat changed to 0x%02h", $time, new_tdat);
            @(posedge tb_clk);
            #1 tb_start = 1'b0;
        end
    endtask

    task reset_dut;
        begin
            $display("[%0t] TB_PATH: reset sequence start", $time);

            tb_rstb  = 1'b1;
            tb_start = 1'b0;
            tb_mlb   = 1'b0;
            tb_tdat  = 8'h00;
            tb_cdiv  = 2'b00;
            tb_din   = 1'b1;

            #2;
            tb_rstb = 1'b0;
            repeat (4) @(posedge tb_clk);
            #1 tb_rstb = 1'b1;
            $display("[%0t] TB_PATH: reset released", $time);
            repeat (6) @(posedge tb_clk);

            $display("[%0t] TB_DUT_PATH: after reset cur=%0d ss=%0b sck=%0b dout=%0b done=%0b", 
                     $time, dut.cur, tb_ss, tb_sck, tb_dout, tb_done);

            check_cond(tb_ss   === 1'b1, "RESET ss must be 1 in idle");
            check_cond(tb_sck  === 1'b1, "RESET sck must be 1 in SPI mode 3 idle");
            check_cond(tb_dout === 1'b1, "RESET dout must be 1 after clear");
        end
    endtask

    task wait_done_or_timeout;
        input [8*32-1:0] case_name;
        integer timeout_count;
        begin
            timeout_count = 0;
            while ((tb_done !== 1'b1) && (timeout_count < 2000)) begin
                @(posedge tb_clk);
                timeout_count = timeout_count + 1;
            end

            if (tb_done === 1'b1)
                $display("[%0t] TB_INFO: %0s done detected rdata=0x%02h", $time, case_name, tb_rdata);
            else
                $display("[%0t] TB_WARN: %0s timeout while waiting for done", $time, case_name);
        end
    endtask

    task wait_idle_after_done;
        input [8*32-1:0] case_name;
        integer timeout_count;
        begin
            timeout_count = 0;
            while (!((tb_ss === 1'b1) && (tb_sck === 1'b1)) && (timeout_count < 2000)) begin
                @(posedge tb_clk);
                timeout_count = timeout_count + 1;
            end

            $display("[%0t] TB_DUT_PATH: %0s idle check cur=%0d ss=%0b sck=%0b done=%0b nbit=%0d", 
                     $time, case_name, dut.cur, tb_ss, tb_sck, tb_done, dut.nbit);
        end
    endtask

    task run_spi_case;
        input [8*32-1:0] case_name;
        input case_mlb;
        input [1:0] case_cdiv;
        input [7:0] tx_data;
        input [7:0] rx_data;
        input inject_mid_start;
        input check_period;
        input [31:0] expected_sck_period_ns;

        reg [7:0] expected_dout_seq;
        reg [7:0] captured_dout_seq;
        integer i;
        integer timeout_count;
        integer post_idle_cycles;
        reg second_transfer_detected;
        time t1;
        time t2;
        time measured_sck_period;
        event after_two_bits;

        begin
            $display("[%0t] TB_PATH: %0s start", $time, case_name);

            expected_dout_seq = 8'h00;
            captured_dout_seq = 8'h00;
            measured_sck_period = 0;
            second_transfer_detected = 1'b0;

            for (i = 0; i < 8; i = i + 1) begin
                expected_dout_seq[i] = ordered_bit(tx_data, case_mlb, i);
            end

            tb_mlb   = case_mlb;
            tb_cdiv  = case_cdiv;
            tb_tdat  = tx_data;
            tb_din   = 1'b1;
            tb_start = 1'b0;

            repeat (3) @(posedge tb_clk);
            pulse_start();

            timeout_count = 0;
            while ((tb_done !== 1'b0) && (timeout_count < 200)) begin
                @(posedge tb_clk);
                timeout_count = timeout_count + 1;
            end
            check_case(case_name, tb_done === 1'b0, "done must clear after start");

            wait (tb_ss === 1'b0);
            $display("[%0t] TB_INFO: %0s ss active low detected", $time, case_name);
            check_case(case_name, tb_ss === 1'b0, "ss must be 0 during transfer");

            fork
                begin : MONITOR_AND_DRIVE
                    for (i = 0; i < 8; i = i + 1) begin
                        @(negedge tb_sck);
                        #1;
                        captured_dout_seq[i] = tb_dout;
                        tb_din = ordered_bit(rx_data, case_mlb, i);
                        $display("[%0t] TB_INFO: %0s bit%0d dout=%0b din_set=%0b nbit=%0d", 
                                 $time, case_name, i, tb_dout, tb_din, dut.nbit);

                        if (i == 1) begin
                            -> after_two_bits;
                        end
                    end
                end

                begin : MID_START_WORKER
                    if (inject_mid_start == 1'b1) begin
                        @(after_two_bits);
                        pulse_mid_start_with_new_tdat(8'hFF);
                    end
                end

                begin : PERIOD_WORKER
                    if (check_period == 1'b1) begin
                        @(posedge tb_sck);
                        t1 = $time;
                        @(posedge tb_sck);
                        t2 = $time;
                        measured_sck_period = t2 - t1;
                        $display("[%0t] TB_INFO: %0s measured_sck_period=%0t", $time, case_name, measured_sck_period);
                    end
                end
            join

            wait_done_or_timeout(case_name);

            print_case_seq(case_name, "expected_dout", expected_dout_seq);
            print_case_seq(case_name, "captured_dout", captured_dout_seq);

            check_case(case_name, captured_dout_seq === expected_dout_seq, "dout bit order must match tdat");
            check_case(case_name, tb_done === 1'b1, "done must be 1 after 8bit transfer");
            check_case(case_name, tb_rdata === rx_data, "rdata must match received din sequence");

            if (check_period == 1'b1) begin
                check_case(case_name, measured_sck_period == expected_sck_period_ns,
                           "sck period must match cdiv setting");
            end

            wait_idle_after_done(case_name);
            check_case(case_name, tb_ss === 1'b1, "ss must return to 1 after transfer");
            check_case(case_name, tb_sck === 1'b1, "sck must return to 1 after transfer");

            if (inject_mid_start == 1'b1) begin
                check_case(case_name, captured_dout_seq === expected_dout_seq,
                           "mid-start must not change current transfer");

                // The SPI master does not queue start requests received while
                // a transfer is active. Observe the idle period long enough
                // to catch a complete cdiv=00 transfer if one were started.
                for (post_idle_cycles = 0; post_idle_cycles < 40; post_idle_cycles = post_idle_cycles + 1) begin
                    @(posedge tb_clk);
                    #1;
                    if (tb_ss !== 1'b1)
                        second_transfer_detected = 1'b1;
                end
                $display("[%0t] TB_INFO: %0s post_mid_start_second_transfer=%0b",
                         $time, case_name, second_transfer_detected);
                check_case(case_name, second_transfer_detected === 1'b0,
                           "mid-start must not start a second transfer after completion");
            end

            repeat (5) @(posedge tb_clk);
        end
    endtask

    initial begin
        $timeformat(-9, 0, " ns", 10);

        tb_clk = 1'b0;
        tb_rstb = 1'b1;
        tb_mlb = 1'b0;
        tb_start = 1'b0;
        tb_tdat = 8'h00;
        tb_cdiv = 2'b00;
        tb_din = 1'b1;
        pass_count = 0;
        fail_count = 0;

        $display("[%0t] TB_PATH: simulation start", $time);

        reset_dut();

        // CASE1: LSB first basic transfer, cdiv=00 -> sck period = 40 ns when clk period is 10 ns
        run_spi_case("CASE1", 1'b0, 2'b00, 8'h96, 8'h3C, 1'b0, 1'b1, 40);

        // CASE2: MSB first basic transfer
        run_spi_case("CASE2", 1'b1, 2'b00, 8'h96, 8'h3C, 1'b0, 1'b0, 0);

        // CASE3: clock divider check, cdiv=01 -> sck period = 80 ns when clk period is 10 ns
        run_spi_case("CASE3", 1'b0, 2'b01, 8'h96, 8'h3C, 1'b0, 1'b1, 80);

        // CASE4: start pulse during active transfer must not break the current transfer
        run_spi_case("CASE4", 1'b0, 2'b00, 8'h96, 8'h3C, 1'b1, 1'b0, 0);

        $display("[%0t] TB_SUMMARY: pass=%0d fail=%0d", $time, pass_count, fail_count);

        if (fail_count == 0)
            $display("[%0t] TB_RESULT: PASS", $time);
        else
            $display("[%0t] TB_RESULT: FAIL", $time);

        #100;
        $finish;
    end

endmodule
