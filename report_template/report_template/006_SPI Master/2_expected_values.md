# SPI Master回路 期待値表

## テスト条件
- クロック周期: `10 ns`
- `CLKS_PER_BIT`: `10`
- UART 1bit期間: `100 ns`
- フレーム形式: `8E1`
  - スタートビット 1bit
  - データ 8bit
  - 偶数パリティ 1bit
  - ストップビット 1bit

## 期待値表

| ケースID | テスト目的 | 入力 | 期待される出力 |
| --- | --- | --- | --- |
| CASE1 | 正常な送受信 | `pulse_start(8'h28)` | `rx_done=1` が1クロックだけ立つ、`rx_data=8'h28`、`rx_data_valid=1`、`rx_parity_error=0`、`rx_framing_error=0`、`rx_overrun_error=0` |

## 実シミュレーション結果
Vivado の実行ログより、上記の全ケースが期待どおりに確認できた。

| ケースID | シミュレーション結果 | 判定 |
| --- | --- | --- |
| CASE1 | `rx_data=0x28`、`rx_done=1`、`parity_error=0`、`framing_error=0` を確認 | 合格 |

## フレーム単位の期待値

### CASE1: データ `8'h28`
- 2進数表現: `0010_1000`
- LSB first の送信順: `0,0,0,1,0,1,0,0`
- `1` の個数: `2`
- 偶数パリティ bit: `0`
- フレーム全体: `0(start), 0,0,0,1,0,1,0,0, 0(parity), 1(stop)`

## 期待されるログ出力
- 送信側 RTL:
  - `uart_tx PATH: IDLE->START`
  - `uart_tx PATH: DATA->PARITY`
  - `uart_tx PATH: STOP->IDLE tx_complete`
- 受信側 RTL:
  - `uart_rx PATH: IDLE->START`
  - `uart_rx PATH: START->DATA`
  - `uart_rx PATH: PARITY->STOP`
  - `uart_rx PATH: STOP->IDLE rx_done=1 ...`
  - `uart_rx PATH: STOP->IDLE error framing=... parity=...`
- テストベンチ:
  - `TB_PATH: CASE1 ...`
  - `TB_PATH: CASE2 ...`
  - `TB_PATH: CASE3 ...`
  - `TB_PATH: CASE4 ...`
  - `TB_SUMMARY: pass=... fail=...`
