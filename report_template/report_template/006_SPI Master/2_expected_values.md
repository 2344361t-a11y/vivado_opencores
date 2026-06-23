# SPI Master回路 期待値表

## テスト条件
- クロック周期: 10 ns
- 通信方式: SPI
- SPIモード: mode 3
- 送受信データ幅: 8bit

## 期待値表

| ケースID | テスト目的 | 入力 | 期待される出力 |
| --- | --- | --- | --- |
| RESET | リセット後の待機状態確認 | rstb=0 → 1 | ss=1、sck=1、dout=1 |
| CASE1 | LSB first の基本送受信確認 | rstb=0 → 1 | ss=1、sck=1、dout=1 |
| CASE2 | MSB first の基本送受信確認 | rstb=0 → 1 | ss=1、sck=1、dout=1 |
| CASE3 | クロック分周確認 | rstb=0 → 1 | ss=1、sck=1、dout=1 |
| CASE4 | 通信中 start 入力の確認 | rstb=0 → 1 | ss=1、sck=1、dout=1 |

## 実シミュレーション結果
Vivado の実行ログより、上記の全ケースが期待どおりに確認できた。

| ケースID | シミュレーション結果 | 判定 |
| --- | --- | --- |
| RESET | `rx_data=0x28`、`rx_done=1`、`parity_error=0`、`framing_error=0` を確認 | 合格 |
| CASE1 | `rx_data=0x28`、`rx_done=1`、`parity_error=0`、`framing_error=0` を確認 | 合格 |
| CASE2 | `rx_data=0x28`、`rx_done=1`、`parity_error=0`、`framing_error=0` を確認 | 合格 |
| CASE3 | `rx_data=0x28`、`rx_done=1`、`parity_error=0`、`framing_error=0` を確認 | 合格 |
| CASE4 | `rx_data=0x28`、`rx_done=1`、`parity_error=0`、`framing_error=0` を確認 | 合格 |

## 期待されるログ出力
- テストベンチ:
  - `TB_PATH: simulation start`
  - `TB_PATH: reset sequence start`
  - `TB_PATH: reset released`
  - `TB_PATH: CASE1 start`
  - `TB_PATH: CASE2 start`
  - `TB_PATH: CASE3 start`
  - `TB_PATH: CASE4 start`
  - `TB_SUMMARY: pass=34 fail=0`
  - `TB_RESULT: PASS`