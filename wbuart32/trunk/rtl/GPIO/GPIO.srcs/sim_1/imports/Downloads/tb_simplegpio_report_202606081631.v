`timescale 1ns / 1ps

module tb_simplegpio_report;

  reg         clk_i;
  reg         rst_i;
  reg         cyc_i;
  reg         stb_i;
  reg         adr_i;
  reg         we_i;
  reg  [7:0]  dat_i;
  wire [7:0]  dat_o;
  wire        ack_o;

  wire [8:1]  gpio;

  // Testbench-side GPIO driver.
  // gpio_oe[n] = 1: testbench drives gpio[n]
  // gpio_oe[n] = 0: testbench releases gpio[n] to high impedance
  reg  [8:1]  gpio_drv;
  reg  [8:1]  gpio_oe;

  integer pass_count;
  integer fail_count;
  integer current_case;

  // Tri-state connection for GPIO pins.
  assign gpio[1] = gpio_oe[1] ? gpio_drv[1] : 1'bz;
  assign gpio[2] = gpio_oe[2] ? gpio_drv[2] : 1'bz;
  assign gpio[3] = gpio_oe[3] ? gpio_drv[3] : 1'bz;
  assign gpio[4] = gpio_oe[4] ? gpio_drv[4] : 1'bz;
  assign gpio[5] = gpio_oe[5] ? gpio_drv[5] : 1'bz;
  assign gpio[6] = gpio_oe[6] ? gpio_drv[6] : 1'bz;
  assign gpio[7] = gpio_oe[7] ? gpio_drv[7] : 1'bz;
  assign gpio[8] = gpio_oe[8] ? gpio_drv[8] : 1'bz;

  // DUT
  simple_gpio #(.io(8)) uut (
    .clk_i(clk_i),
    .rst_i(rst_i),
    .cyc_i(cyc_i),
    .stb_i(stb_i),
    .adr_i(adr_i),
    .we_i (we_i),
    .dat_i(dat_i),
    .dat_o(dat_o),
    .ack_o(ack_o),
    .gpio (gpio)
  );

  // Clock generation: 10 ns period.
  initial begin
    clk_i = 1'b0;
    forever #5 clk_i = ~clk_i;
  end

  // Convert [8:1] vector to normal [7:0] display/check order.
  function [7:0] vec8_to_byte;
    input [8:1] value;
    begin
      vec8_to_byte = {value[8], value[7], value[6], value[5],
                      value[4], value[3], value[2], value[1]};
    end
  endfunction

  task check_equal8;
    input [8*80:1] message;
    input [7:0] actual;
    input [7:0] expected;
    begin
      if (actual === expected) begin
        pass_count = pass_count + 1;
        $display("[%0t] TB_PASS: %0s actual=0x%02h expected=0x%02h",
                 $time, message, actual, expected);
      end else begin
        fail_count = fail_count + 1;
        $display("[%0t] TB_FAIL: %0s actual=0x%02h expected=0x%02h",
                 $time, message, actual, expected);
      end
    end
  endtask

  task check_equal1;
    input [8*80:1] message;
    input actual;
    input expected;
    begin
      if (actual === expected) begin
        pass_count = pass_count + 1;
        $display("[%0t] TB_PASS: %0s actual=%b expected=%b",
                 $time, message, actual, expected);
      end else begin
        fail_count = fail_count + 1;
        $display("[%0t] TB_FAIL: %0s actual=%b expected=%b",
                 $time, message, actual, expected);
      end
    end
  endtask

  // Wishbone single write access.
  task wb_write;
    input adr;
    input [7:0] data;
    begin
      $display("[%0t] TB_CASE: CASE%0d wb_write adr=%0d data=0x%02h",
               $time, current_case, adr, data);

      @(negedge clk_i);
      adr_i = adr;
      dat_i = data;
      we_i  = 1'b1;
      cyc_i = 1'b1;
      stb_i = 1'b1;

      @(posedge clk_i);
      #2;
      check_equal1("Wishbone write ack_o must be 1", ack_o, 1'b1);

      @(negedge clk_i);
      cyc_i = 1'b0;
      stb_i = 1'b0;
      we_i  = 1'b0;
      adr_i = 1'b0;
      dat_i = 8'h00;

      @(posedge clk_i);
      #2;
      check_equal1("Wishbone write ack_o must return to 0", ack_o, 1'b0);
    end
  endtask

  // Wishbone single read access.
  task wb_read;
    input adr;
    output [7:0] data;
    begin
      $display("[%0t] TB_CASE: CASE%0d wb_read adr=%0d",
               $time, current_case, adr);

      @(negedge clk_i);
      adr_i = adr;
      we_i  = 1'b0;
      cyc_i = 1'b1;
      stb_i = 1'b1;

      @(posedge clk_i);
      #2;
      data = dat_o;
      check_equal1("Wishbone read ack_o must be 1", ack_o, 1'b1);
      $display("[%0t] TB_INFO: CASE%0d read_data=0x%02h",
               $time, current_case, data);

      @(negedge clk_i);
      cyc_i = 1'b0;
      stb_i = 1'b0;
      adr_i = 1'b0;

      @(posedge clk_i);
      #2;
      check_equal1("Wishbone read ack_o must return to 0", ack_o, 1'b0);
    end
  endtask

  task run_normal_case;
    input integer case_id;
    input [7:0] ctrl_value;
    input [7:0] line_value;
    input [7:0] external_value;
    input [7:0] expected_gpio_value;
    reg [7:0] ctrl_read;
    reg [7:0] gpio_read;
    reg [7:0] gpio_now;
    begin
      current_case = case_id;

      $display("[%0t] TB_PATH: CASE%0d normal GPIO sequence start", $time, case_id);
      $display("[%0t] TB_INFO: CASE%0d ctrl=0x%02h line=0x%02h external=0x%02h expected_gpio=0x%02h",
               $time, case_id, ctrl_value, line_value, external_value, expected_gpio_value);

      // Release all GPIO pins from the testbench before changing DUT direction.
      gpio_oe  = 8'h00;
      gpio_drv = 8'h00;
      repeat (2) @(posedge clk_i);
      #2;

      // 1. Direction setting by control register.
      wb_write(1'b0, ctrl_value);
      #2;
      $display("[%0t] TB_INFO: CASE%0d DUT ctrl=0x%02h", $time, case_id, vec8_to_byte(uut.ctrl));

      // 2. Control register readback.
      wb_read(1'b0, ctrl_read);
      check_equal8("Control register readback must match ctrl setting", ctrl_read, ctrl_value);

      // 3. Output value setting by line register.
      wb_write(1'b1, line_value);
      #2;
      $display("[%0t] TB_INFO: CASE%0d DUT line=0x%02h", $time, case_id, vec8_to_byte(uut.line));

      // 4. Testbench drives only the GPIO pins configured as input.
      //    ctrl bit = 1: DUT output, so TB releases the pin.
      //    ctrl bit = 0: DUT input, so TB drives external_value.
      gpio_drv = external_value;
      gpio_oe  = ~ctrl_value;
      $display("[%0t] TB_INFO: CASE%0d gpio_drv=0x%02h gpio_oe=0x%02h",
               $time, case_id, vec8_to_byte(gpio_drv), vec8_to_byte(gpio_oe));

      // Wait until GPIO pin values are latched into lgpio and llgpio.
      repeat (4) @(posedge clk_i);
      #2;

      gpio_now = vec8_to_byte(gpio);
      $display("[%0t] TB_INFO: CASE%0d gpio_now=0x%02h", $time, case_id, gpio_now);
      check_equal8("GPIO pin value must match expected mixed input/output value",
                   gpio_now, expected_gpio_value);

      // 5. GPIO status readback from line register address.
      wb_read(1'b1, gpio_read);
      check_equal8("GPIO status readback must match expected GPIO value",
                   gpio_read, expected_gpio_value);

      $display("[%0t] TB_PATH: CASE%0d normal GPIO sequence end", $time, case_id);
    end
  endtask

  initial begin
    pass_count   = 0;
    fail_count   = 0;
    current_case = 0;

    rst_i    = 1'b0;
    cyc_i    = 1'b0;
    stb_i    = 1'b0;
    adr_i    = 1'b0;
    we_i     = 1'b0;
    dat_i    = 8'h00;
    gpio_drv = 8'h00;
    gpio_oe  = 8'h00;

    $display("[%0t] TB_PATH: simulation start", $time);
    $display("[%0t] TB_PATH: reset sequence start", $time);

    repeat (3) @(posedge clk_i);
    #2;
    check_equal8("RESET ctrl must be 0", vec8_to_byte(uut.ctrl), 8'h00);
    check_equal8("RESET line must be 0", vec8_to_byte(uut.line), 8'h00);
    check_equal1("RESET ack_o must be 0", ack_o, 1'b0);

    rst_i = 1'b1;
    $display("[%0t] TB_PATH: reset released", $time);
    repeat (2) @(posedge clk_i);

    // CASE1: lower 4 bits output, upper 4 bits input.
    // gpio[8:5]=1010 from TB, gpio[4:1]=0101 from DUT -> 0xA5.
    run_normal_case(1, 8'h0F, 8'h05, 8'hA0, 8'hA5);

    // CASE2: same direction as CASE1, but input/output values are inverted.
    // gpio[8:5]=0101 from TB, gpio[4:1]=1010 from DUT -> 0x5A.
    run_normal_case(2, 8'h0F, 8'h0A, 8'h50, 8'h5A);

    // CASE3: upper 4 bits output, lower 4 bits input.
    // gpio[8:5]=1010 from DUT, gpio[4:1]=0101 from TB -> 0xA5.
    run_normal_case(3, 8'hF0, 8'hA0, 8'h05, 8'hA5);

    // CASE4: all GPIO pins are output pins.
    // The GPIO status readback must follow line_value.
    run_normal_case(4, 8'hFF, 8'h3C, 8'h00, 8'h3C);

    // CASE5: all GPIO pins are input pins.
    // line_value is written, but the GPIO pin value must follow external_value.
    run_normal_case(5, 8'h00, 8'hFF, 8'hC3, 8'hC3);

    $display("[%0t] TB_SUMMARY: pass=%0d fail=%0d", $time, pass_count, fail_count);
    if (fail_count == 0)
      $display("[%0t] TB_RESULT: PASS", $time);
    else
      $display("[%0t] TB_RESULT: FAIL", $time);

    #50;
    $finish;
  end

endmodule
