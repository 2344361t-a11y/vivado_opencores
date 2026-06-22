`include "timescale.v"

module tb_generic_fifo_dc;

    localparam DW = 8;
    localparam AW = 8;
    localparam DEPTH = (1 << AW);
    localparam [AW:0] PTR_ZERO = {(AW+1){1'b0}};

    reg              rd_clk;
    reg              wr_clk;
    reg              rst;
    reg              clr;
    reg  [DW-1:0]    din;
    reg              we;
    wire [DW-1:0]    dout;
    reg              re;
    wire             full;
    wire             empty;
    wire             full_n;
    wire             empty_n;
    wire [1:0]       level;

    integer pass_count;
    integer fail_count;
    integer i;

    // Default parameter values of generic_fifo_dc are used.
    generic_fifo_dc dut (
        .rd_clk (rd_clk),
        .wr_clk (wr_clk),
        .rst    (rst),
        .clr    (clr),
        .din    (din),
        .we     (we),
        .dout   (dout),
        .re     (re),
        .full   (full),
        .empty  (empty),
        .full_n (full_n),
        .empty_n(empty_n),
        .level  (level)
    );

    // Different clock periods are used to model dual-clock FIFO behavior.
    initial begin
        wr_clk = 1'b0;
        forever #5 wr_clk = ~wr_clk;      // 10 ns period
    end

    initial begin
        rd_clk = 1'b0;
        forever #7 rd_clk = ~rd_clk;      // 14 ns period
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
        input actual;
        input expected;
        input [1023:0] msg;
        begin
            if (actual === expected) begin
                tb_pass(msg);
            end else begin
                $display("[%0t] TB_INFO: expected=%b actual=%b", $time, expected, actual);
                tb_fail(msg);
            end
        end
    endtask

    task check_data;
        input [DW-1:0] actual;
        input [DW-1:0] expected;
        input [1023:0] msg;
        begin
            if (actual === expected) begin
                tb_pass(msg);
            end else begin
                $display("[%0t] TB_INFO: expected=0x%02h actual=0x%02h", $time, expected, actual);
                tb_fail(msg);
            end
        end
    endtask

    task check_ptr;
        input [AW:0] actual;
        input [AW:0] expected;
        input [1023:0] msg;
        begin
            if (actual === expected) begin
                tb_pass(msg);
            end else begin
                $display("[%0t] TB_INFO: expected=%0d actual=%0d", $time, expected, actual);
                tb_fail(msg);
            end
        end
    endtask

    task wait_wr_cycles;
        input integer cycles;
        integer k;
        begin
            for (k = 0; k < cycles; k = k + 1) begin
                @(posedge wr_clk);
            end
            #2;
        end
    endtask

    task wait_rd_cycles;
        input integer cycles;
        integer k;
        begin
            for (k = 0; k < cycles; k = k + 1) begin
                @(posedge rd_clk);
            end
            #2;
        end
    endtask

    task wait_status_settle;
        begin
            wait_wr_cycles(4);
            wait_rd_cycles(4);
        end
    endtask

    task wait_full_value;
        input expected;
        input [1023:0] msg;
        integer timeout;
        begin
            timeout = 0;
            while ((full !== expected) && (timeout < 50)) begin
                @(posedge wr_clk);
                #2;
                timeout = timeout + 1;
            end
            check_bit(full, expected, msg);
        end
    endtask

    task wait_empty_value;
        input expected;
        input [1023:0] msg;
        integer timeout;
        begin
            timeout = 0;
            while ((empty !== expected) && (timeout < 50)) begin
                @(posedge rd_clk);
                #2;
                timeout = timeout + 1;
            end
            check_bit(empty, expected, msg);
        end
    endtask

    task write_one;
        input [DW-1:0] data;
        begin
            if (full === 1'b1) begin
                tb_fail("write_one called while full=1");
            end
            @(negedge wr_clk);
            din = data;
            we  = 1'b1;
            @(posedge wr_clk);
            #2;
            $display("[%0t] TB_INFO: write data=0x%02h wp=%0d rp_s=%0d full=%b empty=%b level=%b",
                     $time, data, dut.wp, dut.rp_s, full, empty, level);
            @(negedge wr_clk);
            we  = 1'b0;
            din = {DW{1'b0}};
            #1;
        end
    endtask

    task read_check;
        input [DW-1:0] expected;
        input [1023:0] msg;
        begin
            if (empty === 1'b1) begin
                tb_fail("read_check called while empty=1");
            end
            @(negedge rd_clk);
            re = 1'b1;
            @(posedge rd_clk);
            #2;
            $display("[%0t] TB_INFO: read expected=0x%02h dout=0x%02h rp=%0d wp_s=%0d full=%b empty=%b level=%b",
                     $time, expected, dout, dut.rp, dut.wp_s, full, empty, level);
            check_data(dout, expected, msg);
            @(negedge rd_clk);
            re = 1'b0;
            #1;
        end
    endtask

    task pulse_clr;
        begin
            $display("[%0t] TB_CASE: pulse_clr start", $time);
            @(negedge wr_clk);
            clr = 1'b1;
            wait_wr_cycles(4);
            wait_rd_cycles(4);
            @(negedge wr_clk);
            clr = 1'b0;
            wait_status_settle();
            $display("[%0t] TB_INFO: clr done wp=%0d rp=%0d full=%b empty=%b level=%b",
                     $time, dut.wp, dut.rp, full, empty, level);
        end
    endtask

    task reset_sequence;
        begin
            $display("[%0t] TB_PATH: reset sequence start", $time);
            rst = 1'b0;
            clr = 1'b0;
            din = {DW{1'b0}};
            we  = 1'b0;
            re  = 1'b0;
            wait_status_settle();
            rst = 1'b1;
            $display("[%0t] TB_PATH: reset released", $time);
            wait_status_settle();
            $display("[%0t] TB_INFO: after reset wp=%0d rp=%0d wp_s=%0d rp_s=%0d full=%b empty=%b full_n=%b empty_n=%b level=%b",
                     $time, dut.wp, dut.rp, dut.wp_s, dut.rp_s, full, empty, full_n, empty_n, level);
        end
    endtask

    initial begin
        pass_count = 0;
        fail_count = 0;
        rst = 1'b1;
        clr = 1'b0;
        din = {DW{1'b0}};
        we  = 1'b0;
        re  = 1'b0;

        $display("[%0t] TB_PATH: simulation start", $time);

        reset_sequence();

        // RESET: initial state check
        $display("[%0t] TB_PATH: RESET initial state check start", $time);
        check_ptr(dut.wp, PTR_ZERO, "RESET wp must be 0");
        check_ptr(dut.rp, PTR_ZERO, "RESET rp must be 0");
        check_bit(full,  1'b0, "RESET full must be 0");
        check_bit(empty, 1'b1, "RESET empty must be 1");
        $display("[%0t] TB_PATH: RESET initial state check end", $time);

        // CASE1: basic FIFO operation
        $display("[%0t] TB_PATH: CASE1 basic FIFO operation start", $time);
        write_one(8'h11);
        write_one(8'h22);
        write_one(8'h33);
        write_one(8'h44);
        wait_empty_value(1'b0, "CASE1 empty must become 0 after writes");
        wait_full_value(1'b0, "CASE1 full must remain 0");
        read_check(8'h11, "CASE1 read data must be 0x11");
        read_check(8'h22, "CASE1 read data must be 0x22");
        read_check(8'h33, "CASE1 read data must be 0x33");
        read_check(8'h44, "CASE1 read data must be 0x44");
        wait_empty_value(1'b1, "CASE1 empty must return to 1 after all reads");
        $display("[%0t] TB_PATH: CASE1 basic FIFO operation end", $time);

        // CASE2: full and empty recovery check
        $display("[%0t] TB_PATH: CASE2 full/empty recovery start", $time);
        for (i = 0; i < DEPTH; i = i + 1) begin
            write_one(i[7:0]);
        end
        wait_full_value(1'b1, "CASE2 full must become 1 after 256 writes");
        check_bit(dut.wp[AW] != dut.rp[AW], 1'b1, "CASE2 pointer upper bits must differ at full");
        read_check(8'h00, "CASE2 first read after full must be 0x00");
        wait_full_value(1'b0, "CASE2 full must return to 0 after one read");
        write_one(8'hA5);
        wait_empty_value(1'b0, "CASE2 empty must remain 0 before remaining reads");
        for (i = 1; i < DEPTH; i = i + 1) begin
            read_check(i[7:0], "CASE2 remaining read data must match counter pattern");
        end
        read_check(8'hA5, "CASE2 last read data must be additional 0xA5");
        wait_empty_value(1'b1, "CASE2 empty must become 1 after all reads");
        wait_full_value(1'b0, "CASE2 full must remain 0 after empty recovery");
        $display("[%0t] TB_PATH: CASE2 full/empty recovery end", $time);

        // CASE3: clear check
        $display("[%0t] TB_PATH: CASE3 clr clear check start", $time);
        write_one(8'h5A);
        write_one(8'hC3);
        write_one(8'h3C);
        write_one(8'hA5);
        wait_empty_value(1'b0, "CASE3 empty must become 0 before clr");
        pulse_clr();
        check_ptr(dut.wp, PTR_ZERO, "CASE3 wp must be 0 after clr");
        check_ptr(dut.rp, PTR_ZERO, "CASE3 rp must be 0 after clr");
        check_bit(full,  1'b0, "CASE3 full must be 0 after clr");
        check_bit(empty, 1'b1, "CASE3 empty must be 1 after clr");
        $display("[%0t] TB_PATH: CASE3 clr clear check end", $time);

        $display("[%0t] TB_SUMMARY: pass=%0d fail=%0d", $time, pass_count, fail_count);
        if (fail_count == 0) begin
            $display("[%0t] TB_PATH: simulation finished PASS", $time);
        end else begin
            $display("[%0t] TB_PATH: simulation finished FAIL", $time);
        end
        $finish;
    end

endmodule
