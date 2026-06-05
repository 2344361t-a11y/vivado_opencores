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
| CASE1 | 正常な受信 | `send_8n1(8'h55)` | `rx_wr=1` が1クロックだけ立つ、`rx_data=8'h55`|

## 実シミュレーション結果
Vivado の実行ログより、上記の全ケースが期待どおりに確認できた。

| ケースID | シミュレーション結果 | 判定 |
| --- | --- | --- |
| CASE1 | `rx_wr=1` , `rx_data=0x55` を確認 | 合格 |

## フレーム単位の期待値

### CASE1: データ `8'h55`
- 2進数表現: `0101_0101`
- LSB first の送信順: `1,0,1,0,1,0,1,0`
- `1` の個数: `4`
- フレーム全体: `0(start), 1,0,1,0,1,0,1,0, 1(stop)`

## 期待されるログ出力
- RTL:
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
  - `TB_CASE: send_8n1 data=0x55`
  - `TB_SUMMARY: pass=... fail=0`
