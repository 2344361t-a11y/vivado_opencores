`timescale 1ns/1ps

module tb_spi_slave;

    reg        tb_rstb;
    reg        tb_ten;
    reg [7:0]  tb_tdata;
    reg        tb_mlb;
    reg        tb_ss;
    reg        tb_sck;
    reg        tb_sdin;

    wire       tb_sdout;
    wire       tb_done;
    wire [7:0] tb_rdata;

    integer pass_count;
    integer fail_count;

    spi_slave dut (
        .rstb  (tb_rstb),
        .ten   (tb_ten),
        .tdata (tb_tdata),
        .mlb   (tb_mlb),
        .ss    (tb_ss),
        .sck   (tb_sck),
        .sdin  (tb_sdin),
        .sdout (tb_sdout),
        .done  (tb_done),
        .rdata (tb_rdata)
    );

    function ordered_bit;
        input [7:0] value;
        input bit_order_mlb;
        input integer index;
        begin
            if (bit_order_mlb == 1'b0)
                ordered_bit = value[index];
            else
                ordered_bit = value[7-index];
        end
    endfunction

    task tb_pass;
        input [8*120-1:0] message;
        begin
            pass_count = pass_count + 1;
            $display("[%0t] TB_PASS: %0s", $time, message);
        end
    endtask

    task tb_fail;
        input [8*120-1:0] message;
        begin
            fail_count = fail_count + 1;
            $display("[%0t] TB_FAIL: %0s", $time, message);
        end
    endtask

    task check_bit;
        input actual;
        input expected;
        input [8*120-1:0] message;
        begin
            if (actual === expected) begin
                tb_pass(message);
            end else begin
                $display("[%0t] TB_INFO: expected=%b actual=%b", $time, expected, actual);
                tb_fail(message);
            end
        end
    endtask

    task check_data;
        input [7:0] actual;
        input [7:0] expected;
        input [8*120-1:0] message;
        begin
            if (actual === expected) begin
                tb_pass(message);
            end else begin
                $display("[%0t] TB_INFO: expected=0x%02h actual=0x%02h", $time, expected, actual);
                tb_fail(message);
            end
        end
    endtask

    task check_tristate;
        input value;
        input [8*120-1:0] message;
        begin
            if (value === 1'bz) begin
                tb_pass(message);
            end else begin
                $display("[%0t] TB_INFO: expected=Z actual=%b", $time, value);
                tb_fail(message);
            end
        end
    endtask

    task print_case_seq;
        input [8*32-1:0] case_name;
        input [8*32-1:0] label_name;
        input [7:0] sequence;
        integer j;
        begin
            $write("[%0t] TB_INFO: %0s %0s = ", $time, case_name, label_name);
            for (j = 0; j < 8; j = j + 1) begin
                $write("%0d", sequence[j]);
                if (j != 7) $write(",");
            end
            $write("\n");
        end
    endtask

    task reset_dut;
        begin
            $display("[%0t] TB_PATH: reset sequence start", $time);
            tb_ss    = 1'b1;
            tb_sck   = 1'b1;
            tb_ten   = 1'b1;
            tb_tdata = 8'h00;
            tb_mlb   = 1'b0;
            tb_sdin  = 1'b0;
            tb_rstb  = 1'b1;

            #2 tb_rstb = 1'b0;
            #20 tb_rstb = 1'b1;
            #2;

            $display("[%0t] TB_PATH: reset released", $time);
            $display("[%0t] TB_DUT_PATH: after reset nb=%0d done=%0b rdata=0x%02h sdout=%b",
                     $time, dut.nb, tb_done, tb_rdata, tb_sdout);
            check_bit(tb_done, 1'b0, "RESET done must be 0");
            check_data(tb_rdata, 8'h00, "RESET rdata must be 0x00");
            check_tristate(tb_sdout, "RESET sdout must be Z while ss is 1");
        end
    endtask

    task run_active_transfer;
        input [8*32-1:0] case_name;
        input case_mlb;
        input case_ten;
        input [7:0] slave_data;
        input [7:0] master_data;

        reg [7:0] expected_sdout_seq;
        reg [7:0] captured_sdout_seq;
        reg tristate_ok;
        integer i;
        begin
            $display("[%0t] TB_PATH: %0s start", $time, case_name);

            expected_sdout_seq = 8'h00;
            captured_sdout_seq = 8'h00;
            tristate_ok = 1'b1;
            for (i = 0; i < 8; i = i + 1)
                expected_sdout_seq[i] = ordered_bit(slave_data, case_mlb, i);

            tb_ss    = 1'b1;
            tb_sck   = 1'b1;
            tb_ten   = case_ten;
            tb_tdata = slave_data;
            tb_mlb   = case_mlb;
            tb_sdin  = 1'b0;
            #10;

            tb_ss = 1'b0;
            $display("[%0t] TB_CASE: %0s select slave ten=%0b mlb=%0b tdata=0x%02h master_data=0x%02h",
                     $time, case_name, case_ten, case_mlb, slave_data, master_data);

            for (i = 0; i < 8; i = i + 1) begin
                #10 tb_sck = 1'b0;
                #1;
                tb_sdin = ordered_bit(master_data, case_mlb, i);

                if (case_ten == 1'b1)
                    captured_sdout_seq[i] = tb_sdout;
                else if (tb_sdout !== 1'bz)
                    tristate_ok = 1'b0;

                $display("[%0t] TB_INFO: %0s bit%0d sdout=%b sdin_set=%b nb=%0d",
                         $time, case_name, i, tb_sdout, tb_sdin, dut.nb);

                #9 tb_sck = 1'b1;
                #1;
                if (i == 0)
                    check_bit(tb_done, 1'b0, {case_name, " done must clear after first sampled bit"});
            end

            if (case_ten == 1'b1) begin
                print_case_seq(case_name, "expected_sdout", expected_sdout_seq);
                print_case_seq(case_name, "captured_sdout", captured_sdout_seq);
                if (captured_sdout_seq === expected_sdout_seq)
                    tb_pass({case_name, " sdout bit order must match tdata"});
                else begin
                    $display("[%0t] TB_INFO: %0s sdout sequence mismatch", $time, case_name);
                    tb_fail({case_name, " sdout bit order must match tdata"});
                end
            end else begin
                if (tristate_ok == 1'b1)
                    tb_pass({case_name, " sdout must remain Z while ten is 0"});
                else
                    tb_fail({case_name, " sdout must remain Z while ten is 0"});
            end

            check_data(tb_rdata, master_data, {case_name, " rdata must match master serial input"});
            check_bit(tb_done, 1'b1, {case_name, " done must be 1 after 8bit transfer"});
            $display("[%0t] TB_DUT_PATH: %0s transfer complete nb=%0d done=%0b rdata=0x%02h",
                     $time, case_name, dut.nb, tb_done, tb_rdata);

            #10 tb_ss = 1'b1;
            #1;
            check_tristate(tb_sdout, {case_name, " sdout must return to Z after slave deselect"});
            #20;
        end
    endtask

    task run_ss_inactive_case;
        reg [7:0] rdata_before;
        reg done_before;
        reg tristate_ok;
        integer i;
        begin
            $display("[%0t] TB_PATH: CASE4 start", $time);

            // Reset establishes the state that must remain unchanged while ss=1.
            tb_ss    = 1'b1;
            tb_sck   = 1'b1;
            tb_ten   = 1'b1;
            tb_tdata = 8'h96;
            tb_mlb   = 1'b0;
            tb_sdin  = 1'b0;
            #2 tb_rstb = 1'b0;
            #20 tb_rstb = 1'b1;
            #2;

            rdata_before = tb_rdata;
            done_before = tb_done;
            tristate_ok = 1'b1;
            $display("[%0t] TB_CASE: CASE4 apply 8 sck cycles with ss=1", $time);

            for (i = 0; i < 8; i = i + 1) begin
                #10 tb_sck = 1'b0;
                #1;
                tb_sdin = ordered_bit(8'h53, 1'b0, i);
                if (tb_sdout !== 1'bz)
                    tristate_ok = 1'b0;
                $display("[%0t] TB_INFO: CASE4 bit%0d sdout=%b sdin_set=%b nb=%0d",
                         $time, i, tb_sdout, tb_sdin, dut.nb);
                #9 tb_sck = 1'b1;
                #1;
            end

            if (tristate_ok == 1'b1)
                tb_pass("CASE4 sdout must remain Z while ss is 1");
            else
                tb_fail("CASE4 sdout must remain Z while ss is 1");
            check_data(tb_rdata, rdata_before, "CASE4 rdata must not change while ss is 1");
            check_bit(tb_done, done_before, "CASE4 done must not change while ss is 1");
            $display("[%0t] TB_DUT_PATH: CASE4 complete nb=%0d done=%0b rdata=0x%02h",
                     $time, dut.nb, tb_done, tb_rdata);
            #20;
        end
    endtask

    initial begin
        $timeformat(-9, 0, " ns", 10);

        tb_rstb = 1'b1;
        tb_ten = 1'b0;
        tb_tdata = 8'h00;
        tb_mlb = 1'b0;
        tb_ss = 1'b1;
        tb_sck = 1'b1;
        tb_sdin = 1'b0;
        pass_count = 0;
        fail_count = 0;

        $display("[%0t] TB_PATH: simulation start", $time);

        reset_dut();

        // CASE1: LSB first. 0x96 and 0x53 are not bit-order symmetric.
        run_active_transfer("CASE1", 1'b0, 1'b1, 8'h96, 8'h53);

        // CASE2: MSB first with the same byte values for direct comparison.
        run_active_transfer("CASE2", 1'b1, 1'b1, 8'h96, 8'h53);

        // CASE3: ten only controls sdout; reception must still work.
        run_active_transfer("CASE3", 1'b0, 1'b0, 8'h96, 8'h3A);

        // CASE4: an unselected slave must not drive or update state.
        run_ss_inactive_case();

        $display("[%0t] TB_SUMMARY: pass=%0d fail=%0d", $time, pass_count, fail_count);
        if (fail_count == 0)
            $display("[%0t] TB_RESULT: PASS", $time);
        else
            $display("[%0t] TB_RESULT: FAIL", $time);

        #20;
        $finish;
    end

endmodule
