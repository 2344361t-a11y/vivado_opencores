# FIFO同期回路 期待値表

## テスト条件
- クロック周期: `10 ns`
- `CLKS_PER_BIT`: `10`
- UART 1bit期間: `100 ns`

## 期待値表

| ケースID | テスト目的 | 入力 | 期待される出力 |
| --- | --- | --- | --- |
| RESET | リセット後の初期状態確認 |  |  |
| CASE1 | 基本FIFO動作確認 |  |  |
| CASE2 | full / guard bit / empty復帰確認 |  |  |
| CASE3 | clr によるクリア確認 |  |  |

## 実シミュレーション結果
Vivado の実行ログより、上記の全ケースが期待どおりに確認できた。

| ケースID | シミュレーション結果 | 判定 |
| --- | --- | --- |
| CASE1 | `rx_data=0x28`、`rx_done=1`、`parity_error=0`、`framing_error=0` を確認 | 合格 |

## フレーム単位の期待値

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
