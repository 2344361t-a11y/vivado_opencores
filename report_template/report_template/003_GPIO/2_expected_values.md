# GPIO回路 期待値表

## テスト条件
- クロック周期: `10 ns`
- GPIO幅: `8 bit`
- 対象GPIO: `gpio[7:0]`
- バス形式: WISHBONE-style bus

## 期待値表

| ケースID | テスト目的 | 入力 | 期待される出力 |
| --- | --- | --- | --- |
| RESET | リセット後の初期状態確認 |  | `ready=1`、`wb_ack=0`、`direction_reg=8'h00` |
| CASE1 | 下位4bit出力・上位4bit入力の確認 |  | `direction_reg=8'h0F`、`output_reg=8'h05`、`wb_rdata=8'hA5`、`input_data=8'hA5`、`read_valid=1` |
| CASE2 | 上位4bit出力・下位4bit入力の確認 |  | `direction_reg=8'hF0`、`output_reg=8'hC0`、`wb_rdata=8'hCA`、`input_data=8'hCA`、`read_valid=1` |
| CASE3 | 全GPIO入力の確認 |  | `direction_reg=8'h00`、`output_reg=8'hFF`、`wb_rdata=8'h3C`、`input_data=8'h3C`、`read_valid=1` |
| CASE4 | 全GPIO出力の確認 |  | `direction_reg=8'hFF`、`output_reg=8'h96`、`wb_rdata=8'h96`、`input_data=8'h96`、`read_valid=1` |
| CASE5 | wb_cyc のみ有効な無効アクセス確認 |  | `wb_ack=0`、`done=0`、`busy=0`、`ready=1`、`direction_reg` と `output_reg` は変化しない |
| CASE6 | wb_stb のみ有効な無効アクセス確認 |  | `wb_ack=0`、`done=0`、`busy=0`、`ready=1`、`direction_reg` と `output_reg` は変化しない |
| CASE7 | 動作途中リセット確認 |  | `direction_reg=8'h00`、`output_reg=8'h00`、`input_data=8'h00`、`wb_rdata=8'h00`、`wb_ack=0`、`done=0`、`read_valid=0`、リセット解除後 `ready=1` |

## 実シミュレーション結果
Vivado の実行ログより、上記の全ケースが期待どおりに確認できた。

| ケースID | シミュレーション結果 | 判定 |
| --- | --- | --- |
| RESET | `ready=1`、`wb_ack=0`、`direction_reg=8'h00` を確認 | 合格 |
| CASE1 | `direction_reg=8'h0F`、`output_reg=8'h05`、`wb_rdata=8'hA5`、`input_data=8'hA5` を確認 | 合格 |
| CASE2 | `direction_reg=8'hF0`、`output_reg=8'hC0`、`wb_rdata=8'hCA`、`input_data=8'hCA` を確認 | 合格 |
| CASE3 | `direction_reg=8'h00`、`output_reg=8'hFF`、`wb_rdata=8'h3C`、`input_data=8'h3C` を確認 | 合格 |
| CASE4 | `direction_reg=8'hFF`、`output_reg=8'h96`、`wb_rdata=8'h96`、`input_data=8'h96` を確認 | 合格 |
| CASE5 | `wb_cyc=1`、`wb_stb=0` のとき、`wb_ack=0`、`done=0`、`busy=0`、`ready=1`、レジスタ不変を確認 | 合格 |
| CASE6 | `wb_cyc=0`、`wb_stb=1` のとき、`wb_ack=0`、`done=0`、`busy=0`、`ready=1`、レジスタ不変を確認 | 合格 |
| CASE7 | 動作途中リセットにより、内部レジスタおよびステータス信号が初期化されることを確認 | 合格 |

## 期待されるログ出力
- DUT:
  - GPIO_CTRL PATH: reset direction=00 output=00 wb_ack=0
  - GPIO_CTRL PATH: write_direction addr=00 ...
  - GPIO_CTRL PATH: write_line addr=01 ...
  - GPIO_CTRL DATA: read_direction addr=00 ...
  - GPIO_CTRL DATA: read_line addr=01 ...
- テストベンチ:
  - TB_PATH: CASE1 ...
  - TB_PATH: CASE2 ...
  - TB_PATH: CASE3 ...
  - TB_PATH: CASE4 ...
  - TB_PATH: CASE5 ...
  - TB_PATH: CASE6 ...
  - TB_PATH: CASE9 ...
  - TB_SUMMARY: pass=69 fail=0