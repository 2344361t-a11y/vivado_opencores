`timescale 1ns / 1ps

module simple_gpio_tb;

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

  // テストベンチ側からgpioを駆動するための信号
  reg  [8:1]  gpio_drv;
  reg  [8:1]  gpio_oe;   // 1ならTBが駆動、0ならZ

  // tri-state接続
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

  // クロック生成
  initial begin
    clk_i = 0;
    forever #5 clk_i = ~clk_i; // 10ns周期
  end

  // Wishbone 1サイクル書き込み
  task wb_write;
    input adr;
    input [7:0] data;
    begin
      @(negedge clk_i);
      adr_i = adr;
      dat_i = data;
      we_i  = 1'b1;
      cyc_i = 1'b1;
      stb_i = 1'b1;

      @(negedge clk_i);
      cyc_i = 1'b0;
      stb_i = 1'b0;
      we_i  = 1'b0;
      adr_i = 1'b0;
      dat_i = 8'h00;
    end
  endtask

  // Wishbone 1サイクル読み出し
  task wb_read;
    input adr;
    begin
      @(negedge clk_i);
      adr_i = adr;
      we_i  = 1'b0;
      cyc_i = 1'b1;
      stb_i = 1'b1;

      @(negedge clk_i);
      cyc_i = 1'b0;
      stb_i = 1'b0;
      adr_i = 1'b0;
    end
  endtask

  initial begin
    // 初期値
    rst_i    = 0;
    cyc_i    = 0;
    stb_i    = 0;
    adr_i    = 0;
    we_i     = 0;
    dat_i    = 8'h00;
    gpio_drv = 8'h00;
    gpio_oe  = 8'h00;  // 最初はTB側は駆動しない

    // リセット解除
    #20;
    rst_i = 1;

    // -----------------------------
    // 1) ctrlレジスタに 0x0F を書く
    //    下位4bitを出力, 上位4bitを入力にする
    // -----------------------------
    wb_write(1'b0, 8'h0F);

    // -----------------------------
    // 2) lineレジスタに 0x05 を書く
    //    出力ピンに値を出す
    // -----------------------------
    wb_write(1'b1, 8'h05);

    // -----------------------------
    // 3) 上位4bit入力側に外部値を与える
    //    gpio[8:5] = 1010
    // -----------------------------
    gpio_oe[8]  = 1'b1; gpio_drv[8] = 1'b1;
    gpio_oe[7]  = 1'b1; gpio_drv[7] = 1'b0;
    gpio_oe[6]  = 1'b1; gpio_drv[6] = 1'b1;
    gpio_oe[5]  = 1'b1; gpio_drv[5] = 1'b0;

    // 下位4bitはDUT出力なのでTBは駆動しない
    gpio_oe[4:1] = 4'b0000;

    // 少し待つ
    #40;

    // -----------------------------
    // 4) ctrl読み出し
    // -----------------------------
    wb_read(1'b0);

    // -----------------------------
    // 5) line読み出し
    //    adr_i=1 のとき dat_o は llgpio を返す実装
    // -----------------------------
    wb_read(1'b1);

    #50;
    $finish;
  end

endmodule