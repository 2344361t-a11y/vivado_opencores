# GPIOコントローラおよびテストベンチ説明書

## 対象ファイル
- `gpio_controller.v`: GPIOコントローラ
- `tb_gpio_controller.v`: 検証用テストベンチ

## 回路概要


## 実装する処理仕様の概要


## 構成図（ブロック図）
![GPIOコントローラとテストベンチの構成図](./rs232.png)

## `gpio_controller.v`
### 入力信号
- `clk`: クロック信号
- `rst_n`: Low有効リセット信号
- `wb_cyc`: バスサイクルが有効であることを示す信号
- `wb_stb`: バス転送要求が有効であることを示す信号
- `wb_addr`: アクセス対象を選択するアドレス信号
- `wb_we`: 書き込み・読み出しを指定する信号。`1` で書き込み、`0` で読み出し
- `wb_wdata[7:0]`: 書き込みデータ

### 出力信号
- `wb_rdata[7:0]`: 読み出しデータ
- `wb_ack`: Wishbone バスアクセスに対する応答信号
- `direction_reg[7:0]`:GPIO方向設定を保持する観測用出力
- `output_reg[7:0]`: GPIO出力値を保持する観測用出力
- `input_data[7:0]`: GPIO状態読み出し時の値を保持する観測用出力
- `read_valid`: GPIO状態読み出し値が有効であることを示す
- `done`: バスアクセス完了を示す
- `busy`: バスアクセス処理中を示す
- `ready`: 次のバスアクセスを受け付け可能であることを示す

### 双方向信号
- `gpio[7:0]`: 外部回路と接続される双方向GPIOピン

### 内部レジスタ
- `gpio_sample_1[7:0]`: GPIOピン状態を1段目で取り込むレジスタ
- `gpio_sample_2[7:0]`: GPIOピン状態を2段目で取り込むレジスタ
- `read_value[7:0]`: GPIO状態読み出し時に一時的に使用される値

### 内部信号
- `bus_access`: wb_cyc & wb_stb。バスアクセスが有効であることを示す
- `bus_accept`: bus_access & ~wb_ack。DUTがそのアクセスを受け付ける条件
- `bus_write`: bus_accept & wb_we。書き込みアクセスを示す

### 機能
### 機能
- `rst_n=0` のとき、リセット状態となる。
- リセット時には、`direction_reg`、`output_reg`、`input_data`、`wb_rdata`、`wb_ack`、`read_valid`、`done` を初期化する。
- `wb_cyc=1` かつ `wb_stb=1` のとき、WISHBONE-style bus アクセスを受け付ける。
- バスアクセスを受け付けたとき、応答信号として `wb_ack` を出力する。
- バスアクセスを受け付けたとき、アクセス完了信号として `done` を出力する。
- `wb_we=1` かつ `wb_addr=0` のとき、`wb_wdata` の値を `direction_reg` に書き込む。
- `wb_we=1` かつ `wb_addr=1` のとき、`wb_wdata` の値を `output_reg` に書き込む。
- `wb_we=0` かつ `wb_addr=0` のとき、`direction_reg` の値を `wb_rdata` に出力する。
- `wb_we=0` かつ `wb_addr=1` のとき、GPIO ピン状態を取り込んだ値を `wb_rdata` に出力する。
- `wb_we=0` かつ `wb_addr=1` の読み出し時には、GPIO 状態読み出し値を `input_data` に保持する。
- GPIO 状態読み出し時には、読み出し値が有効であることを示す `read_valid` を出力する。
- `direction_reg[n]=1` の GPIO ピンでは、`output_reg[n]` の値を `gpio[n]` へ出力する。
- `direction_reg[n]=0` の GPIO ピンでは、`gpio[n]` をハイインピーダンス状態とし、DUT 側からは駆動しない。
- GPIO ピンの値を `gpio_sample_1`、`gpio_sample_2` の 2 段のレジスタに順に取り込む。
- `busy` により、バスアクセス処理中であることを示す。
- `ready` により、次のバスアクセスを受け付け可能であることを示す。
- シミュレーション時には、リセット、方向設定書き込み、出力値書き込み、方向設定読み出し、GPIO 状態読み出しの実行パスをログに出力する。

### シミュレーションログ出力
- リセットから待機状態への遷移
- 送信開始受付
- 各データ bit の送信
- パリティ bit の送信
- フレーム送信完了

### エラー動作

### 主要ステータス信号とテスト内容
#### `wb_ack` の応答確認
意味:
- wb_ack は、WISHBONE-style bus アクセスに対する応答信号である。
- wb_cyc=1 かつ wb_stb=1 によりバスアクセスが有効になったとき、DUT がアクセスを受け付けたことを示す。
- 書き込み時および読み出し時の両方で確認対象となる。

テスト内容:
- `CASE`
  - 

#### `done` のアクセス完了確認
意味:
- done は、バスアクセスの完了を示す信号である。
- DUT が書き込みまたは読み出しアクセスを受け付けたときに 1 となる。
- wb_ack とあわせて確認することで、バスアクセスが完了したことを判断できる。

テスト内容:
- `CASE`
  - 

#### `read_valid` のGPIO状態読み出し確認
意味:
- read_valid は、GPIO 状態読み出し値が有効であることを示す信号である。
- wb_addr=1 かつ wb_we=0 の GPIO 状態読み出し時に 1 となる。
- direction register の読み出しでは、GPIO 状態読み出しではないため read_valid は立たない。

テスト内容:
- `CASE`
  - 

#### `wb_ack` の応答確認
意味:
- 

テスト内容:
- `CASE`
  - 

#### `wb_ack` の応答確認
意味:
- 

テスト内容:
- `CASE`
  - 


## `tb_gpio_controller.v`
### 目的
- 案件で要求される主要機能を一通り検証する
- 実行パスをシミュレーションログに残す
- 回路の入出力値をシミュレーションログに残す

### テストケース
- `CASE1`: 正常な送受信

### Vivado Wave で観測すべき主な信号
- `tx_line`
- `rx_line`
- `tx_busy`
- `rx_busy`
- `rx_data`
- `rx_done`