# SPI Master回路 期待値表

## テスト条件

- 基準クロック周期：10 ns
- SPIモード：mode 3
- 送受信データ幅：8 bit
- 送信データ：`8'h96`（2進数：`1001_0110`）
- 受信データ：`8'h3C`（2進数：`0011_1100`）

## 期待値表

| ケースID | テスト目的 | 入力 | 期待される出力 |
| --- | --- | --- | --- |
| RESET | リセット後の待機状態確認 | `rstb=0`後に`rstb=1` | `ss=1`、`sck=1`、`dout=1` |
| CASE1 | LSB first基本送受信 | `mlb=0`、`cdiv=00`、`tdat=8'h96`、`din`列=`8'h3C` | `dout=0,1,1,0,1,0,0,1`、`rdata=8'h3C`、`done=1`、`sck`周期40 ns |
| CASE2 | MSB first基本送受信 | `mlb=1`、`cdiv=00`、`tdat=8'h96`、`din`列=`8'h3C` | `dout=1,0,0,1,0,1,1,0`、`rdata=8'h3C`、`done=1` |
| CASE3 | クロック分周確認 | `mlb=0`、`cdiv=01`、`tdat=8'h96`、`din`列=`8'h3C` | `rdata=8'h3C`、`done=1`、`sck`周期80 ns |
| CASE4 | 通信中`start`の無視確認 | CASE1の転送中に`start=1`、`tdat=8'hFF` | 進行中の送信列と`rdata=8'h3C`を維持し、完了後400 ns以内に第2転送が開始しない |

## ビット単位の期待値

### CASE1・CASE3・CASE4：LSB first

- `tdat=8'h96`の送信順：`0,1,1,0,1,0,0,1`
- `8'h3C`を得るための`din`入力順：`0,0,1,1,1,1,0,0`
- CASE1の`sck`周期：40 ns
- CASE3の`sck`周期：80 ns

### CASE2：MSB first

- `tdat=8'h96`の送信順：`1,0,0,1,0,1,1,0`
- `8'h3C`を得るための`din`入力順：`0,0,1,1,1,1,0,0`

## 実シミュレーション結果

2026年6月24日にVivado Behavioral Simulationを実行し、全ケースが合格した。

| ケースID | シミュレーション結果 | 判定 |
| --- | --- | --- |
| RESET | `ss=1`、`sck=1`、`dout=1`を確認 | 合格 |
| CASE1 | LSB firstの送信列、`rdata=0x3C`、`done=1`、`sck`周期40 nsを確認 | 合格 |
| CASE2 | MSB firstの送信列、`rdata=0x3C`、`done=1`を確認 | 合格 |
| CASE3 | LSB firstの送信列、`rdata=0x3C`、`done=1`、`sck`周期80 nsを確認 | 合格 |
| CASE4 | 通信中の`start`後も送信列と受信値が不変で、400 ns監視中に第2転送がないことを確認 | 合格 |

最終結果は`TB_SUMMARY: pass=35 fail=0`、`TB_RESULT: PASS`であった。

## 期待されるログ出力

- `TB_PATH: simulation start`
- `TB_PATH: reset sequence start`
- `TB_PATH: CASE1 start`
- `TB_PATH: CASE2 start`
- `TB_PATH: CASE3 start`
- `TB_PATH: CASE4 start`
- `TB_INFO: CASE4 post_mid_start_second_transfer=0`
- `TB_SUMMARY: pass=35 fail=0`
- `TB_RESULT: PASS`
