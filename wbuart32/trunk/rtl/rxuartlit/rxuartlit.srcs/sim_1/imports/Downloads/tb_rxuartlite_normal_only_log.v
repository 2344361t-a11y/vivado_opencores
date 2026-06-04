`timescale 1ns/1ps
`default_nettype none

module tb_rxuartlite_normal_only_log;
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

    reg [3:0] prev_state = 4'hx;
    reg [3:0] sample_state;
    reg       sample_bit;

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

    // state の数値を人間が読みやすい名前で出すための表示用タスク
    task print_state;
        input [3:0] s;
        begin
            case (s)
                4'h0: $write("BIT_ZERO");
                4'h1: $write("BIT_ONE");
                4'h2: $write("BIT_TWO");
                4'h3: $write("BIT_THREE");
                4'h4: $write("BIT_FOUR");
                4'h5: $write("BIT_FIVE");
                4'h6: $write("BIT_SIX");
                4'h7: $write("BIT_SEVEN");
                4'h8: $write("STOP");
                4'h9: $write("WAIT");
                4'hf: $write("IDLE");
                default: $write("UNKNOWN(%h)", s);
            endcase
        end
    endtask

    // DUT内部の状態遷移をログ出力する
    always @(dut.state) begin
        if (prev_state === 4'hx) begin
            $write("[%0t] rxuartlite STATE: initial -> ", $time);
            print_state(dut.state);
            $display("");
        end else if (dut.state !== prev_state) begin
            $write("[%0t] rxuartlite STATE: ", $time);
            print_state(prev_state);
            $write(" -> ");
            print_state(dut.state);
            $display("");
        end
        prev_state = dut.state;
    end

    // DUTが各データビットを取り込むタイミングをログ出力する
    // dut.zero_baud_counter が1で、stateがBIT_ZERO〜BIT_SEVENのときに
    // dut.qq_uart が data_reg に取り込まれる。
    always @(posedge i_clk) begin
        if ((dut.zero_baud_counter) && (dut.state <= 4'h7)) begin
            sample_state = dut.state;
            sample_bit   = dut.qq_uart;

            // DUT内部レジスタの nonblocking assignment 反映後に表示するため少し待つ
            #1;
            $write("[%0t] rxuartlite DATA: state=", $time);
            print_state(sample_state);
            $display(" sampled_bit=%b data_reg_after=0x%02h",
                     sample_bit, dut.data_reg);
        end
    end

    // o_wr の立ち上がりを受信完了として記録する
    always @(posedge o_wr) begin
        wr_count = wr_count + 1;
        last_data = o_data;
        $display("[%0t] rxuartlite DONE: o_wr=1 o_data=0x%02h", $time, o_data);
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
    // kind: 0=start, 1=data, 2=stop
    task drive_bit_for_one_baud;
        input value;
        input integer kind;
        input integer bit_index;
        integer k;
        begin
            @(negedge i_clk);
            i_uart_rx = value;

            if (kind == 0)
                $display("[%0t] TB_TX: START bit=%b", $time, value);
            else if (kind == 1)
                $display("[%0t] TB_TX: DATA bit%0d=%b", $time, bit_index, value);
            else if (kind == 2)
                $display("[%0t] TB_TX: STOP bit=%b", $time, value);
            else
                $display("[%0t] TB_TX: bit=%b", $time, value);

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
            $display("[%0t] TB_PATH: normal receive test start, send data=0x%02h", $time, value);

            drive_bit_for_one_baud(1'b0, 0, -1);         // start bit

            for (i = 0; i < 8; i = i + 1)
                drive_bit_for_one_baud(value[i], 1, i);  // data bit0 -> bit7

            drive_bit_for_one_baud(1'b1, 2, -1);         // stop bit
        end
    endtask

    task check_received_byte;
        input [7:0] expected_data;
        begin
            // o_wr が立った後の反映を待つため、少し余裕を持って待つ
            wait_posedges(2 * CLOCKS_PER_BAUD);

            if (wr_count !== 1) begin
                $display("[%0t] ERROR: expected exactly one o_wr pulse, got %0d",
                         $time, wr_count);
                errors = errors + 1;
            end

            if (last_data !== expected_data) begin
                $display("[%0t] ERROR: expected o_data=0x%02h, got 0x%02h",
                         $time, expected_data, last_data);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("tb_rxuartlite_normal_only_log.vcd");
        $dumpvars(0, tb_rxuartlite_normal_only_log);

        $display("[%0t] TB_PATH: simulation start", $time);

        // UART入力を待機状態にしてから開始
        i_uart_rx = 1'b1;
        wait_posedges(5 * CLOCKS_PER_BAUD);

        // 正常系のみ確認：0x55を送る
        send_uart_byte(8'h55);
        check_received_byte(8'h55);

        if (errors == 0)
            $display("[%0t] PASS: normal receive test passed", $time);
        else
            $display("[%0t] FAIL: %0d error(s)", $time, errors);

        $finish;
    end
endmodule

`default_nettype wire
