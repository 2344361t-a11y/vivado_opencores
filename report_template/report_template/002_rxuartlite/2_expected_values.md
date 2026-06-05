# RS-232回路 期待値表

## テスト条件
- クロック周期: `10 ns`
- `CLKS_PER_BIT`: `16`
- UART 1bit期間: `160 ns`
- フレーム形式: `8N1`
  - スタートビット 1bit
  - データ 8bit
  - ストップビット 1bit

## 期待値表

| ケースID | テスト目的 | 入力 | 期待される出力 |
| --- | --- | --- | --- |
| CASE1 | 全ビット0の正常受信 | `send_8n1(8'h00)` | `rx_wr=1` が1クロックだけ立つ、`rx_data=8'h00` |
| CASE2 | 全ビット1の正常受信 | `send_8n1(8'hFF)` | `rx_wr=1` が1クロックだけ立つ、`rx_data=8'hFF` |
| CASE3 | 交互ビットパターンの正常受信 | `send_8n1(8'h55)` | `rx_wr=1` が1クロックだけ立つ、`rx_data=8'h55` |
| CASE4 | 交互ビットパターンの正常受信 | `send_8n1(8'hAA)` | `rx_wr=1` が1クロックだけ立つ、`rx_data=8'hAA` |

## 実シミュレーション結果
Vivado の実行ログより、上記の全ケースが期待どおりに確認できた。

| ケースID | シミュレーション結果 | 判定 |
| --- | --- | --- |
| CASE1 | `rx_wr=1`、`rx_data=0x00` を確認 | 合格 |
| CASE2 | `rx_wr=1`、`rx_data=0xFF` を確認 | 合格 |
| CASE3 | `rx_wr=1`、`rx_data=0x55` を確認 | 合格 |
| CASE4 | `rx_wr=1`、`rx_data=0xAA` を確認 | 合格 |

## フレーム単位の期待値

### CASE1: データ `8'h00`
- 2進数表現: `0000_0000`
- LSB first の送信順: `0,0,0,0,0,0,0,0`
- フレーム全体: `0(start), 0,0,0,0,0,0,0,0, 1(stop)`

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

## 期待されるログ出力

- RTL:
  - 各CASEで以下の状態遷移が確認できることを期待する。
  - `TB_DUT_PATH: IDLE -> BIT_ZERO`
  - `TB_DUT_PATH: BIT_ZERO -> BIT_ONE`
  - `TB_DUT_PATH: BIT_ONE -> BIT_TWO`
  - `TB_DUT_PATH: BIT_TWO -> BIT_THREE`
  - `TB_DUT_PATH: BIT_THREE -> BIT_FOUR`
  - `TB_DUT_PATH: BIT_FOUR -> BIT_FIVE`
  - `TB_DUT_PATH: BIT_FIVE -> BIT_SIX`
  - `TB_DUT_PATH: BIT_SIX -> BIT_SEVEN`
  - `TB_DUT_PATH: BIT_SEVEN -> STOP`
  - `TB_DUT_PATH: STOP -> WAIT`
  - `TB_DUT_PATH: WAIT -> IDLE`

- テストベンチ:
  - `TB_PATH: CASE1 normal receive start`
  - `TB_CASE: send_8n1 data=0x00`
  - `TB_PATH: CASE2 normal receive start`
  - `TB_CASE: send_8n1 data=0xff`
  - `TB_PATH: CASE3 normal receive start`
  - `TB_CASE: send_8n1 data=0x55`
  - `TB_PATH: CASE4 normal receive start`
  - `TB_CASE: send_8n1 data=0xaa`
  - `TB_SUMMARY: pass=13 fail=0`
  - `TB_RESULT: PASS`
