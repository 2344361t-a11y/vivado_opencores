`timescale 1ns / 100ps

// Revised testbench for OpenCores generic_fifo_sc_a
// Target DUT : generic_fifo_sc_a.v
// Parameters : default values dw=8, aw=8, n=32
// Purpose    : verify reset, FIFO order, full/guard-bit behavior, and clr behavior
// Revision   : expanded log message width to avoid truncated TB_PASS/TB_FAIL strings

module tb_generic_fifo_sc_a_20260616_1449;

    parameter DW = 8;
    parameter AW = 8;
    parameter N  = 32;
    parameter FIFO_DEPTH = (1 << AW);

    reg              clk;
    reg              rst;   // low active reset
    reg              clr;   // high active synchronous clear
    reg  [DW-1:0]    din;
    reg              we;
    wire [DW-1:0]    dout;
    reg              re;
    wire             full;
    wire             empty;
    wire             full_r;
    wire             empty_r;
    wire             full_n;
    wire             empty_n;
    wire             full_n_r;
    wire             empty_n_r;
    wire [1:0]       level;

    integer pass_count;
    integer fail_count;
    integer i;
    integer mismatch_count;

    reg [DW-1:0] case1_data [0:3];

    generic_fifo_sc_a #(DW, AW, N) dut (
        .clk(clk),
        .rst(rst),
        .clr(clr),
        .din(din),
        .we(we),
        .dout(dout),
        .re(re),
        .full(full),
        .empty(empty),
        .full_r(full_r),
        .empty_r(empty_r),
        .full_n(full_n),
        .empty_n(empty_n),
        .full_n_r(full_n_r),
        .empty_n_r(empty_n_r),
        .level(level)
    );

    // 100 MHz clock: 10 ns period
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    task tb_pass;
        input [1023:0] msg;
        begin
            pass_count = pass_count + 1;
            $display("[%0t] TB_PASS: %0s", $time, msg);
        end
    endtask

    task tb_fail;
        input [1023:0] msg;
        begin
            fail_count = fail_count + 1;
            $display("[%0t] TB_FAIL: %0s", $time, msg);
        end
    endtask

    task check_bit;
        input condition;
        input [1023:0] msg;
        begin
            if (condition) tb_pass(msg);
            else           tb_fail(msg);
        end
    endtask

    task check_eq8;
        input [DW-1:0] actual;
        input [DW-1:0] expected;
        input [1023:0] msg;
        begin
            if (actual === expected) begin
                pass_count = pass_count + 1;
                $display("[%0t] TB_PASS: %0s actual=0x%02h expected=0x%02h",
                         $time, msg, actual, expected);
            end else begin
                fail_count = fail_count + 1;
                $display("[%0t] TB_FAIL: %0s actual=0x%02h expected=0x%02h",
                         $time, msg, actual, expected);
            end
        end
    endtask

    task check_eq_int;
        input [31:0] actual;
        input [31:0] expected;
        input [1023:0] msg;
        begin
            if (actual === expected) begin
                pass_count = pass_count + 1;
                $display("[%0t] TB_PASS: %0s actual=%0d expected=%0d",
                         $time, msg, actual, expected);
            end else begin
                fail_count = fail_count + 1;
                $display("[%0t] TB_FAIL: %0s actual=%0d expected=%0d",
                         $time, msg, actual, expected);
            end
        end
    endtask

    task log_state;
        input [1023:0] tag;
        begin
            $display("[%0t] TB_INFO: %0s din=0x%02h dout=0x%02h we=%0b re=%0b full=%0b empty=%0b wp=0x%02h rp=0x%02h gb=%0b cnt=%0d level=%0b",
                     $time, tag, din, dout, we, re, full, empty,
                     dut.wp, dut.rp, dut.gb, dut.cnt, level);
        end
    endtask

    task reset_fifo;
        begin
            $display("[%0t] TB_PATH: reset sequence start", $time);
            rst = 1'b0;
            clr = 1'b0;
            din = {DW{1'b0}};
            we  = 1'b0;
            re  = 1'b0;
            repeat (4) @(posedge clk);
            #2;
            log_state("during reset");

            rst = 1'b1;
            repeat (2) @(posedge clk);
            #2;
            $display("[%0t] TB_PATH: reset released", $time);
            log_state("after reset");
        end
    endtask

    task write_one;
        input [DW-1:0] data;
        input [1023:0] tag;
        begin
            if (full) begin
                tb_fail("write request blocked because FIFO is full before write_one");
            end
            @(negedge clk);
            din = data;
            we  = 1'b1;
            re  = 1'b0;
            $display("[%0t] TB_CASE: %0s write data=0x%02h", $time, tag, data);
            @(posedge clk);
            #2;
            log_state("after write_one");
            @(negedge clk);
            we  = 1'b0;
            din = {DW{1'b0}};
        end
    endtask

    task read_one_check;
        input [DW-1:0] expected;
        input [1023:0] tag;
        begin
            if (empty) begin
                tb_fail("read request blocked because FIFO is empty before read_one_check");
            end
            @(negedge clk);
            re = 1'b1;
            we = 1'b0;
            $display("[%0t] TB_CASE: %0s read expected=0x%02h", $time, tag, expected);
            @(posedge clk);
            #3;
            check_eq8(dout, expected, tag);
            log_state("after read_one_check");
            @(negedge clk);
            re = 1'b0;
        end
    endtask

    task pulse_clr;
        input [1023:0] tag;
        begin
            @(negedge clk);
            clr = 1'b1;
            we  = 1'b0;
            re  = 1'b0;
            din = {DW{1'b0}};
            $display("[%0t] TB_CASE: %0s clr=1", $time, tag);
            @(posedge clk);
            #2;
            log_state("after clr active edge");
            @(negedge clk);
            clr = 1'b0;
            @(posedge clk);
            #2;
            log_state("after clr released");
        end
    endtask

    task check_empty_state;
        input [1023:0] tag;
        begin
            check_bit(empty === 1'b1, {tag, " empty must be 1"});
            check_bit(full  === 1'b0, {tag, " full must be 0"});
            check_bit(dut.wp === dut.rp, {tag, " wp must equal rp"});
            check_bit(dut.gb === 1'b0, {tag, " gb must be 0"});
            check_eq_int(dut.cnt, 0, {tag, " cnt must be 0"});
        end
    endtask

    initial begin
        pass_count = 0;
        fail_count = 0;
        mismatch_count = 0;

        case1_data[0] = 8'h00;
        case1_data[1] = 8'hFF;
        case1_data[2] = 8'hA5;
        case1_data[3] = 8'h5A;

        rst = 1'b1;
        clr = 1'b0;
        din = {DW{1'b0}};
        we  = 1'b0;
        re  = 1'b0;

        $display("[%0t] TB_PATH: simulation start", $time);
        $display("[%0t] TB_INFO: DUT=generic_fifo_sc_a dw=%0d aw=%0d n=%0d depth=%0d",
                 $time, DW, AW, N, FIFO_DEPTH);

        // RESET: initial state check
        reset_fifo();
        check_empty_state("RESET");

        // CASE1: basic FIFO order and data retention check
        $display("[%0t] TB_PATH: CASE1 basic FIFO operation start", $time);
        $display("[%0t] TB_INFO: CASE1 write sequence = 00, FF, A5, 5A", $time);
        for (i = 0; i < 4; i = i + 1) begin
            write_one(case1_data[i], "CASE1");
        end
        check_bit(empty === 1'b0, "CASE1 empty must be 0 after four writes");
        check_bit(full  === 1'b0, "CASE1 full must be 0 after four writes");
        check_eq_int(dut.cnt, 4, "CASE1 cnt must be 4 after four writes");

        for (i = 0; i < 4; i = i + 1) begin
            read_one_check(case1_data[i], "CASE1 read order check");
        end
        check_empty_state("CASE1 after all reads");

        // CASE2: full, guard bit, and empty return check
        $display("[%0t] TB_PATH: CASE2 full guard empty return start", $time);
        $display("[%0t] TB_INFO: CASE2 write din=i[7:0] for i=0..255", $time);

        // Write 256 entries continuously. Do not issue any write after full becomes 1.
        for (i = 0; i < FIFO_DEPTH; i = i + 1) begin
            if (full) begin
                tb_fail("CASE2 full asserted before 256 writes completed");
            end
            @(negedge clk);
            din = i[7:0];
            we  = 1'b1;
            re  = 1'b0;
            if ((i < 4) || (i >= FIFO_DEPTH-4)) begin
                $display("[%0t] TB_CASE: CASE2 write index=%0d data=0x%02h", $time, i, i[7:0]);
            end
            @(posedge clk);
            #2;
        end
        @(negedge clk);
        we  = 1'b0;
        din = {DW{1'b0}};
        @(posedge clk);
        #2;
        log_state("CASE2 after 256 writes");

        check_bit(full  === 1'b1, "CASE2 full must be 1 after 256 writes");
        check_bit(empty === 1'b0, "CASE2 empty must be 0 after 256 writes");
        check_eq_int(dut.cnt, FIFO_DEPTH, "CASE2 cnt must be 256 after 256 writes");
        check_bit(dut.wp === dut.rp, "CASE2 full state wp must equal rp");
        check_bit(dut.gb === 1'b1, "CASE2 full state gb must be 1");

        // Read 256 entries continuously and verify FIFO order.
        mismatch_count = 0;
        for (i = 0; i < FIFO_DEPTH; i = i + 1) begin
            if (empty) begin
                tb_fail("CASE2 empty asserted before 256 reads completed");
            end
            @(negedge clk);
            re = 1'b1;
            we = 1'b0;
            if ((i < 4) || (i >= FIFO_DEPTH-4)) begin
                $display("[%0t] TB_CASE: CASE2 read index=%0d expected=0x%02h", $time, i, i[7:0]);
            end
            @(posedge clk);
            #3;
            if (dout !== i[7:0]) begin
                mismatch_count = mismatch_count + 1;
                if (mismatch_count <= 8) begin
                    $display("[%0t] TB_FAIL: CASE2 read mismatch index=%0d actual=0x%02h expected=0x%02h",
                             $time, i, dout, i[7:0]);
                end
            end
        end
        @(negedge clk);
        re = 1'b0;
        @(posedge clk);
        #2;
        log_state("CASE2 after 256 reads");

        if (mismatch_count == 0) begin
            tb_pass("CASE2 all 256 read values must match write order");
        end else begin
            fail_count = fail_count + mismatch_count;
            $display("[%0t] TB_FAIL: CASE2 total read mismatches=%0d", $time, mismatch_count);
        end

        check_empty_state("CASE2 after all reads");

        // CASE3: synchronous clear check during non-empty state
        $display("[%0t] TB_PATH: CASE3 clr behavior start", $time);
        write_one(8'h11, "CASE3 pre-clear");
        write_one(8'h22, "CASE3 pre-clear");
        write_one(8'h33, "CASE3 pre-clear");
        check_bit(empty === 1'b0, "CASE3 empty must be 0 before clr");
        check_eq_int(dut.cnt, 3, "CASE3 cnt must be 3 before clr");

        pulse_clr("CASE3");
        check_empty_state("CASE3 after clr");

        $display("[%0t] TB_SUMMARY: pass=%0d fail=%0d", $time, pass_count, fail_count);
        if (fail_count == 0) begin
            $display("[%0t] TB_PATH: simulation finished with PASS", $time);
        end else begin
            $display("[%0t] TB_PATH: simulation finished with FAIL", $time);
        end
        $finish;
    end

endmodule
