# SPI Slave回路 期待値表

## テスト条件

- シミュレーション時間単位: `1 ns / 1 ps`
- SPI動作モード: mode 3
- `sck`アイドル値: High
- `sck`立下り: `sdout`の更新点
- `sck`立上り: `sdin`の受信点
- データ幅: 8 bit
- `sck`の周期: 21 ns（Low期間: 10 ns、High期間: 11 ns）
- スレーブ選択: `ss=0`で選択、`ss=1`で非選択

## 期待値表

| ケース | 入力条件 | 期待される`sdout` | 期待される`rdata` | 期待される`done` |
| --- | --- | --- | --- | --- |
| RESET | `rstb=0`、`ss=1` | `Z` | `8'h00` | `0` |
| CASE1_LSB_BASIC | `mlb=0`、`ten=1`、`ss=0`、`tdata=8'h96`、`sdin=8'h53` | `0,1,1,0,1,0,0,1` | `8'h53` | 8 bit受信後に`1` |
| CASE2_MSB_BASIC | `mlb=1`、`ten=1`、`ss=0`、`tdata=8'h96`、`sdin=8'h53` | `1,0,0,1,0,1,1,0` | `8'h53` | 8 bit受信後に`1` |
| CASE3_TEN_DISABLED | `mlb=0`、`ten=0`、`ss=0`、`tdata=8'h96`、`sdin=8'h3A` | 常に`Z` | `8'h3A` | 8 bit受信後に`1` |
| CASE4_SS_INACTIVE | `mlb=0`、`ten=1`、`ss=1`、`tdata=8'h96`、`sdin=8'h53` | 常に`Z` | `8'h00`を維持 | `0`を維持 |

`8'h96`、`8'h53`および`8'h3A`は、ビット反転しても同じ値にならないデータである。このため、LSB firstとMSB firstの送信順序および受信順序の違いを区別できる。

## 実シミュレーション結果

Vivado Behavioral Simulationを実行した結果、全21判定が合格した。`TB_FAIL`は出力されず、最終結果は`TB_RESULT: PASS`であった。

| ケース | 実測結果 | 判定 |
| --- | --- | --- |
| RESET | `done=0`、`rdata=8'h00`、`sdout=z` | 合格 |
| CASE1_LSB_BASIC | `sdout=0,1,1,0,1,0,0,1`、`rdata=8'h53`、`done=1` | 合格 |
| CASE2_MSB_BASIC | `sdout=1,0,0,1,0,1,1,0`、`rdata=8'h53`、`done=1` | 合格 |
| CASE3_TEN_DISABLED | `sdout=z`を維持、`rdata=8'h3A`、`done=1` | 合格 |
| CASE4_SS_INACTIVE | `sdout=z`を維持、`rdata=8'h00`、`done=0`を維持 | 合格 |

## ビット単位の期待値

### CASE1_LSB_BASIC

- `tdata=8'h96`の`sdout`出力順序: `0,1,1,0,1,0,0,1`
- `sdin`から入力する`8'h53`の順序: `1,1,0,0,1,0,1,0`
- 1 bit受信後: `done=0`
- 8回目の`sck`立上り後: `rdata=8'h53`、`done=1`

### CASE2_MSB_BASIC

- `tdata=8'h96`の`sdout`出力順序: `1,0,0,1,0,1,1,0`
- `sdin`から入力する`8'h53`の順序: `0,1,0,1,0,0,1,1`
- 1 bit受信後: `done=0`
- 8回目の`sck`立上り後: `rdata=8'h53`、`done=1`

### CASE3_TEN_DISABLED

- `tdata=8'h96`を設定しても、`ten=0`のため`sdout`は8 bitの全期間で`Z`
- `sdin`から入力する`8'h3A`のLSB first順序: `0,1,0,1,1,1,0,0`
- 1 bit受信後: `done=0`
- 8回目の`sck`立上り後: `rdata=8'h3A`、`done=1`

### CASE4_SS_INACTIVE

- `ss=1`のため、8回の`sck`変化中も`sdout=Z`
- `sdin`へ`8'h53`相当のビット列を与えても、`rdata=8'h00`および`done=0`を維持する

## 期待されるログ出力

テストベンチは、次の種別のログを出力する。

- `TB_PATH`: シミュレーション開始、リセット、各テストケースの実行経路
- `TB_CASE`: テストケースの設定値
- `TB_INFO`: 各ビットの`sdout`、`sdin`、内部カウンタ`nb`および送信ビット列
- `TB_DUT_PATH`: リセット後および各転送後の`done`、`rdata`、`nb`
- `TB_PASS`: 各チェックの合格結果
- `TB_FAIL`: 各チェックの不合格結果

今回の実行では、最終行に次の内容が出力された。

```text
TB_SUMMARY: pass=21 fail=0
TB_RESULT: PASS
```
