# FIFO同期回路 期待値表

## テスト条件
- クロック周期: `10 ns`
- `CLKS_PER_BIT`: `10`
- UART 1bit期間: `100 ns`

## 期待値表

| ケースID | テスト目的 | 入力 | 期待される出力 |
| --- | --- | --- | --- |
| RESET | リセット後の初期状態確認 | `rst=0` によるリセット後、`rst=1` に戻す | `empty=1`、`full=0`、`wp==rp`、`gb=0`、`cnt=0` |
| CASE1 | 基本FIFO動作確認 | `8'h00`、`8'hFF`、`8'hA5`、`8'h5A` を順番に書き込み、その後4回読み出す | 書き込んだ順に `8'h00`、`8'hFF`、`8'hA5`、`8'h5A` が読み出される。全読み出し後に `empty=1`、`full=0`、`wp==rp`、`gb=0`、`cnt=0` となる |
| CASE2 | `full` / `guard bit` / `empty` 復帰確認 | `i=0〜255` に対して `din=i[7:0]` を256個連続で書き込む。その後256個すべて読み出す | 256個書き込み後に `full=1`、`empty=0`、`wp==rp`、`gb=1`、`cnt=256` となる。256個読み出し後に `empty=1`、`full=0`、`wp==rp`、`gb=0`、`cnt=0` となる |
| CASE3 | clr によるクリア確認 | `8'h11`、`8'h22`、`8'h33` を書き込んだ後、`clr=1` を1クロック入力する | clr 入力後に `empty=1`、`full=0`、`wp==rp`、`gb=0`、`cnt=0` となる |

## 実シミュレーション結果
Vivado の実行ログより、上記の全ケースが期待どおりに確認できた。

| ケースID | シミュレーション結果 | 判定 |
| --- | --- | --- |
| RESET | リセット後に `empty=1`、`full=0`、`wp=0x00`、`rp=0x00`、`gb=0`、`cnt=0` を確認 | 合格 |
| CASE1 | `8'h00`、`8'hFF`、`8'hA5`、`8'h5A` が書き込み順と同じ順序で読み出されることを確認。全読み出し後に `empty=1`、`full=0`、`wp==rp`、`gb=0`、`cnt=0` を確認 | 合格 |
| CASE2 | 256個書き込み後に `full=1`、`empty=0`、`wp=0x04`、`rp=0x04`、`gb=1`、`cnt=256` を確認。256個読み出し後に `empty=1`、`full=0`、`wp=0x04`、`rp=0x04`、`gb=0`、`cnt=0` を確認 | 合格 |
| CASE3 | `clr=1` 入力後に `empty=1`、`full=0`、`wp=0x00`、`rp=0x00`、`gb=0`、`cnt=0` を確認 | 合格 |

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
