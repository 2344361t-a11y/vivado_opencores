`timescale 1ns / 1ps

module tb_gpio_controller;
    localparam WIDTH = 8;
    localparam CLK_PERIOD = 10;

    reg clk;
    reg rst_n;
    reg wb_cyc;
    reg wb_stb;
    reg wb_addr;
    reg wb_we;
    reg [7:0] wb_wdata;
    wire [7:0] wb_rdata;
    wire wb_ack;
    wire [WIDTH-1:0] gpio;
    wire [WIDTH-1:0] direction_reg;
    wire [WIDTH-1:0] output_reg;
    wire [WIDTH-1:0] input_data;
    wire read_valid;
    wire done;
    wire busy;
    wire ready;

    reg [WIDTH-1:0] gpio_external_drive;
    reg [WIDTH-1:0] gpio_external_oe;

    integer pass_count;
    integer fail_count;
    integer cycle_count;

    assign gpio[0] = (gpio_external_oe[0]) ? gpio_external_drive[0] : 1'bz;
    assign gpio[1] = (gpio_external_oe[1]) ? gpio_external_drive[1] : 1'bz;
    assign gpio[2] = (gpio_external_oe[2]) ? gpio_external_drive[2] : 1'bz;
    assign gpio[3] = (gpio_external_oe[3]) ? gpio_external_drive[3] : 1'bz;
    assign gpio[4] = (gpio_external_oe[4]) ? gpio_external_drive[4] : 1'bz;
    assign gpio[5] = (gpio_external_oe[5]) ? gpio_external_drive[5] : 1'bz;
    assign gpio[6] = (gpio_external_oe[6]) ? gpio_external_drive[6] : 1'bz;
    assign gpio[7] = (gpio_external_oe[7]) ? gpio_external_drive[7] : 1'bz;

    gpio_controller #(.WIDTH(WIDTH)) uut (
        .clk(clk),
        .rst_n(rst_n),
        .wb_cyc(wb_cyc),
        .wb_stb(wb_stb),
        .wb_addr(wb_addr),
        .wb_we(wb_we),
        .wb_wdata(wb_wdata),
        .wb_rdata(wb_rdata),
        .wb_ack(wb_ack),
        .gpio(gpio),
        .direction_reg(direction_reg),
        .output_reg(output_reg),
        .input_data(input_data),
        .read_valid(read_valid),
        .done(done),
        .busy(busy),
        .ready(ready)
    );

    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) cycle_count <= 0;
        else cycle_count <= cycle_count + 1;
    end

    task check;
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

    task bus_write;
        input [8*32-1:0] case_name;
        input addr;
        input [7:0] data;
        begin
            @(negedge clk);
            wb_addr = addr;
            wb_wdata = data;
            wb_we = 1'b1;
            wb_cyc = 1'b1;
            wb_stb = 1'b1;
            $display("[%0t] TB_CASE: %0s bus_write addr=%0d data=%02h cycle=%0d",
                     $time, case_name, addr, data, cycle_count);
            while (!wb_ack) begin
                @(posedge clk); #1;
            end
            check(done === 1'b1, "WISHBONE write must assert done with ack");
            $display("[%0t] TB_INFO: %0s write_ack wb_ack=%0b ready=%0b cycle=%0d",
                     $time, case_name, wb_ack, ready, cycle_count);
            @(negedge clk);
            wb_cyc = 1'b0;
            wb_stb = 1'b0;
            wb_we = 1'b0;
            wb_wdata = 8'h00;
            @(posedge clk); #1;
        end
    endtask

    task bus_read;
        input [8*32-1:0] case_name;
        input addr;
        output [7:0] data;
        begin
            @(negedge clk);
            wb_addr = addr;
            wb_we = 1'b0;
            wb_cyc = 1'b1;
            wb_stb = 1'b1;
            $display("[%0t] TB_CASE: %0s bus_read addr=%0d cycle=%0d",
                     $time, case_name, addr, cycle_count);
            while (!wb_ack) begin
                @(posedge clk); #1;
            end
            data = wb_rdata;
            check(done === 1'b1, "WISHBONE read must assert done with ack");
            if (addr) check(read_valid === 1'b1, "line register read must assert read_valid");
            $display("[%0t] TB_INFO: %0s read_ack wb_ack=%0b wb_rdata=%02h input_data=%02h cycle=%0d",
                     $time, case_name, wb_ack, wb_rdata, input_data, cycle_count);
            @(negedge clk);
            wb_cyc = 1'b0;
            wb_stb = 1'b0;
            @(posedge clk); #1;
        end
    endtask

    task drive_gpio_inputs;
        input [7:0] direction_value;
        input [7:0] external_value;
        begin
            @(negedge clk);
            gpio_external_drive = external_value;
            gpio_external_oe = ~direction_value;
            $display("[%0t] TB_CASE: external_gpio drive=%02h oe=%02h",
                     $time, gpio_external_drive, gpio_external_oe);
            repeat (3) @(posedge clk);
            #1;
        end
    endtask

    task configure_gpio;
        input [8*32-1:0] case_name;
        input [7:0] direction_value;
        input [7:0] output_value;
        reg [7:0] data;
        begin
            bus_write(case_name, 1'b0, direction_value);
            bus_write(case_name, 1'b1, output_value);
            bus_read(case_name, 1'b0, data);
            check(data === direction_value, "direction register readback must match written value");
        end
    endtask

    task read_gpio;
        input [8*32-1:0] case_name;
        input [7:0] direction_value;
        input [7:0] external_value;
        input [7:0] expected_value;
        reg [7:0] data;
        begin
            drive_gpio_inputs(direction_value, external_value);
            bus_read(case_name, 1'b1, data);
            check(data === expected_value, "line register read data must match expected pin value");
            check(input_data === expected_value, "input_data must match expected pin value");
        end
    endtask


    task invalid_bus_access;
        input [8*32-1:0] case_name;
        input cyc_value;
        input stb_value;
        input addr;
        input we_value;
        input [7:0] data;
        reg [7:0] saved_direction;
        reg [7:0] saved_output;
        begin
            saved_direction = direction_reg;
            saved_output = output_reg;

            @(negedge clk);
            wb_addr = addr;
            wb_wdata = data;
            wb_we = we_value;
            wb_cyc = cyc_value;
            wb_stb = stb_value;
            $display("[%0t] TB_CASE: %0s invalid_bus_access cyc=%0b stb=%0b addr=%0d we=%0b data=%02h cycle=%0d",
                     $time, case_name, cyc_value, stb_value, addr, we_value, data, cycle_count);

            @(posedge clk); #1;
            check(wb_ack === 1'b0, "invalid bus access must not assert wb_ack");
            check(done === 1'b0, "invalid bus access must not assert done");
            check(busy === 1'b0, "invalid bus access must not assert busy");
            check(ready === 1'b1, "invalid bus access must keep ready asserted");
            check(direction_reg === saved_direction, "invalid bus access must not change direction_reg");
            check(output_reg === saved_output, "invalid bus access must not change output_reg");

            @(negedge clk);
            wb_cyc = 1'b0;
            wb_stb = 1'b0;
            wb_we = 1'b0;
            wb_wdata = 8'h00;
            @(posedge clk); #1;
        end
    endtask

    task reset_during_operation;
        input [8*32-1:0] case_name;
        begin
            $display("[%0t] TB_PATH: %0s reset during operation start", $time, case_name);

            bus_write(case_name, 1'b0, 8'hAA);
            bus_write(case_name, 1'b1, 8'h55);
            check(direction_reg === 8'hAA, "CASE9 pre-reset direction_reg must be AA");
            check(output_reg === 8'h55, "CASE9 pre-reset output_reg must be 55");

            @(negedge clk);
            wb_addr = 1'b0;
            wb_wdata = 8'h0F;
            wb_we = 1'b1;
            wb_cyc = 1'b1;
            wb_stb = 1'b1;
            $display("[%0t] TB_CASE: %0s assert reset while bus access is active", $time, case_name);
            #1;
            rst_n = 1'b0;
            #1;

            check(direction_reg === 8'h00, "CASE9 reset must clear direction_reg");
            check(output_reg === 8'h00, "CASE9 reset must clear output_reg");
            check(input_data === 8'h00, "CASE9 reset must clear input_data");
            check(wb_rdata === 8'h00, "CASE9 reset must clear wb_rdata");
            check(wb_ack === 1'b0, "CASE9 reset must clear wb_ack");
            check(done === 1'b0, "CASE9 reset must clear done");
            check(read_valid === 1'b0, "CASE9 reset must clear read_valid");

            wb_cyc = 1'b0;
            wb_stb = 1'b0;
            wb_we = 1'b0;
            wb_wdata = 8'h00;
            gpio_external_drive = 8'h00;
            gpio_external_oe = 8'hFF;

            repeat (2) @(posedge clk);
            @(negedge clk);
            rst_n = 1'b1;
            @(posedge clk); #1;

            check(ready === 1'b1, "CASE9 reset release must make ready 1");
            check(wb_ack === 1'b0, "CASE9 reset release must keep wb_ack 0");
            check(direction_reg === 8'h00, "CASE9 reset release must keep direction_reg 00");
            check(output_reg === 8'h00, "CASE9 reset release must keep output_reg 00");
            check(input_data === 8'h00, "CASE9 reset release must keep input_data 00");
        end
    endtask

    initial begin
        pass_count = 0;
        fail_count = 0;
        rst_n = 1'b0;
        wb_cyc = 1'b0;
        wb_stb = 1'b0;
        wb_addr = 1'b0;
        wb_we = 1'b0;
        wb_wdata = 8'h00;
        gpio_external_drive = 8'h00;
        gpio_external_oe = 8'hFF;

        $display("[%0t] TB_PATH: reset sequence start", $time);
        repeat (3) @(posedge clk);
        @(negedge clk);
        rst_n = 1'b1;
        @(posedge clk); #1;
        check(ready === 1'b1, "RESET ready must be 1");
        check(wb_ack === 1'b0, "RESET wb_ack must be 0");
        check(direction_reg === 8'h00, "RESET all pins must be input");

        $display("[%0t] TB_PATH: CASE1 lower nibble output upper input start", $time);
        configure_gpio("CASE1 lower output", 8'h0F, 8'h05);
        check(direction_reg === 8'h0F, "CASE1 lower nibble must be output enabled");
        check(output_reg === 8'h05, "CASE1 output register must be 05");
        read_gpio("CASE1 mixed read", 8'h0F, 8'hA0, 8'hA5);

        $display("[%0t] TB_PATH: CASE2 upper nibble output lower input start", $time);
        configure_gpio("CASE2 upper output", 8'hF0, 8'hC0);
        check(direction_reg === 8'hF0, "CASE2 upper nibble must be output enabled");
        check(output_reg === 8'hC0, "CASE2 output register must be C0");
        read_gpio("CASE2 mixed read", 8'hF0, 8'h0A, 8'hCA);

        $display("[%0t] TB_PATH: CASE3 all input start", $time);
        configure_gpio("CASE3 all input", 8'h00, 8'hFF);
        check(direction_reg === 8'h00, "CASE3 all pins must be input");
        read_gpio("CASE3 input read", 8'h00, 8'h3C, 8'h3C);

        $display("[%0t] TB_PATH: CASE4 all output start", $time);
        configure_gpio("CASE4 all output", 8'hFF, 8'h96);
        check(direction_reg === 8'hFF, "CASE4 all pins must be output");
        read_gpio("CASE4 output readback", 8'hFF, 8'h00, 8'h96);

        $display("[%0t] TB_PATH: CASE5 wb_cyc only invalid access start", $time);
        invalid_bus_access("CASE5 cyc only", 1'b1, 1'b0, 1'b0, 1'b1, 8'h00);

        $display("[%0t] TB_PATH: CASE6 wb_stb only invalid access start", $time);
        invalid_bus_access("CASE6 stb only", 1'b0, 1'b1, 1'b0, 1'b1, 8'h00);

        $display("[%0t] TB_PATH: CASE9 reset during operation start", $time);
        reset_during_operation("CASE9 mid reset");

        $display("[%0t] TB_SUMMARY: pass=%0d fail=%0d", $time, pass_count, fail_count);
        if (fail_count == 0) $display("Good.");
        $finish;
    end
endmodule
