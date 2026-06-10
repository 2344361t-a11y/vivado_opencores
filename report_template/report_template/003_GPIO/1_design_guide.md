# GPIO回路およびテストベンチ説明書

## 対象ファイル
- `simple_gpio.v`: GPIO回路
- `tb_simplegpio.v`: 検証用テストベンチ

## 回路概要
本回路は，Wishboneバスを介してGPIOピンの入出力方向および出力値を制御するGPIO回路である．GPIOはGeneral Purpose Input/Outputの略であり，外部回路と0または1のデジタル信号をやり取りするための汎用入出力端子である．
今回のテストベンチでは，CPUなどのバスマスタの代わりに`tb_simplegpio.v`がWishboneバス信号を操作する．

## 実装する処理仕様の概要
本回路には、GPIO の動作を制御するために主に 2 種類のレジスタが用意されている。

1 つ目は control register である。control register は、各 GPIO ピンを入力として使用するか、出力として使用するかを決定するレジスタである。各 bit の値が `1` の場合、その bit に対応する GPIO ピンは出力モードとなる。一方、各 bit の値が `0` の場合、その bit に対応する GPIO ピンは入力モードとなる。

2 つ目は line register である。line register は、書き込み時には GPIO の出力値を設定するために使用される。出力モードに設定された GPIO ピンでは、line register に書き込まれた値が GPIO ピンへ出力される。一方、入力モードに設定された GPIO ピンでは、line register に値を書き込んでも GPIO ピンは DUT から駆動されず、外部から与えられた値が読み出し対象となる。

本回路における Wishbone バスのアドレスは `adr_i` により指定される。`adr_i=0` の場合は control register を対象とし、`adr_i=1` の場合は line register または GPIO ピン状態を対象とする。書き込み時には `we_i=1` とし、読み出し時には `we_i=0` とする。また、Wishbone アクセスは `cyc_i` および `stb_i` が有効になったときに行われ、回路はアクセス応答として `ack_o` を出力する。

今回のテストベンチでは、まず control register に値を書き込み、GPIO ピンごとの入力・出力方向を設定する。次に line register に値を書き込み、出力モードに設定された GPIO ピンへ値を出力する。その後、入力モードに設定された GPIO ピンに対してテストベンチ側から外部入力値を与える。最後に Wishbone バスを用いて GPIO ピン全体の状態を読み出し、出力ピンの値と入力ピンの値が期待どおり反映されていることを確認する。

## 構成図（ブロック図）
![RS-232 UART ループバック回路図](./rs232.png)

## `simple_gpio.v`
### 入力信号
- `clk_i`: Wishbone バスおよび内部レジスタ動作の基準となるクロック信号
- `rst_i`: 非同期リセット信号。Low のときリセット状態となる
- `cyc_i`: Wishbone バスの転送サイクルが有効であることを示す信号
- `stb_i`: Wishbone バスの転送要求が有効であることを示す信号
- `adr_i`: アクセス対象のレジスタを選択するアドレス信号
- `we_i`: 書き込み動作か読み出し動作かを指定する信号。`1` のとき書き込み、`0` のとき読み出し
- `dat_i[7:0]`: Wishbone バスから DUT へ書き込むデータ

### 出力信号
- `dat_o[7:0]`: Wishbone バスへの読み出しデータ
- `ack_o`: Wishbone バスアクセスに対する応答信号
- `gpio`: GPIO ピン。入力および出力の両方に用いられる双方向信号

### 内部レジスタ
- `ctrl`: GPIO の入出力方向を保持する control register
- `line`: GPIO の出力値を保持する line register
- `lgpio`: GPIO ピンの値を 1 段目で取り込むレジスタ
- `llgpio`: `lgpio` の値をさらに取り込む 2 段目のレジスタ

### 機能
- `rst_i=0` のとき、リセット状態となる。
- リセット時には、`ctrl`、`line`、`ack_o` を `0` に初期化する。
- `cyc_i=1` かつ `stb_i=1` のとき、Wishbone アクセスを受け付ける。
- Wishbone アクセスを受け付けたとき、応答信号として `ack_o` を出力する。
- `we_i=1` かつ `adr_i=0` のとき、`dat_i` の値を control register である `ctrl` に書き込む。
- `we_i=1` かつ `adr_i=1` のとき、`dat_i` の値を line register である `line` に書き込む。
- `we_i=0` かつ `adr_i=0` のとき、`ctrl` の値を `dat_o` へ出力する。
- `we_i=0` かつ `adr_i=1` のとき、GPIO ピン状態を取り込んだ `llgpio` の値を `dat_o` へ出力する。
- `ctrl[n]=1` の GPIO ピンでは、`line[n]` の値を `gpio[n]` へ出力する。
- `ctrl[n]=0` の GPIO ピンでは、`gpio[n]` をハイインピーダンス状態とし、DUT 側からは駆動しない。
- GPIO ピンの値を `lgpio`、`llgpio` の 2 段のレジスタに順に取り込む。
- 読み出し時には、取り込まれた GPIO ピン状態である `llgpio` を用いて、現在の GPIO 状態を確認できる。

### シミュレーションログ出力
- リセットから待機状態への遷移
- 送信開始受付
- 各データ bit の送信
- パリティ bit の送信
- フレーム送信完了

### エラー動作

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

## `tb_simple_gpio.v`
### 目的
- 案件で要求される主要機能を一通り検証する
- 実行パスをシミュレーションログに残す
- 回路の入出力値をシミュレーションログに残す

### テストケース
- `CASE1`: 正常な loopback 送受信

### Vivado Wave で観測すべき主な信号
- `tx_line`
- `rx_line`
- `tx_busy`
- `rx_busy`
- `rx_data`
- `rx_done`