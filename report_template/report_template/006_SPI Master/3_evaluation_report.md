# SPI Master回路 評価報告書

## 評価対象
- 対象回路:
  - `spi_master.v`
- テストベンチ:
  - `tb_spi_master.v`

## 評価目的
- 選定した SPI Master 回路が、期待値表どおりに動作することを確認する。

## 評価項目
- リセット後の待機状態の確認
- LSB first の基本送受信
- MSB firat の基本送受信
- `cdiv`によるSPIクロック分周確認
- 通信中`start`入力時の動作確認

## 合格条件
- `tb_spi_master.v` 内のチェックで TB_FAIL が 0 件であること
- 最終サマリに fail=0 と表示されること
- 最終結果に TB_RESULT: PASS と表示されること
- シミュレーションログに TB_PATH、TB_CASE、TB_INFO、TB_DUT_PATH、TB_PASS が含まれること
- 各テストケースにおいて、期待値表に示した出力が確認できること

## Vivadoでの実行手順
1. Vivado プロジェクトを開く。
2. `tb_spi_master.v` を simulation top に設定する。
3. Behavioral Simulation を実行する。
4. Console ログを保存する。
5. 以下の信号を含む波形を保存する。
   - `tb_rstb`
   - `tb_clk`
   - `tb_start`
   - `tb_mlb`
   - `tb_cdiv[1:0]`
   - `tb_tdat[7:0]`
   - `tb_din`
   - `tb_ss`
   - `tb_sck`
   - `tb_dout`
   - `tb_done`
   - `tb_rdata[7:0]`

## シミュレーションログ
Vivado 実行時のログを以下に示す。

```text
[0 ns] TB_PATH: simulation start
[0 ns] TB_PATH: reset sequence start
[36 ns] TB_PATH: reset released
[95 ns] TB_DUT_PATH: after reset cur=0 ss=1 sck=1 dout=1 done=x
[95 ns] TB_PASS: RESET ss must be 1 in idle
[95 ns] TB_PASS: RESET sck must be 1 in SPI mode 3 idle
[95 ns] TB_PASS: RESET dout must be 1 after clear
[95 ns] TB_PATH: CASE1_LSB_BASIC start
[136 ns] TB_CASE: pulse_start tdat=0x96 mlb=0 cdiv=00
[146 ns] TB_PASS: CASE1_LSB_BASIC done must clear after start
[146 ns] TB_INFO: CASE1_LSB_BASIC ss active low detected
[146 ns] TB_PASS: CASE1_LSB_BASIC ss must be 0 during transfer
[151 ns] TB_INFO: CASE1_LSB_BASIC bit0 dout=0 din_set=0 nbit=0
[191 ns] TB_INFO: CASE1_LSB_BASIC bit1 dout=1 din_set=0 nbit=1
[210 ns] TB_INFO: CASE1_LSB_BASIC measured_sck_period=40 ns
[231 ns] TB_INFO: CASE1_LSB_BASIC bit2 dout=1 din_set=1 nbit=2
[271 ns] TB_INFO: CASE1_LSB_BASIC bit3 dout=0 din_set=1 nbit=3
[311 ns] TB_INFO: CASE1_LSB_BASIC bit4 dout=1 din_set=1 nbit=4
[351 ns] TB_INFO: CASE1_LSB_BASIC bit5 dout=0 din_set=1 nbit=5
[391 ns] TB_INFO: CASE1_LSB_BASIC bit6 dout=0 din_set=0 nbit=6
[431 ns] TB_INFO: CASE1_LSB_BASIC bit7 dout=1 din_set=0 nbit=7
[455 ns] TB_INFO: CASE1_LSB_BASIC done detected rdata=0x3c
[455 ns] TB_INFO: CASE1_LSB_BASIC expected_dout = 0,1,1,0,1,0,0,1
[455 ns] TB_INFO: CASE1_LSB_BASIC captured_dout = 0,1,1,0,1,0,0,1
[455 ns] TB_PASS: CASE1_LSB_BASIC dout bit order must match tdat
[455 ns] TB_PASS: CASE1_LSB_BASIC done must be 1 after 8bit transfer
[455 ns] TB_PASS: CASE1_LSB_BASIC rdata must match received din sequence
[455 ns] TB_PASS: CASE1_LSB_BASIC sck period must match cdiv setting
[465 ns] TB_DUT_PATH: CASE1_LSB_BASIC idle check cur=3 ss=1 sck=1 done=1 nbit=0
[465 ns] TB_PASS: CASE1_LSB_BASIC ss must return to 1 after transfer
[465 ns] TB_PASS: CASE1_LSB_BASIC sck must return to 1 after transfer
[515 ns] TB_PATH: CASE2_MSB_BASIC start
[556 ns] TB_CASE: pulse_start tdat=0x96 mlb=1 cdiv=00
[566 ns] TB_PASS: CASE2_MSB_BASIC done must clear after start
[566 ns] TB_INFO: CASE2_MSB_BASIC ss active low detected
[566 ns] TB_PASS: CASE2_MSB_BASIC ss must be 0 during transfer
[571 ns] TB_INFO: CASE2_MSB_BASIC bit0 dout=1 din_set=0 nbit=0
[611 ns] TB_INFO: CASE2_MSB_BASIC bit1 dout=0 din_set=0 nbit=1
[651 ns] TB_INFO: CASE2_MSB_BASIC bit2 dout=0 din_set=1 nbit=2
[691 ns] TB_INFO: CASE2_MSB_BASIC bit3 dout=1 din_set=1 nbit=3
[731 ns] TB_INFO: CASE2_MSB_BASIC bit4 dout=0 din_set=1 nbit=4
[771 ns] TB_INFO: CASE2_MSB_BASIC bit5 dout=1 din_set=1 nbit=5
[811 ns] TB_INFO: CASE2_MSB_BASIC bit6 dout=1 din_set=0 nbit=6
[851 ns] TB_INFO: CASE2_MSB_BASIC bit7 dout=0 din_set=0 nbit=7
[875 ns] TB_INFO: CASE2_MSB_BASIC done detected rdata=0x3c
[875 ns] TB_INFO: CASE2_MSB_BASIC expected_dout = 1,0,0,1,0,1,1,0
[875 ns] TB_INFO: CASE2_MSB_BASIC captured_dout = 1,0,0,1,0,1,1,0
[875 ns] TB_PASS: CASE2_MSB_BASIC dout bit order must match tdat
[875 ns] TB_PASS: CASE2_MSB_BASIC done must be 1 after 8bit transfer
[875 ns] TB_PASS: CASE2_MSB_BASIC rdata must match received din sequence
[885 ns] TB_DUT_PATH: CASE2_MSB_BASIC idle check cur=3 ss=1 sck=1 done=1 nbit=0
[885 ns] TB_PASS: CASE2_MSB_BASIC ss must return to 1 after transfer
[885 ns] TB_PASS: CASE2_MSB_BASIC sck must return to 1 after transfer
[935 ns] TB_PATH: CASE3_CDIV_01 start
[976 ns] TB_CASE: pulse_start tdat=0x96 mlb=0 cdiv=01
[986 ns] TB_PASS: CASE3_CDIV_01 done must clear after start
[986 ns] TB_INFO: CASE3_CDIV_01 ss active low detected
[986 ns] TB_PASS: CASE3_CDIV_01 ss must be 0 during transfer
[1011 ns] TB_INFO: CASE3_CDIV_01 bit0 dout=0 din_set=0 nbit=0
[1091 ns] TB_INFO: CASE3_CDIV_01 bit1 dout=1 din_set=0 nbit=1
[1130 ns] TB_INFO: CASE3_CDIV_01 measured_sck_period=80 ns
[1171 ns] TB_INFO: CASE3_CDIV_01 bit2 dout=1 din_set=1 nbit=2
[1251 ns] TB_INFO: CASE3_CDIV_01 bit3 dout=0 din_set=1 nbit=3
[1331 ns] TB_INFO: CASE3_CDIV_01 bit4 dout=1 din_set=1 nbit=4
[1411 ns] TB_INFO: CASE3_CDIV_01 bit5 dout=0 din_set=1 nbit=5
[1491 ns] TB_INFO: CASE3_CDIV_01 bit6 dout=0 din_set=0 nbit=6
[1571 ns] TB_INFO: CASE3_CDIV_01 bit7 dout=1 din_set=0 nbit=7
[1615 ns] TB_INFO: CASE3_CDIV_01 done detected rdata=0x3c
[1615 ns] TB_INFO: CASE3_CDIV_01 expected_dout = 0,1,1,0,1,0,0,1
[1615 ns] TB_INFO: CASE3_CDIV_01 captured_dout = 0,1,1,0,1,0,0,1
[1615 ns] TB_PASS: CASE3_CDIV_01 dout bit order must match tdat
[1615 ns] TB_PASS: CASE3_CDIV_01 done must be 1 after 8bit transfer
[1615 ns] TB_PASS: CASE3_CDIV_01 rdata must match received din sequence
[1615 ns] TB_PASS: CASE3_CDIV_01 sck period must match cdiv setting
[1625 ns] TB_DUT_PATH: CASE3_CDIV_01 idle check cur=3 ss=1 sck=1 done=1 nbit=0
[1625 ns] TB_PASS: CASE3_CDIV_01 ss must return to 1 after transfer
[1625 ns] TB_PASS: CASE3_CDIV_01 sck must return to 1 after transfer
[1675 ns] TB_PATH: CASE4_MID_START start
[1716 ns] TB_CASE: pulse_start tdat=0x96 mlb=0 cdiv=00
[1726 ns] TB_PASS: CASE4_MID_START done must clear after start
[1726 ns] TB_INFO: CASE4_MID_START ss active low detected
[1726 ns] TB_PASS: CASE4_MID_START ss must be 0 during transfer
[1731 ns] TB_INFO: CASE4_MID_START bit0 dout=0 din_set=0 nbit=0
[1771 ns] TB_INFO: CASE4_MID_START bit1 dout=1 din_set=0 nbit=1
[1776 ns] TB_CASE: mid_start pulse, tdat changed to 0xff
[1811 ns] TB_INFO: CASE4_MID_START bit2 dout=1 din_set=1 nbit=2
[1851 ns] TB_INFO: CASE4_MID_START bit3 dout=0 din_set=1 nbit=3
[1891 ns] TB_INFO: CASE4_MID_START bit4 dout=1 din_set=1 nbit=4
[1931 ns] TB_INFO: CASE4_MID_START bit5 dout=0 din_set=1 nbit=5
[1971 ns] TB_INFO: CASE4_MID_START bit6 dout=0 din_set=0 nbit=6
[2011 ns] TB_INFO: CASE4_MID_START bit7 dout=1 din_set=0 nbit=7
[2035 ns] TB_INFO: CASE4_MID_START done detected rdata=0x3c
[2035 ns] TB_INFO: CASE4_MID_START expected_dout = 0,1,1,0,1,0,0,1
[2035 ns] TB_INFO: CASE4_MID_START captured_dout = 0,1,1,0,1,0,0,1
[2035 ns] TB_PASS: CASE4_MID_START dout bit order must match tdat
[2035 ns] TB_PASS: CASE4_MID_START done must be 1 after 8bit transfer
[2035 ns] TB_PASS: CASE4_MID_START rdata must match received din sequence
[2045 ns] TB_DUT_PATH: CASE4_MID_START idle check cur=3 ss=1 sck=1 done=1 nbit=0
[2045 ns] TB_PASS: CASE4_MID_START ss must return to 1 after transfer
[2045 ns] TB_PASS: CASE4_MID_START sck must return to 1 after transfer
[2045 ns] TB_PASS: CASE4_MID_START mid-start must not change current transfer
[2095 ns] TB_SUMMARY: pass=34 fail=0
[2095 ns] TB_RESULT: PASS
```

## 評価結果まとめ
### RESET リセット後の待機状態確認
| 項目 | 入力条件 | 期待値 | 実測値 | 判定 |
| --- | --- | --- | --- | --- |
| スレーブ非選択 | `pulse_start(8'h28)` | `rx_data=8'h28` | `rx_data=8'h28` | 合格 |
| SPIクロック待機値 | `pulse_start(8'h28)` | `rx_data=8'h28` | `rx_data=8'h28` | 合格 |
| スレーブ非選択 | `pulse_start(8'h28)` | `rx_data=8'h28` | `rx_data=8'h28` | 合格 |

### CASE1 リセット後の待機状態確認
| 項目 | 入力条件 | 期待値 | 実測値 | 判定 |
| --- | --- | --- | --- | --- |

### CASE2 リセット後の待機状態確認
| 項目 | 入力条件 | 期待値 | 実測値 | 判定 |
| --- | --- | --- | --- | --- |

### CASE3 リセット後の待機状態確認
| 項目 | 入力条件 | 期待値 | 実測値 | 判定 |
| --- | --- | --- | --- | --- |

### CASE4 リセット後の待機状態確認
| 項目 | 入力条件 | 期待値 | 実測値 | 判定 |
| --- | --- | --- | --- | --- |

### 総括
| 項目 | 結果 |
| --- | --- |
| 総判定 | 合格 |
| 判定数 | `pass=34` |
| 不合格数 | `fail=0` |
| 結論 | 対象回路の主要機能は期待値どおりに動作したことを確認した |

## 波形キャプチャ貼付欄

### 図1 リセット後の待機状態波形
- 対象ケース: RESET
- 推奨表示信号:
  - `tb_rstb`
  - `tb_clk`
  - `tb_start`
  - `tb_mlb`
  - `tb_cdiv[1:0]`
  - `tb_tdat[7:0]`
  - `tb_din`
  - `tb_ss`
  - `tb_sck`
  - `tb_dout`
  - `tb_done`
  - `tb_rdata[7:0]`
- 推奨表示時間帯: `1.0 us` から `1.2 us`
- 説明:
  - 

![図1 正常送受信波形](./images/case1.png)

### 図1 正常送受信波形
- 対象ケース: CASE1
- 推奨表示信号:
  - `tb_rstb`
  - `tb_clk`
  - `tb_start`
  - `tb_mlb`
  - `tb_cdiv[1:0]`
  - `tb_tdat[7:0]`
  - `tb_din`
  - `tb_ss`
  - `tb_sck`
  - `tb_dout`
  - `tb_done`
  - `tb_rdata[7:0]`
- 推奨表示時間帯: `1.0 us` から `1.2 us`
- 説明:
  - 

![図1 正常送受信波形](./images/case1.png)

### 図1 正常送受信波形
- 対象ケース: CASE1
- 推奨表示信号:
  - `tb_rstb`
  - `tb_clk`
  - `tb_start`
  - `tb_mlb`
  - `tb_cdiv[1:0]`
  - `tb_tdat[7:0]`
  - `tb_din`
  - `tb_ss`
  - `tb_sck`
  - `tb_dout`
  - `tb_done`
  - `tb_rdata[7:0]`
- 推奨表示時間帯: `1.0 us` から `1.2 us`
- 説明:
  - 

![図1 正常送受信波形](./images/case1.png)

### 図1 正常送受信波形
- 対象ケース: CASE1
- 推奨表示信号:
  - `tb_rstb`
  - `tb_clk`
  - `tb_start`
  - `tb_mlb`
  - `tb_cdiv[1:0]`
  - `tb_tdat[7:0]`
  - `tb_din`
  - `tb_ss`
  - `tb_sck`
  - `tb_dout`
  - `tb_done`
  - `tb_rdata[7:0]`
- 推奨表示時間帯: `1.0 us` から `1.2 us`
- 説明:
  - 

![図1 正常送受信波形](./images/case1.png)

### 図1 正常送受信波形
- 対象ケース: CASE1
- 推奨表示信号:
  - `tb_rstb`
  - `tb_clk`
  - `tb_start`
  - `tb_mlb`
  - `tb_cdiv[1:0]`
  - `tb_tdat[7:0]`
  - `tb_din`
  - `tb_ss`
  - `tb_sck`
  - `tb_dout`
  - `tb_done`
  - `tb_rdata[7:0]`
- 推奨表示時間帯: `1.0 us` から `1.2 us`
- 説明:
  - 

![図1 正常送受信波形](./images/case1.png)