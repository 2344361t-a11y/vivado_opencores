# FIFO非同期回路 期待値表

## テスト条件
- 時刻定義: `timescale.v`
- データ幅: `8 bit`
- アドレス幅: `8 bit`
- FIFO 深さ: `2^8 = 256`
- 書き込み側クロック周期: `10 ns`
- 読み出し側クロック周期: `14 ns`
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
