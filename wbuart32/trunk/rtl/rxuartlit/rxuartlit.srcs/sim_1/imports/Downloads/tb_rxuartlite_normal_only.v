`timescale 1ns/1ps
`default_nettype none

module tb_rxuartlite_normal_only;
    // Simulation-friendly setting.
    // rxuartlite.v のデフォルトは CLOCKS_PER_BAUD=868 ですが、
    // シミュレーションを短くするため 16 にしています。
    localparam integer TIMER_BITS      = 5;
    localparam integer CLOCKS_PER_BAUD = 16;

    reg        i_clk     = 1'b0;
    reg        i_uart_rx = 1'b1;  // UARTの待機状態はHigh
    wire       o_wr;
    wire [7:0] o_data;

    integer errors   = 0;
    integer wr_count = 0;
    reg [7:0] last_data = 8'h00;

    // 10 ns周期のクロック
    always #5 i_clk = ~i_clk;

    // DUT: 検証対象の rxuartlite
    rxuartlite #(
        .TIMER_BITS(TIMER_BITS),
        .CLOCKS_PER_BAUD(CLOCKS_PER_BAUD)
    ) dut (
        .i_clk(i_clk),
        .i_uart_rx(i_uart_rx),
        .o_wr(o_wr),
        .o_data(o_data)
    );

    // o_wr が立ったら、受信完了として記録する
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

    // i_uart_rx に1ビット分の値を与える
    task drive_bit_for_one_baud;
        input value;
        integer k;
        begin
            @(negedge i_clk);
            i_uart_rx = value;

            // 次のビット変化までの間隔がちょうど CLOCKS_PER_BAUD クロックになるようにする
            for (k = 1; k < CLOCKS_PER_BAUD; k = k + 1)
                @(negedge i_clk);
        end
    endtask

    // 8N1形式で1バイト送る
    // start bit: 0
    // data bits: bit0 から bit7 まで、LSB first
    // stop bit : 1
    task send_uart_byte;
        input [7:0] value;
        integer i;
        begin
            drive_bit_for_one_baud(1'b0);          // start bit

            for (i = 0; i < 8; i = i + 1)
                drive_bit_for_one_baud(value[i]);  // data bit0 -> bit7

            drive_bit_for_one_baud(1'b1);          // stop bit
        end
    endtask

    task check_received_byte;
        input [7:0] expected_data;
        begin
            // o_wr が立った後の反映を待つため、少し余裕を持って待つ
            wait_posedges(2 * CLOCKS_PER_BAUD);

            if (wr_count !== 1) begin
                $display("ERROR: expected exactly one o_wr pulse, got %0d", wr_count);
                errors = errors + 1;
            end

            if (last_data !== expected_data) begin
                $display("ERROR: expected o_data=0x%02h, got 0x%02h", expected_data, last_data);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("tb_rxuartlite_normal_only.vcd");
        $dumpvars(0, tb_rxuartlite_normal_only);

        // UART入力を待機状態にしてから開始
        i_uart_rx = 1'b1;
        wait_posedges(5 * CLOCKS_PER_BAUD);

        // 正常系のみ確認：0x55を送る
        send_uart_byte(8'h55);
        check_received_byte(8'h55);

        if (errors == 0)
            $display("PASS: normal receive test passed");
        else
            $display("FAIL: %0d error(s)", errors);

        $finish;
    end
endmodule

`default_nettype wire
