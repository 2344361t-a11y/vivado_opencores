# FFIO同期回路およびテストベンチ説明書

## 対象ファイル
- `generic_fifo_sc_a.v`: FIFO同期回路
- `generic_dpram.v`: FIFO内部で使用されるデュアルポートRAM
- `timescale.v`: シミュレーション時間単位の設定ファイル
- `tb_generic_fifo_sc_a_20260616_1449.v`: 検証用テストベンチ

## 回路概要

本回路は、OpenCores の `generic_fifos` に含まれる FIFO同期回路である。FIFO は First-In First-Out の略であり、先に書き込んだデータを先に読み出すためのバッファ回路である。

今回対象とする `generic_fifo_sc_a.v` は、書き込みと読み出しを同一クロック `clk` に同期して行う single clock FIFO である。外部から `din` に入力されたデータは、`we` が有効なクロックで FIFO 内部のメモリへ書き込まれる。また、`re` が有効なクロックで、FIFO に保存されているデータが書き込み順に `dout` へ読み出される。

本回路では、FIFO内部のデータ格納部として `generic_dpram.v` を使用する。`generic_fifo_sc_a.v` は、書き込み位置を示す `wp`、読み出し位置を示す `rp`、FIFO内のデータ数を示す `cnt`、および `full` と `empty` を区別するための `gb` を用いて FIFO の状態を管理する。


## 実装する処理仕様の概要
本回路のデフォルトパラメータは以下の通りである。

dw = 8
aw = 8
n  = 32

各パラメータの意味は以下の通りである。

- `dw`: 1要素あたりのデータ幅を示す
- `aw `: FIFOのアドレス幅を示す。
- `n `: `full_n` および `empty_n` のしきい値判定に使用される値である。

今回の設定では、`dw=8`、`aw=8` であるため、FIFOの構成は以下のようになる。

1要素のデータ幅: 8bit
保存可能な要素数: 2^8 = 256個
FIFO全体の記憶容量: 8bit × 256個 = 2048bit

ここで、FIFO容量が256であるということは、256bitのデータを1回で入力できるという意味ではない。1回の書き込みでは、`din[7:0]` の8bitデータを1要素として FIFO へ格納する。この8bitデータ要素を最大256個まで保存できるという意味である。

FIFOの基本動作は以下の通りである。

- `we=1` のクロックで、`din` の値を FIFO に書き込む。
- `re=1` のクロックで、FIFO に保存されているデータを `dout` へ読み出す。
- 書き込み時には `wp` が進み、読み出し時には `rp` が進む。
- FIFO内のデータ数は `cnt` により管理される。
- FIFOが空のときは `empty=1` となる。
- FIFOが満杯のときは `full=1` となる。

本回路では、`wp` と `rp` が同じ値になる状態が、空状態と満杯状態の両方で発生する。そのため、generic_fifo_sc_a.v では `gb` を用いて、同じ `wp==rp` の状態が empty を意味するのか、full を意味するのかを区別している。

`wp == rp` かつ `gb == 0` → empty
`wp == rp` かつ `gb == 1` → full

したがって、本回路の検証では、データが書き込み順に読み出されることに加えて、`gb` により full と empty が正しく区別されることを確認する。
## 構成図（ブロック図）
![FIFO同期回路図](./fifo_sc.png)

## `uart_tx.v`
### 入力信号
- `clk`: システムクロック
- `rst`: 非同期リセット
- `clr`: リセット
- `din`: 
- `we`: 
- `re`:

### 出力信号
- `dout`: 
- `full`:
- `full_r`: 
- `empty`: 
- `empty_r`:
- `full_n`: 
- `full_n_r`: 
- `empty_n`: 
- `empty_n_r`: 
- `level`: 

### 内部レジスタ
- `wp`: 
- `rp`: 
- `full_r`: 
- `empty_r`: 
- `gb`: 
- `gb2`: 
- `cnt`: 
- `full_n_r`: 
- `empty_n_r`: 

### 機能
- `STATE_IDLE` で待機する
- `start` 入力時に `data` をラッチし、パリティを計算する
- start bit を送信する
- データ 8bit を LSB first で送信する
- パリティ有効時は parity bit を送信する
- stop bit を送信して待機状態へ戻る

### シミュレーションログ出力
- リセットから待機状態への遷移
- 送信開始受付
- 各データ bit の送信
- パリティ bit の送信
- フレーム送信完了

## `uart_rx.v`
### 入力信号
- `clk`: システムクロック
- `rst`: 非同期リセット
- `rx`: シリアル受信線
- `data_read`: 受信済みデータの読出し完了通知

### 出力信号
- `data_out[7:0]`: 受信データ
- `done`: 正常受信完了時に 1 クロックだけ立つ信号
- `busy`: 受信中フラグ
- `framing_error`: stop bit が不正な場合に立つ信号
- `parity_error`: parity bit が不正な場合に立つ信号
- `overrun_error`: 未読データが残ったまま次の正常フレームを受信した場合に立つ信号
- `data_valid`: `data_out` に未読の有効データが格納されていることを示す信号

### 内部レジスタ
- `state`: 受信状態を管理するステートマシン
- `clk_count`: UART 1bit 期間内のクロック数を数えるカウンタ
- `bit_index`: 現在受信中のデータビット位置
- `parity_calc`: 受信データから計算したパリティ値

### 機能
- start bit の Low を検出する
- start bit 中央で再確認し、誤検出を防ぐ
- データ 8bit を LSB first で受信する
- parity bit を検査する
- stop bit を検査する
- 正常フレームなら `done` を立てる
- 未読データがある状態で次の正常フレームを受信した場合、`overrun_error` を立てる

### エラー動作
- `parity_error=1`: parity bit が期待値と一致しない
- `framing_error=1`: stop bit が `1` ではない
- `overrun_error=1`: `data_valid=1` のまま次の正常フレームを受信した

### 主要ステータス信号とテスト内容
#### `data_valid` のセットおよびクリア
意味:
- `uart_rx` が正常に 1 フレーム受信し、`data_out` に有効なデータが入っていることを示す。
- `data_valid=1` は、まだ読み出されていない受信データが存在することを意味する。
- `data_read` を入力すると `data_valid=0` にクリアされる。

テスト内容:
- `CASE1`
  - 正常受信後に `data_valid=1` になることを確認する。
  - `pulse_data_read()` 後に `data_valid=0` になることを確認する。
- `CASE4`
  - 1 回目受信後に `data_valid=1` となることを確認する。
  - 2 回目受信後も未読のため `data_valid=1` のままであることを確認する。
  - `pulse_data_read()` 後にクリアされることを確認する。

#### `parity_error` の検出
意味:
- parity bit が、受信したデータから計算した期待値と一致しないときに立つエラー信号である。
- 今回は even parity を採用しているため、データ中の `1` の個数が偶数になることを前提に検査する。
- 通信中のビット化けを簡易的に検出する目的で使用する。

テスト内容:
- `CASE2`
  - `inject_frame(8'h55, 1'b1, 1'b1)` により、意図的に誤った parity bit を注入する。
  - その結果 `parity_error=1` となることを確認する。
  - あわせて `rx_done=0`、`data_valid=0` であり、正常受信扱いしないことを確認する。

#### `framing_error` の検出
意味:
- stop bit が本来 `1` で終わるべきところ、そうなっていない場合に立つエラー信号である。
- フレーム終端が正しく形成されていないことを示す。
- 通信区切りの異常や波形異常を検出する目的で使用する。

テスト内容:
- `CASE3`
  - `inject_frame(8'h33, 1'b0, 1'b0)` により、stop bit を意図的に `0` にする。
  - その結果 `framing_error=1` となることを確認する。
  - あわせて `rx_done=0`、`data_valid=0` であり、正常受信扱いしないことを確認する。

#### `overrun_error` の検出
意味:
- 前に受信したデータをまだ読み出していない状態で、新しい正常フレームを受信した場合に立つエラー信号である。
- 受信自体は成立しているが、前のデータを取りこぼした可能性があることを示す。

テスト内容:
- `CASE4`
  - まず `8'hA5` を正常受信し、`data_valid=1` とする。
  - `data_read` を行わないまま、続けて `8'h3C` を受信させる。
  - このとき `overrun_error=1` になることを確認する。
  - 最後に `pulse_data_read()` を入力し、`overrun_error=0` に戻ることを確認する。

## `tb_uart_loopback.v`
### 目的
- 案件で要求される主要機能を一通り検証する
- 実行パスをシミュレーションログに残す
- 回路の入出力値をシミュレーションログに残す

### テストケース
- `CASE1`: 正常な loopback 送受信
- `CASE2`: パリティエラーの強制注入
- `CASE3`: フレーミングエラーの強制注入
- `CASE4`: 未読データを残したまま2フレーム受信し、オーバーランを確認

### Vivado Wave で観測すべき主な信号
- `tx_line`
- `rx_line`
- `tx_busy`
- `rx_busy`
- `rx_data`
- `rx_done`
- `rx_data_valid`
- `rx_parity_error`
- `rx_framing_error`
- `rx_overrun_error`
