# RS-232回路 期待値表

## テスト条件
- クロック周期: `10 ns`
- `CLKS_PER_BIT`: `10`
- UART 1bit期間: `100 ns`
- フレーム形式: `8N1`
  - スタートビット 1bit
  - データ 8bit
  - ストップビット 1bit

## 期待値表

| ケースID | テスト目的 | 入力 | 期待される出力 |
| --- | --- | --- | --- |
| CASE1 | `8'h00` の正常送信 | `run_normal_case(8'h00, "CASE1")` | `tx_line` に `0(start), 0,0,0,0,0,0,0,0, 1(stop)` が順に出力され、送信中は `tx_busy=1`、送信完了後は `tx_busy=0`、`tx_line=1` に戻る |
| CASE2 | `8'hFF` の正常送信 | `run_normal_case(8'hFF, "CASE2")` | `tx_line` に `0(start), 1,1,1,1,1,1,1,1, 1(stop)` が順に出力され、送信中は `tx_busy=1`、送信完了後は `tx_busy=0`、`tx_line=1` に戻る |
| CASE3 | `8'h55` の正常送信 | `run_normal_case(8'h55, "CASE3")` | `tx_line` に `0(start), 1,0,1,0,1,0,1,0, 1(stop)` が順に出力され、送信中は `tx_busy=1`、送信完了後は `tx_busy=0`、`tx_line=1` に戻る |
| CASE4 | `8'hAA` の正常送信 | `run_normal_case(8'hAA, "CASE4")` | `tx_line` に `0(start), 0,1,0,1,0,1,0,1, 1(stop)` が順に出力され、送信中は `tx_busy=1`、送信完了後は `tx_busy=0`、`tx_line=1` に戻る |
| CASE5 | `tx_busy=1` 中の書き込み無視確認 | `run_busy_write_case()` | `8'h55` の送信中に `tx_data=8'hAA`、`tx_wr=1` が入力されても、現在送信中の `8'h55` のフレームが崩れず、送信完了後に `8'hAA` の追加フレームが開始しない |

## 実シミュレーション結果
Vivado の実行ログより、上記のケースが期待どおりに確認できた。

| ケースID | シミュレーション結果 | 判定 |
| --- | --- | --- |
| CASE1 | `tx_data=0x55`、`rx_done=1` を確認 | 合格 |
| CASE2 | `rx_wr=1`、`rx_data=0xFF` を確認 | 合格 |
| CASE3 | `rx_wr=1`、`rx_data=0x55` を確認 | 合格 |
| CASE4 | `rx_wr=1`、`rx_data=0xAA` を確認 | 合格 |

## フレーム単位の期待値

### CASE1: データ `8'h00`
- 2進数表現: `0010_1000`
- LSB first の送信順: `0,0,0,1,0,1,0,0`
- `1` の個数: `2`
- フレーム全体: `0(start), 0,0,0,1,0,1,0,0, 1(stop)`

### CASE2: データ `8'hFF`
- 2進数表現: `1111_1111`
- LSB first の送信順: `1,1,1,1,1,1,1,1`
- フレーム全体: `0(start), 1,1,1,1,1,1,1,1, 1(stop)`

### CASE3: データ `8'h55`
- 2進数表現: `0101_0101`
- LSB first の送信順: `1,0,1,0,1,0,1,0`
- フレーム全体: `0(start), 1,0,1,0,1,0,1,0, 1(stop)`

### CASE4: データ `8'hAA`
- 2進数表現: `1010_1010`
- LSB first の送信順: `0,1,0,1,0,1,0,1`
- フレーム全体: `0(start), 0,1,0,1,0,1,0,1, 1(stop)`

### CASE5: `tx_busy=1` 中の `tx_wr` 入力
- 最初に送信するデータ: `8'h55`
- 送信中に書き込みを試みるデータ: `8'hAA`
- 期待される送信フレーム: `8'h55` のフレームのみ
- 期待毛kkさ: 送信中の `8'h55` のフレームは変化せず、`8'h55` の送信完了後、`8'hAA` の新しいフレームが続けて開始しない

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
