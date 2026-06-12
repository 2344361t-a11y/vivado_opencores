# GPIO回路 評価報告書

## 評価対象
- 対象回路:
  - `gpio_controller.v`
- テストベンチ:
  - `tb_gpio_controller.v`

## 評価目的
- 選定した GPIO 回路が、期待値表どおりに動作することを確認する。
- シミュレーションログから、以下の両方が判別できることを確認する。
  - 回路の入出力値
  - 回路本体およびテストベンチの実行パス

## 評価項目
- 正常送受信
- `data_read` による `data_valid` のクリア

## 合格条件
- `tb_gpio_controller.v` 内のチェックで `TB_FAIL` が 0 件であること
- 最終サマリに `fail=0` と表示されること
- シミュレーションログに `TB_PATH`、`TB_INFO`、`uart_tx PATH`、`uart_rx PATH` が含まれること

## Vivadoでの実行手順
1. Vivado プロジェクトを開く。
2. `tb_gpio_controller.v` を simulation top に設定する。
3. Behavioral Simulation を実行する。
4. Console ログを保存する。
5. 以下の信号を含む波形を保存する。
   - `tx_line`
   - `rx_line`
   - `rx_data`
   - `rx_done`

## シミュレーションログ
Vivado 実行時のログを以下に示す。

```text
[0] TB_PATH: reset sequence start
[0] GPIO_CTRL PATH: reset direction=00 output=00 wb_ack=0
[5000] GPIO_CTRL PATH: reset direction=00 output=00 wb_ack=0
[15000] GPIO_CTRL PATH: reset direction=00 output=00 wb_ack=0
[25000] GPIO_CTRL PATH: reset direction=00 output=00 wb_ack=0
[36000] TB_PASS: RESET ready must be 1
[36000] TB_PASS: RESET wb_ack must be 0
[36000] TB_PASS: RESET all pins must be input
[36000] TB_PATH: CASE1 lower nibble output upper input start
[40000] TB_CASE: CASE1 lower output bus_write addr=0 data=0f cycle=1
[45000] GPIO_CTRL PATH: write_direction addr=00 wb_wdata=0f direction=0f
[46000] TB_PASS: WISHBONE write must assert done with ack
[46000] TB_INFO: CASE1 lower output write_ack wb_ack=1 ready=1 cycle=2
[60000] TB_CASE: CASE1 lower output bus_write addr=1 data=05 cycle=3
[65000] GPIO_CTRL PATH: write_line addr=01 wb_wdata=05 output=05
[66000] TB_PASS: WISHBONE write must assert done with ack
[66000] TB_INFO: CASE1 lower output write_ack wb_ack=1 ready=1 cycle=4
[80000] TB_CASE: CASE1 lower output bus_read addr=0 cycle=5
[85000] GPIO_CTRL DATA: read_direction addr=00 direction=0f wb_rdata=0f
[86000] TB_PASS: WISHBONE read must assert done with ack
[86000] TB_INFO: CASE1 lower output read_ack wb_ack=1 wb_rdata=0f input_data=00 cycle=6
[96000] TB_PASS: direction register readback must match written value
[96000] TB_PASS: CASE1 lower nibble must be output enabled
[96000] TB_PASS: CASE1 output register must be 05
[100000] TB_CASE: external_gpio drive=a0 oe=f0
[130000] TB_CASE: CASE1 mixed read bus_read addr=1 cycle=10
[135000] GPIO_CTRL DATA: read_line addr=01 gpio_sample=a5 wb_rdata=a5
[136000] TB_PASS: WISHBONE read must assert done with ack
[136000] TB_PASS: line register read must assert read_valid
[136000] TB_INFO: CASE1 mixed read read_ack wb_ack=1 wb_rdata=a5 input_data=a5 cycle=11
[146000] TB_PASS: line register read data must match expected pin value
[146000] TB_PASS: input_data must match expected pin value
[146000] TB_PATH: CASE2 upper nibble output lower input start
[150000] TB_CASE: CASE2 upper output bus_write addr=0 data=f0 cycle=12
[155000] GPIO_CTRL PATH: write_direction addr=00 wb_wdata=f0 direction=f0
[156000] TB_PASS: WISHBONE write must assert done with ack
[156000] TB_INFO: CASE2 upper output write_ack wb_ack=1 ready=1 cycle=13
[170000] TB_CASE: CASE2 upper output bus_write addr=1 data=c0 cycle=14
[175000] GPIO_CTRL PATH: write_line addr=01 wb_wdata=c0 output=c0
[176000] TB_PASS: WISHBONE write must assert done with ack
[176000] TB_INFO: CASE2 upper output write_ack wb_ack=1 ready=1 cycle=15
[190000] TB_CASE: CASE2 upper output bus_read addr=0 cycle=16
[195000] GPIO_CTRL DATA: read_direction addr=00 direction=f0 wb_rdata=f0
[196000] TB_PASS: WISHBONE read must assert done with ack
[196000] TB_INFO: CASE2 upper output read_ack wb_ack=1 wb_rdata=f0 input_data=a5 cycle=17
[206000] TB_PASS: direction register readback must match written value
[206000] TB_PASS: CASE2 upper nibble must be output enabled
[206000] TB_PASS: CASE2 output register must be C0
[210000] TB_CASE: external_gpio drive=0a oe=0f
[240000] TB_CASE: CASE2 mixed read bus_read addr=1 cycle=21
[245000] GPIO_CTRL DATA: read_line addr=01 gpio_sample=ca wb_rdata=ca
[246000] TB_PASS: WISHBONE read must assert done with ack
[246000] TB_PASS: line register read must assert read_valid
[246000] TB_INFO: CASE2 mixed read read_ack wb_ack=1 wb_rdata=ca input_data=ca cycle=22
[256000] TB_PASS: line register read data must match expected pin value
[256000] TB_PASS: input_data must match expected pin value
[256000] TB_PATH: CASE3 all input start
[260000] TB_CASE: CASE3 all input bus_write addr=0 data=00 cycle=23
[265000] GPIO_CTRL PATH: write_direction addr=00 wb_wdata=00 direction=00
[266000] TB_PASS: WISHBONE write must assert done with ack
[266000] TB_INFO: CASE3 all input write_ack wb_ack=1 ready=1 cycle=24
[280000] TB_CASE: CASE3 all input bus_write addr=1 data=ff cycle=25
[285000] GPIO_CTRL PATH: write_line addr=01 wb_wdata=ff output=ff
[286000] TB_PASS: WISHBONE write must assert done with ack
[286000] TB_INFO: CASE3 all input write_ack wb_ack=1 ready=1 cycle=26
[300000] TB_CASE: CASE3 all input bus_read addr=0 cycle=27
[305000] GPIO_CTRL DATA: read_direction addr=00 direction=00 wb_rdata=00
[306000] TB_PASS: WISHBONE read must assert done with ack
[306000] TB_INFO: CASE3 all input read_ack wb_ack=1 wb_rdata=00 input_data=ca cycle=28
[316000] TB_PASS: direction register readback must match written value
[316000] TB_PASS: CASE3 all pins must be input
[320000] TB_CASE: external_gpio drive=3c oe=ff
[350000] TB_CASE: CASE3 input read bus_read addr=1 cycle=32
[355000] GPIO_CTRL DATA: read_line addr=01 gpio_sample=3c wb_rdata=3c
[356000] TB_PASS: WISHBONE read must assert done with ack
[356000] TB_PASS: line register read must assert read_valid
[356000] TB_INFO: CASE3 input read read_ack wb_ack=1 wb_rdata=3c input_data=3c cycle=33
[366000] TB_PASS: line register read data must match expected pin value
[366000] TB_PASS: input_data must match expected pin value
[366000] TB_PATH: CASE4 all output start
[370000] TB_CASE: CASE4 all output bus_write addr=0 data=ff cycle=34
[375000] GPIO_CTRL PATH: write_direction addr=00 wb_wdata=ff direction=ff
[376000] TB_PASS: WISHBONE write must assert done with ack
[376000] TB_INFO: CASE4 all output write_ack wb_ack=1 ready=1 cycle=35
[390000] TB_CASE: CASE4 all output bus_write addr=1 data=96 cycle=36
[395000] GPIO_CTRL PATH: write_line addr=01 wb_wdata=96 output=96
[396000] TB_PASS: WISHBONE write must assert done with ack
[396000] TB_INFO: CASE4 all output write_ack wb_ack=1 ready=1 cycle=37
[410000] TB_CASE: CASE4 all output bus_read addr=0 cycle=38
[415000] GPIO_CTRL DATA: read_direction addr=00 direction=ff wb_rdata=ff
[416000] TB_PASS: WISHBONE read must assert done with ack
[416000] TB_INFO: CASE4 all output read_ack wb_ack=1 wb_rdata=ff input_data=3c cycle=39
[426000] TB_PASS: direction register readback must match written value
[426000] TB_PASS: CASE4 all pins must be output
[430000] TB_CASE: external_gpio drive=00 oe=00
[460000] TB_CASE: CASE4 output readback bus_read addr=1 cycle=43
[465000] GPIO_CTRL DATA: read_line addr=01 gpio_sample=96 wb_rdata=96
[466000] TB_PASS: WISHBONE read must assert done with ack
[466000] TB_PASS: line register read must assert read_valid
[466000] TB_INFO: CASE4 output readback read_ack wb_ack=1 wb_rdata=96 input_data=96 cycle=44
[476000] TB_PASS: line register read data must match expected pin value
[476000] TB_PASS: input_data must match expected pin value
[476000] TB_PATH: CASE5 wb_cyc only invalid access start
[480000] TB_CASE: CASE5 cyc only invalid_bus_access cyc=1 stb=0 addr=0 we=1 data=00 cycle=45
[486000] TB_PASS: invalid bus access must not assert wb_ack
[486000] TB_PASS: invalid bus access must not assert done
[486000] TB_PASS: invalid bus access must not assert busy
[486000] TB_PASS: invalid bus access must keep ready asserted
[486000] TB_PASS: invalid bus access must not change direction_reg
[486000] TB_PASS: invalid bus access must not change output_reg
[496000] TB_PATH: CASE6 wb_stb only invalid access start
[500000] TB_CASE: CASE6 stb only invalid_bus_access cyc=0 stb=1 addr=0 we=1 data=00 cycle=47
[506000] TB_PASS: invalid bus access must not assert wb_ack
[506000] TB_PASS: invalid bus access must not assert done
[506000] TB_PASS: invalid bus access must not assert busy
[506000] TB_PASS: invalid bus access must keep ready asserted
[506000] TB_PASS: invalid bus access must not change direction_reg
[506000] TB_PASS: invalid bus access must not change output_reg
[516000] TB_PATH: CASE9 reset during operation start
[516000] TB_PATH: CASE9 mid reset reset during operation start
[520000] TB_CASE: CASE9 mid reset bus_write addr=0 data=aa cycle=49
[525000] GPIO_CTRL PATH: write_direction addr=00 wb_wdata=aa direction=aa
[526000] TB_PASS: WISHBONE write must assert done with ack
[526000] TB_INFO: CASE9 mid reset write_ack wb_ack=1 ready=1 cycle=50
[540000] TB_CASE: CASE9 mid reset bus_write addr=1 data=55 cycle=51
[545000] GPIO_CTRL PATH: write_line addr=01 wb_wdata=55 output=55
[546000] TB_PASS: WISHBONE write must assert done with ack
[546000] TB_INFO: CASE9 mid reset write_ack wb_ack=1 ready=1 cycle=52
[556000] TB_PASS: CASE9 pre-reset direction_reg must be AA
[556000] TB_PASS: CASE9 pre-reset output_reg must be 55
[560000] TB_CASE: CASE9 mid reset assert reset while bus access is active
[561000] GPIO_CTRL PATH: reset direction=00 output=00 wb_ack=0
[562000] TB_PASS: CASE9 reset must clear direction_reg
[562000] TB_PASS: CASE9 reset must clear output_reg
[562000] TB_PASS: CASE9 reset must clear input_data
[562000] TB_PASS: CASE9 reset must clear wb_rdata
[562000] TB_PASS: CASE9 reset must clear wb_ack
[562000] TB_PASS: CASE9 reset must clear done
[562000] TB_PASS: CASE9 reset must clear read_valid
[565000] GPIO_CTRL PATH: reset direction=00 output=00 wb_ack=0
[575000] GPIO_CTRL PATH: reset direction=00 output=00 wb_ack=0
[586000] TB_PASS: CASE9 reset release must make ready 1
[586000] TB_PASS: CASE9 reset release must keep wb_ack 0
[586000] TB_PASS: CASE9 reset release must keep direction_reg 00
[586000] TB_PASS: CASE9 reset release must keep output_reg 00
[586000] TB_PASS: CASE9 reset release must keep input_data 00
[586000] TB_SUMMARY: pass=69 fail=0
```

## 評価結果まとめ
### CASE1 正常送受信
| 項目 | 入力条件 | 期待値 | 実測値 | 判定 |
| --- | --- | --- | --- | --- |
| 送受信 | `pulse_start(8'h28)` | `rx_data=8'h28` | `rx_data=8'h28` | 合格 |
| 受信完了 | `pulse_start(8'h28)` | `rx_done=1` | `rx_done=1` | 合格 |
| 有効データ保持 | 正常受信後 | `rx_data_valid=1` | `rx_data_valid=1` | 合格 |
| 読出し後クリア | `pulse_data_read()` 後 | `rx_data_valid=0` | `rx_data_valid=0` | 合格 |

### 総括
| 項目 | 結果 |
| --- | --- |
| 総判定 | 合格 |
| 判定数 | `pass=69` |
| 不合格数 | `fail=0` |
| 結論 | 対象回路の主要機能は期待値どおりに動作したことを確認した |

## 波形キャプチャ貼付欄

### 図1 下位4bit出力・上位4bit入力波形
- 対象ケース: CASE1
- 推奨表示信号:
  - `wb_cyc`
  - `wb_stb`
  - `wb_addr`
  - `wb_we`
  - `wb_wdata`
  - `wb_rdata`
  - `wb_ack`
  - `done`
  - `direction_reg`
  - `outpot_reg`
  - `gpio`
  - `input_data`
  - `read_valid`
- 推奨表示時間帯: `36 ns` から `150 ns`
- 説明:
  - 正常な送受信により `rx_data=0x28`、`rx_done=1` となることを確認した。

![図1 下位4bit出力・上位4bit入力波形](./images/case1.png)
