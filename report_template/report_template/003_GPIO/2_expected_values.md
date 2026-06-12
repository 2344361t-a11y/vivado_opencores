# GPIO回路 期待値表

## テスト条件
- クロック周期: `10 ns`
- `CLKS_PER_BIT`: `10`
- UART 1bit期間: `100 ns`
- フレーム形式: `8E1`
  - スタートビット 1bit
  - データ 8bit
  - ストップビット 1bit

## 期待値表

| ケースID | テスト目的 | 入力 | 期待される出力 |
| --- | --- | --- | --- |
| RESET | リセット後の初期状態確認 | `pulse_start(8'h28)` | `rx_done=1` が1クロックだけ立つ、`rx_data=8'h28`、`rx_data_valid=1`|
| CASE1 | 正常な送受信 | `pulse_start(8'h28)` | `rx_done=1` が1クロックだけ立つ、`rx_data=8'h28`、`rx_data_valid=1`|
| CASE2 | 正常な送受信 | `pulse_start(8'h28)` | `rx_done=1` が1クロックだけ立つ、`rx_data=8'h28`、`rx_data_valid=1`|
| CASE3 | 正常な送受信 | `pulse_start(8'h28)` | `rx_done=1` が1クロックだけ立つ、`rx_data=8'h28`、`rx_data_valid=1`|
| CASE4 | 正常な送受信 | `pulse_start(8'h28)` | `rx_done=1` が1クロックだけ立つ、`rx_data=8'h28`、`rx_data_valid=1`|
| CASE5 | 正常な送受信 | `pulse_start(8'h28)` | `rx_done=1` が1クロックだけ立つ、`rx_data=8'h28`、`rx_data_valid=1`|
| CASE6 | 正常な送受信 | `pulse_start(8'h28)` | `rx_done=1` が1クロックだけ立つ、`rx_data=8'h28`、`rx_data_valid=1`|
| CASE7 | 正常な送受信 | `pulse_start(8'h28)` | `rx_done=1` が1クロックだけ立つ、`rx_data=8'h28`、`rx_data_valid=1`|

## 実シミュレーション結果
Vivado の実行ログより、上記の全ケースが期待どおりに確認できた。

| ケースID | シミュレーション結果 | 判定 |
| --- | --- | --- |
| RESET | `rx_data=0x28`、`rx_done=1` を確認 | 合格 |
| CASE1 | `rx_data=0x28`、`rx_done=1` を確認 | 合格 |
| CASE2 | `rx_data=0x28`、`rx_done=1` を確認 | 合格 |
| CASE3 | `rx_data=0x28`、`rx_done=1` を確認 | 合格 |
| CASE4 | `rx_data=0x28`、`rx_done=1` を確認 | 合格 |
| CASE5 | `rx_data=0x28`、`rx_done=1` を確認 | 合格 |
| CASE6 | `rx_data=0x28`、`rx_done=1` を確認 | 合格 |
| CASE7 | `rx_data=0x28`、`rx_done=1` を確認 | 合格 |

## フレーム単位の期待値

### RESET: データ `8'h28`
- 2進数表現: `0010_1000`
- LSB first の送信順: `0,0,0,1,0,1,0,0`
- フレーム全体: `0(start), 0,0,0,1,0,1,0,0, 0(parity), 1(stop)`

### CASE1: データ `8'h28`
- 2進数表現: `0010_1000`
- LSB first の送信順: `0,0,0,1,0,1,0,0`
- フレーム全体: `0(start), 0,0,0,1,0,1,0,0, 0(parity), 1(stop)`

### CASE2: データ `8'h28`
- 2進数表現: `0010_1000`
- LSB first の送信順: `0,0,0,1,0,1,0,0`
- フレーム全体: `0(start), 0,0,0,1,0,1,0,0, 0(parity), 1(stop)`

### CASE3: データ `8'h28`
- 2進数表現: `0010_1000`
- LSB first の送信順: `0,0,0,1,0,1,0,0`
- フレーム全体: `0(start), 0,0,0,1,0,1,0,0, 0(parity), 1(stop)`

### CASE4: データ `8'h28`
- 2進数表現: `0010_1000`
- LSB first の送信順: `0,0,0,1,0,1,0,0`
- フレーム全体: `0(start), 0,0,0,1,0,1,0,0, 0(parity), 1(stop)`

### CASE5: データ `8'h28`
- 2進数表現: `0010_1000`
- LSB first の送信順: `0,0,0,1,0,1,0,0`
- フレーム全体: `0(start), 0,0,0,1,0,1,0,0, 0(parity), 1(stop)`

### CASE6: データ `8'h28`
- 2進数表現: `0010_1000`
- LSB first の送信順: `0,0,0,1,0,1,0,0`
- フレーム全体: `0(start), 0,0,0,1,0,1,0,0, 0(parity), 1(stop)`

### CASE7: データ `8'h28`
- 2進数表現: `0010_1000`
- LSB first の送信順: `0,0,0,1,0,1,0,0`
- フレーム全体: `0(start), 0,0,0,1,0,1,0,0, 0(parity), 1(stop)`

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