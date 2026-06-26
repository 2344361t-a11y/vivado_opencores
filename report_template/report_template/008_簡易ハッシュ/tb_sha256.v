`timescale 1ns/1ps

module tb_sha256;

    reg         tb_clk_i;
    reg         tb_rst_i;
    reg  [31:0] tb_text_i;
    wire [31:0] tb_text_o;
    reg  [2:0]  tb_cmd_i;
    reg         tb_cmd_w_i;
    wire [3:0]  tb_cmd_o;

    integer pass_count;
    integer fail_count;

    localparam [511:0] BLOCK_EMPTY = {
        32'h80000000, 32'h00000000, 32'h00000000, 32'h00000000,
        32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000,
        32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000,
        32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000
    };

    localparam [511:0] BLOCK_ABC = {
        32'h61626380, 32'h00000000, 32'h00000000, 32'h00000000,
        32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000,
        32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000,
        32'h00000000, 32'h00000000, 32'h00000000, 32'h00000018
    };

    localparam [511:0] BLOCK_LONG_0 = {
        32'h61626364, 32'h62636465, 32'h63646566, 32'h64656667,
        32'h65666768, 32'h66676869, 32'h6768696a, 32'h68696a6b,
        32'h696a6b6c, 32'h6a6b6c6d, 32'h6b6c6d6e, 32'h6c6d6e6f,
        32'h6d6e6f70, 32'h6e6f7071, 32'h80000000, 32'h00000000
    };

    localparam [511:0] BLOCK_LONG_1 = {
        32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000,
        32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000,
        32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000,
        32'h00000000, 32'h00000000, 32'h00000000, 32'h000001c0
    };

    localparam [255:0] DIGEST_EMPTY =
        256'he3b0c442_98fc1c14_9afbf4c8_996fb924_27ae41e4_649b934c_a495991b_7852b855;

    localparam [255:0] DIGEST_ABC =
        256'hba7816bf_8f01cfea_414140de_5dae2223_b00361a3_96177a9c_b410ff61_f20015ad;

    localparam [255:0] DIGEST_LONG =
        256'h248d6a61_d20638b8_e5c02693_0c3e6039_a33ce459_64ff2167_f6ecedd4_19db06c1;

    sha256 dut (
        .clk_i   (tb_clk_i),
        .rst_i   (tb_rst_i),
        .text_i  (tb_text_i),
        .text_o  (tb_text_o),
        .cmd_i   (tb_cmd_i),
        .cmd_w_i (tb_cmd_w_i),
        .cmd_o   (tb_cmd_o)
    );

    always #5 tb_clk_i = ~tb_clk_i;

    task tb_pass;
        input [8*160-1:0] message;
        begin
            pass_count = pass_count + 1;
            $display("[%0t] TB_PASS: %0s", $time, message);
        end
    endtask

    task tb_fail;
        input [8*160-1:0] message;
        begin
            fail_count = fail_count + 1;
            $display("[%0t] TB_FAIL: %0s", $time, message);
        end
    endtask

    task check_bit;
        input actual;
        input expected;
        input [8*160-1:0] message;
        begin
            if (actual === expected) begin
                tb_pass(message);
            end else begin
                $display("[%0t] TB_INFO: expected=%b actual=%b", $time, expected, actual);
                tb_fail(message);
            end
        end
    endtask

    task check_word;
        input [31:0] actual;
        input [31:0] expected;
        input [8*160-1:0] message;
        begin
            if (actual === expected) begin
                tb_pass(message);
            end else begin
                $display("[%0t] TB_INFO: expected=0x%08h actual=0x%08h", $time, expected, actual);
                tb_fail(message);
            end
        end
    endtask

    task check_cmd;
        input [3:0] actual;
        input [3:0] expected;
        input [8*160-1:0] message;
        begin
            if (actual === expected) begin
                tb_pass(message);
            end else begin
                $display("[%0t] TB_INFO: expected_cmd=0b%04b actual_cmd=0b%04b", $time, expected, actual);
                tb_fail(message);
            end
        end
    endtask

    task reset_dut;
        begin
            $display("[%0t] TB_PATH: reset sequence start", $time);
            tb_rst_i   = 1'b1;
            tb_text_i  = 32'h00000000;
            tb_cmd_i   = 3'b000;
            tb_cmd_w_i = 1'b0;

            repeat (3) @(posedge tb_clk_i);
            #1;

            $display("[%0t] TB_DUT_PATH: during reset cmd_o=0b%04b text_o=0x%08h busy=%0b round=%0d",
                     $time, tb_cmd_o, tb_text_o, dut.busy, dut.round);
            check_cmd(tb_cmd_o, 4'b0000, "RESET cmd_o must be 0");
            check_word(tb_text_o, 32'h00000000, "RESET text_o must be 0x00000000");
            check_bit(dut.busy, 1'b0, "RESET internal busy must be 0");

            @(negedge tb_clk_i);
            tb_rst_i = 1'b0;
            #1;
            $display("[%0t] TB_PATH: reset released", $time);
        end
    endtask

    task wait_busy_asserted;
        input [8*48-1:0] case_name;
        integer guard;
        begin
            guard = 0;
            while ((tb_cmd_o[3] !== 1'b1) && (guard < 20)) begin
                @(posedge tb_clk_i);
                #1;
                guard = guard + 1;
            end

            if (tb_cmd_o[3] === 1'b1)
                tb_pass({case_name, " busy status must assert"});
            else
                tb_fail({case_name, " busy status must assert"});
        end
    endtask

    task wait_busy_cleared;
        input [8*48-1:0] case_name;
        integer guard;
        begin
            guard = 0;
            while ((tb_cmd_o[3] !== 1'b0) && (guard < 200)) begin
                @(posedge tb_clk_i);
                #1;
                guard = guard + 1;
            end

            if (tb_cmd_o[3] === 1'b0)
                tb_pass({case_name, " busy status must clear after calculation"});
            else
                tb_fail({case_name, " busy status must clear after calculation"});

            $display("[%0t] TB_DUT_PATH: %0s calculation complete cmd_o=0b%04b busy=%0b round=%0d",
                     $time, case_name, tb_cmd_o, dut.busy, dut.round);
        end
    endtask

    task write_block;
        input [8*48-1:0] case_name;
        input            round_mode;
        input [511:0]    block_data;

        integer i;
        reg [511:0] block_shift;
        reg [31:0]  current_word;
        reg [2:0]   write_cmd;
        begin
            write_cmd = {round_mode, 1'b1, 1'b0};
            block_shift = block_data;
            current_word = block_shift[511:480];

            $display("[%0t] TB_CASE: %0s write block round_mode=%0b cmd=0b%03b",
                     $time, case_name, round_mode, write_cmd);

            @(negedge tb_clk_i);
            tb_cmd_i   = write_cmd;
            tb_cmd_w_i = 1'b1;
            tb_text_i  = current_word;

            @(posedge tb_clk_i);
            #1;
            $display("[%0t] TB_INFO: %0s write command accepted cmd_o=0b%04b",
                     $time, case_name, tb_cmd_o);
            check_bit(tb_cmd_o[1], 1'b1, {case_name, " write command bit must be accepted"});

            @(negedge tb_clk_i);
            tb_cmd_i   = 3'b000;
            tb_cmd_w_i = 1'b0;
            tb_text_i  = current_word;

            for (i = 0; i < 16; i = i + 1) begin
                if (i != 0) begin
                    @(negedge tb_clk_i);
                    block_shift = block_shift << 32;
                    current_word = block_shift[511:480];
                    tb_text_i = current_word;
                end

                @(posedge tb_clk_i);
                #1;
                $display("[%0t] TB_INFO: %0s word%02d text_i=0x%08h cmd_o=0b%04b busy=%0b round=%0d",
                         $time, case_name, i, current_word, tb_cmd_o, dut.busy, dut.round);

                if (i == 0)
                    check_bit(dut.busy, 1'b1, {case_name, " internal busy must assert after first word"});
            end

            wait_busy_asserted(case_name);
            wait_busy_cleared(case_name);
        end
    endtask

    task read_digest;
        input [8*48-1:0] case_name;
        input [255:0]    expected_digest;

        integer i;
        reg [255:0] expected_shift;
        reg [255:0] captured_digest;
        reg [31:0]  expected_word;
        begin
            expected_shift = expected_digest;
            captured_digest = 256'h0;

            $display("[%0t] TB_CASE: %0s read digest start", $time, case_name);

            @(negedge tb_clk_i);
            tb_cmd_i   = 3'b001;
            tb_cmd_w_i = 1'b1;

            @(posedge tb_clk_i);
            #1;
            $display("[%0t] TB_INFO: %0s read command accepted cmd_o=0b%04b",
                     $time, case_name, tb_cmd_o);
            check_bit(tb_cmd_o[0], 1'b1, {case_name, " read command bit must be accepted"});

            @(negedge tb_clk_i);
            tb_cmd_i   = 3'b000;
            tb_cmd_w_i = 1'b0;

            @(posedge tb_clk_i);
            #1;
            $display("[%0t] TB_INFO: %0s read_counter loaded read_counter=%0d text_o=0x%08h",
                     $time, case_name, dut.read_counter, tb_text_o);

            for (i = 0; i < 8; i = i + 1) begin
                expected_word = expected_shift[255:224];

                @(posedge tb_clk_i);
                #1;
                captured_digest = {captured_digest[223:0], tb_text_o};
                $display("[%0t] TB_INFO: %0s digest_word%0d expected=0x%08h actual=0x%08h read_counter=%0d",
                         $time, case_name, i, expected_word, tb_text_o, dut.read_counter);

                if (tb_text_o === expected_word) begin
                    pass_count = pass_count + 1;
                    $display("[%0t] TB_PASS: %0s digest word%0d must match expected",
                             $time, case_name, i);
                end else begin
                    fail_count = fail_count + 1;
                    $display("[%0t] TB_FAIL: %0s digest word%0d must match expected",
                             $time, case_name, i);
                end

                expected_shift = expected_shift << 32;
            end

            if (captured_digest === expected_digest)
                tb_pass({case_name, " full digest must match expected"});
            else begin
                $display("[%0t] TB_INFO: %0s captured_digest=0x%064h expected_digest=0x%064h",
                         $time, case_name, captured_digest, expected_digest);
                tb_fail({case_name, " full digest must match expected"});
            end

            $display("[%0t] TB_DUT_PATH: %0s digest read complete cmd_o=0b%04b text_o=0x%08h",
                     $time, case_name, tb_cmd_o, tb_text_o);
            repeat (3) @(posedge tb_clk_i);
        end
    endtask

    task run_single_block_case;
        input [8*48-1:0] case_name;
        input [511:0]    block_data;
        input [255:0]    expected_digest;
        begin
            $display("[%0t] TB_PATH: %0s start", $time, case_name);
            write_block(case_name, 1'b0, block_data);
            read_digest(case_name, expected_digest);
        end
    endtask

    task run_multi_block_case;
        begin
            $display("[%0t] TB_PATH: CASE3 start", $time);

            write_block("CASE3 block0", 1'b0, BLOCK_LONG_0);
            write_block("CASE3 block1", 1'b1, BLOCK_LONG_1);
            read_digest("CASE3", DIGEST_LONG);
        end
    endtask

    initial begin
        $timeformat(-9, 0, " ns", 10);

        tb_clk_i   = 1'b0;
        tb_rst_i   = 1'b0;
        tb_text_i  = 32'h00000000;
        tb_cmd_i   = 3'b000;
        tb_cmd_w_i = 1'b0;
        pass_count = 0;
        fail_count = 0;

        $display("[%0t] TB_PATH: simulation start", $time);

        reset_dut();

        run_single_block_case("CASE1", BLOCK_ABC, DIGEST_ABC);
        run_single_block_case("CASE2", BLOCK_EMPTY, DIGEST_EMPTY);
        run_multi_block_case();

        $display("[%0t] TB_SUMMARY: pass=%0d fail=%0d", $time, pass_count, fail_count);
        if (fail_count == 0)
            $display("[%0t] TB_RESULT: PASS", $time);
        else
            $display("[%0t] TB_RESULT: FAIL", $time);

        $finish;
    end

endmodule
