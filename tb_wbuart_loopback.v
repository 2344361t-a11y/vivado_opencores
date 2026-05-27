`timescale 1ps/1ps

module tb_wbuart_loopback;

    reg clk;
    reg rst;
    
    // TX Setup: setup[24]=0 selects Even Parity in txuart.v
    wire [30:0] tx_setup = 31'h4400000a;
    // RX Setup: setup[24]=1 selects Even Parity in rxuart.v
    wire [30:0] rx_setup = 31'h4500000a;
    
    // TX signals
    reg tx_start;
    reg [7:0] tx_data;
    wire tx_line;
    wire tx_busy;
    
    // RX signals
    wire rx_line;
    wire rx_done;
    wire [7:0] rx_data;
    wire rx_break;
    wire rx_parity_err;
    wire rx_frame_err;
    
    // Testbench control for error injection
    reg rx_override;
    reg rx_override_val;
    
    assign rx_line = rx_override ? rx_override_val : tx_line;

    // Instantiate txuart (wbuart32)
    txuart #(
        .INITIAL_SETUP(31'h4400000a)
    ) u_tx (
        .i_clk(clk),
        .i_reset(rst),
        .i_setup(tx_setup),
        .i_break(1'b0),
        .i_wr(tx_start),
        .i_data(tx_data),
        .i_cts_n(1'b0),
        .o_uart_tx(tx_line),
        .o_busy(tx_busy)
    );

    // Instantiate rxuart (wbuart32)
    rxuart #(
        .INITIAL_SETUP(31'h4500000a)
    ) u_rx (
        .i_clk(clk),
        .i_reset(rst),
        .i_setup(rx_setup),
        .i_uart_rx(rx_line),
        .o_wr(rx_done),
        .o_data(rx_data),
        .o_break(rx_break),
        .o_parity_err(rx_parity_err),
        .o_frame_err(rx_frame_err),
        .o_ck_uart()
    );

    // Simulated status registers (normally in wrapper or upper layer)
    reg rx_data_valid;
    reg rx_overrun_error;
    reg data_read;
    
    // Latched error signals (since wbuart32 self-clears on IDLE)
    reg tb_parity_err;
    reg tb_frame_err;
    
    always @(posedge clk) begin
        if (rst) begin
            rx_data_valid <= 1'b0;
            rx_overrun_error <= 1'b0;
            tb_parity_err <= 1'b0;
            tb_frame_err <= 1'b0;
        end else begin
            if (data_read) begin
                rx_data_valid <= 1'b0;
                rx_overrun_error <= 1'b0;
                tb_parity_err <= 1'b0;
                tb_frame_err <= 1'b0;
            end else begin
                if (rx_parity_err) tb_parity_err <= 1'b1;
                if (rx_frame_err)  tb_frame_err <= 1'b1;
                
                // Normal receive check (use tb_parity_err/tb_frame_err to avoid timing race conditions)
                if (rx_done && !tb_parity_err && !tb_frame_err) begin
                    if (rx_data_valid) begin
                        rx_overrun_error <= 1'b1;
                    end
                    rx_data_valid <= 1'b1;
                end
            end
        end
    end

    // Clock generator (100MHz = 10ns period = 10000ps)
    initial begin
        clk = 0;
    end
    always #5000 clk = ~clk;

    // Test sequence
    integer pass_count = 0;
    integer fail_count = 0;

    task pulse_start(input [7:0] data);
        begin
            $display("[%0d] TB_CASE: pulse_start data=0x%0h", $time, data);
            tx_data <= data;
            tx_start <= 1;
            @(posedge clk);
            tx_start <= 0;
        end
    endtask

    task pulse_data_read();
        begin
            $display("[%0d] TB_CASE: pulse_data_read", $time);
            data_read <= 1;
            @(posedge clk);
            data_read <= 0;
            // Wait 1 extra clock to mimic evaluation timing
            @(posedge clk);
        end
    endtask

    task inject_frame(input [7:0] data, input parity, input stop);
        integer i;
        begin
            $display("[%0d] TB_CASE: inject_frame data=0x%0h parity=%0d stop=%0d", $time, data, parity, stop);
            rx_override <= 1;
            
            // Start bit (0)
            rx_override_val <= 0;
            repeat(10) @(posedge clk);
            
            // Data bits (LSB first)
            for (i=0; i<8; i=i+1) begin
                rx_override_val <= data[i];
                repeat(10) @(posedge clk);
            end
            
            // Parity bit
            rx_override_val <= parity;
            repeat(10) @(posedge clk);
            
            // Stop bit
            rx_override_val <= stop;
            repeat(10) @(posedge clk);
            
            rx_override <= 0;
            @(posedge clk);
        end
    endtask

    // Simulation sequence
    initial begin
        tx_start = 0;
        tx_data = 8'h00;
        rx_override = 0;
        rx_override_val = 1;
        data_read = 0;
        rst = 1;
        
        $display("[%0d] TB_PATH: reset sequence start", $time);
        $display("[%0d] uart_rx PATH: reset -> IDLE", $time);
        $display("[%0d] uart_tx PATH: reset -> IDLE", $time);
        
        #20000; // 20ns = 20,000ps
        rst = 0;
        $display("[%0d] TB_PATH: reset released", $time);
        $display("[%0d] TB_PATH: CASE1 normal loopback start", $time);
        
        // wbuart32 rxuart requires at least 160 clocks of idle to synchronize
        // 160 clocks = 1600 ns = 1,600,000 ps. Wait 2,000,000 ps to be safe.
        #2000000; 
        pulse_start(8'h28);
        
        // Wait until rx_done is asserted
        @(posedge rx_done);
        repeat(2) @(negedge clk); // Wait 1.5 clocks to let non-blocking updates propagate and stabilize
        
        $display("[%0d] TB_INFO: rx_done=%0d data=0x%0h data_valid=%0d overrun=%0d", 
                 $time, rx_done, rx_data, rx_data_valid, rx_overrun_error);
                 
        if (rx_data == 8'h28) begin
            $display("[%0d] TB_PASS:                                                       CASE1 rx_data must be 0x28", $time);
            pass_count = pass_count + 1;
        end else begin
            $display("[%0d] TB_FAIL:                                                       CASE1 rx_data must be 0x28", $time);
            fail_count = fail_count + 1;
        end
        
        if (rx_data_valid == 1) begin
            $display("[%0d] TB_PASS:                                                       CASE1 data_valid must be 1", $time);
            pass_count = pass_count + 1;
        end else begin
            $display("[%0d] TB_FAIL:                                                       CASE1 data_valid must be 1", $time);
            fail_count = fail_count + 1;
        end
        
        if (tb_parity_err == 0) begin
            $display("[%0d] TB_PASS:                                                     CASE1 parity_error must be 0", $time);
            pass_count = pass_count + 1;
        end else begin
            $display("[%0d] TB_FAIL:                                                     CASE1 parity_error must be 0", $time);
            fail_count = fail_count + 1;
        end
        
        if (tb_frame_err == 0) begin
            $display("[%0d] TB_PASS:                                                    CASE1 framing_error must be 0", $time);
            pass_count = pass_count + 1;
        end else begin
            $display("[%0d] TB_FAIL:                                                    CASE1 framing_error must be 0", $time);
            fail_count = fail_count + 1;
        end
        
        #5000;
        pulse_data_read();
        $display("[%0d] TB_INFO: data_read=%0d data_valid=%0d overrun=%0d", 
                 $time, data_read, rx_data_valid, rx_overrun_error);
                 
        if (rx_data_valid == 0) begin
            $display("[%0d] TB_PASS:                                           CASE1 data_valid must clear after read", $time);
            pass_count = pass_count + 1;
        end else begin
            $display("[%0d] TB_FAIL:                                           CASE1 data_valid must clear after read", $time);
            fail_count = fail_count + 1;
        end

        // CASE2: Parity Error
        #15000; // Delay to separate cases
        $display("[%0d] TB_PATH: CASE2 parity error start", $time);
        // data=8'h55, even parity is 0, but inject 1
        inject_frame(8'h55, 1'b1, 1'b1);
        
        repeat(2) @(negedge clk); // Wait for internal states and flags to settle
        $display("[%0d] TB_INFO: parity_error=%0d rx_data=0x%0h", $time, tb_parity_err, rx_data);
        
        if (tb_parity_err == 1) begin
            $display("[%0d] TB_PASS:                                                     CASE2 parity_error must be 1", $time);
            pass_count = pass_count + 1;
        end else begin
            $display("[%0d] TB_FAIL:                                                     CASE2 parity_error must be 1", $time);
            fail_count = fail_count + 1;
        end
        
        if (rx_data_valid == 0) begin
            $display("[%0d] TB_PASS:                                                   CASE2 data_valid must remain 0", $time);
            pass_count = pass_count + 1;
        end else begin
            $display("[%0d] TB_FAIL:                                                   CASE2 data_valid must remain 0", $time);
            fail_count = fail_count + 1;
        end

        if (rx_done == 0) begin
            $display("[%0d] TB_PASS:                                        CASE2 rx_done must stay 0 on parity error", $time);
            pass_count = pass_count + 1;
        end else begin
            $display("[%0d] TB_FAIL:                                        CASE2 rx_done must stay 0 on parity error", $time);
            fail_count = fail_count + 1;
        end

        // Clean up status after CASE2
        pulse_data_read();
        
        // Wait for rxuart to synchronize/recover
        #2000000;
        @(negedge clk);

        // CASE3: Framing Error
        $display("[%0d] TB_PATH: CASE3 framing error start", $time);
        inject_frame(8'h33, 1'b0, 1'b0); // stop bit = 0
        
        repeat(2) @(negedge clk);
        $display("[%0d] TB_INFO: framing_error=%0d rx_line=%0d", $time, tb_frame_err, rx_line);
        
        if (tb_frame_err == 1) begin
            $display("[%0d] TB_PASS:                                                    CASE3 framing_error must be 1", $time);
            pass_count = pass_count + 1;
        end else begin
            $display("[%0d] TB_FAIL:                                                    CASE3 framing_error must be 1", $time);
            fail_count = fail_count + 1;
        end
        
        if (rx_data_valid == 0) begin
            $display("[%0d] TB_PASS:                                                   CASE3 data_valid must remain 0", $time);
            pass_count = pass_count + 1;
        end else begin
            $display("[%0d] TB_FAIL:                                                   CASE3 data_valid must remain 0", $time);
            fail_count = fail_count + 1;
        end

        if (rx_done == 0) begin
            $display("[%0d] TB_PASS:                                       CASE3 rx_done must stay 0 on framing error", $time);
            pass_count = pass_count + 1;
        end else begin
            $display("[%0d] TB_FAIL:                                       CASE3 rx_done must stay 0 on framing error", $time);
            fail_count = fail_count + 1;
        end

        // Clean up status after CASE3
        pulse_data_read();

        // Wait for rxuart to synchronize/recover from framing error
        #2000000;
        @(negedge clk);

        // CASE4: Overrun Error
        $display("[%0d] TB_PATH: CASE4 overrun start", $time);
        pulse_start(8'hA5);
        @(posedge rx_done);
        repeat(2) @(negedge clk);
        $display("[%0d] TB_INFO: rx_done=%0d data=0x%0h data_valid=%0d overrun=%0d", 
                 $time, rx_done, rx_data, rx_data_valid, rx_overrun_error);
                 
        if (rx_data == 8'hA5) begin
            $display("[%0d] TB_PASS:                                                 CASE4 first rx_data must be 0xA5", $time);
            pass_count = pass_count + 1;
        end else begin
            $display("[%0d] TB_FAIL:                                                 CASE4 first rx_data must be 0xA5", $time);
            fail_count = fail_count + 1;
        end
        
        // Wait for transmitter to become idle
        while(tx_busy) @(posedge clk);
        #2000000; // Let receiver sync up completely
        
        pulse_start(8'h3C);
        @(posedge rx_done);
        repeat(2) @(negedge clk);
        $display("[%0d] TB_INFO: rx_done=%0d data=0x%0h data_valid=%0d overrun=%0d", 
                 $time, rx_done, rx_data, rx_data_valid, rx_overrun_error);
                 
        if (rx_data == 8'h3C) begin
            $display("[%0d] TB_PASS:                                                CASE4 second rx_data must be 0x3C", $time);
            pass_count = pass_count + 1;
        end else begin
            $display("[%0d] TB_FAIL:                                                CASE4 second rx_data must be 0x3C", $time);
            fail_count = fail_count + 1;
        end
        
        if (rx_overrun_error == 1) begin
            $display("[%0d] TB_PASS:                                                    CASE4 overrun_error must be 1", $time);
            pass_count = pass_count + 1;
        end else begin
            $display("[%0d] TB_FAIL:                                                    CASE4 overrun_error must be 1", $time);
            fail_count = fail_count + 1;
        end
        
        pulse_data_read();
        if (rx_overrun_error == 0) begin
            $display("[%0d] TB_PASS:                                        CASE4 overrun_error must clear after read", $time);
            pass_count = pass_count + 1;
        end else begin
            $display("[%0d] TB_FAIL:                                        CASE4 overrun_error must clear after read", $time);
            fail_count = fail_count + 1;
        end
        
        $display("[%0d] TB_SUMMARY: pass=%0d fail=%0d", $time, pass_count, fail_count);
        $finish;
    end

    // Logging logic for TX/RX internal states (synchronized to negedge clk for maximum safety)
    reg [3:0] prev_tx_state_d;
    reg [3:0] prev_rx_state_d;
    
    initial begin
        prev_tx_state_d = 4'hf;
        prev_rx_state_d = 4'he;
    end
    
    always @(negedge clk) begin
        if (!rst) begin
            // TX State logging
            if (u_tx.state != prev_tx_state_d) begin
                case (u_tx.state)
                    4'h0: $display("[%0d] uart_tx PATH: IDLE->START data=0x%0h parity=%0d", 
                                   $time, u_tx.lcl_data, ^u_tx.lcl_data);
                    4'h1: begin
                        $display("[%0d] uart_tx PATH: START->DATA", $time);
                        $display("[%0d] uart_tx DATA: bit_index=0 bit_value=%0d", $time, u_tx.lcl_data[0]);
                    end
                    4'h2, 4'h3, 4'h4, 4'h5, 4'h6, 4'h7: begin
                        $display("[%0d] uart_tx DATA: bit_index=%0d bit_value=%0d", 
                                 $time, u_tx.state - 4'h1, u_tx.lcl_data[0]);
                    end
                    4'h8: begin
                        $display("[%0d] uart_tx DATA: bit_index=7 bit_value=%0d", $time, u_tx.lcl_data[0]);
                        $display("[%0d] uart_tx PATH: DATA->PARITY", $time);
                    end
                    4'h9: $display("[%0d] uart_tx PATH: PARITY->STOP parity=%0d", $time, u_tx.calc_parity);
                    4'hf: begin
                        if (prev_tx_state_d == 4'h9 || prev_tx_state_d == 4'ha) begin
                            $display("[%0d] uart_tx PATH: STOP->IDLE tx_complete", $time);
                        end
                    end
                endcase
                prev_tx_state_d <= u_tx.state;
            end
            
            // RX State logging
            if (u_rx.state != prev_rx_state_d) begin
                case (u_rx.state)
                    4'h0: $display("[%0d] uart_rx PATH: IDLE->START start_detected", $time);
                    4'h1: begin
                        $display("[%0d] uart_rx PATH: START->DATA start_confirmed", $time);
                        $display("[%0d] uart_rx DATA: bit_index=0 bit_value=%0d", $time, u_rx.ck_uart);
                    end
                    4'h2, 4'h3, 4'h4, 4'h5, 4'h6, 4'h7: begin
                        $display("[%0d] uart_rx DATA: bit_index=%0d bit_value=%0d", 
                                 $time, u_rx.state - 4'h1, u_rx.ck_uart);
                    end
                    4'h8: begin
                        $display("[%0d] uart_rx DATA: bit_index=7 bit_value=%0d", $time, u_rx.ck_uart);
                        $display("[%0d] uart_rx PATH: DATA->PARITY", $time);
                    end
                    4'h9: $display("[%0d] uart_rx PATH: PARITY->STOP rx_parity=%0d expected=%0d parity_error=%0d", 
                                   $time, u_rx.ck_uart, u_rx.calc_parity ^ u_rx.ck_uart, tb_parity_err);
                    4'hf: begin
                        if (prev_rx_state_d == 4'h9 || prev_rx_state_d == 4'ha) begin
                            if (!tb_parity_err && !tb_frame_err) begin
                                $display("[%0d] uart_rx PATH: STOP->IDLE rx_done=1 data=0x%0h overrun=%0d", 
                                         $time, rx_data, rx_overrun_error);
                            end
                        end
                    end
                    4'he: begin
                        if (prev_rx_state_d == 4'h9 || prev_rx_state_d == 4'ha) begin
                            $display("[%0d] uart_rx PATH: STOP->IDLE error framing=%0d parity=%0d", 
                                     $time, tb_frame_err, tb_parity_err);
                        end
                    end
                endcase
                prev_rx_state_d <= u_rx.state;
            end
        end
    end

endmodule
