# SHA-256簡易ハッシュ回路 期待値表

## テスト条件

- クロック周期: `10 ns`
- 入力形式: padding済み512 bitブロックを32 bit word 16個として入力する
- 出力形式: 256 bitハッシュ値を32 bit word 8個として読み出す
- 使用コマンド: `cmd_i=3'b010`（初回ブロック）、`cmd_i=3'b110`（継続ブロック）、`cmd_i=3'b001`（ハッシュ値読み出し）

## 期待値表

| ケース | 入力条件 | 確認内容 | 期待値 |
| --- | --- | --- | --- |
| RESET | `rst_i=1` | 初期状態 | `cmd_o=4'b0000`、`text_o=32'h00000000`、`dut.busy=0` |
| CASE1 | 文字列`abc`をpaddingした1ブロック | 基本的な1ブロックSHA-256計算 | ハッシュ値が`ba7816bf...f20015ad`と一致する |
| CASE2 | 空入力をpaddingした1ブロック | 実データがない場合の特殊入力 | ハッシュ値が`e3b0c442...7852b855`と一致する |
| CASE3 | 長い文字列をpaddingした2ブロック | 継続ブロック処理 | ハッシュ値が`248d6a61...19db06c1`と一致する |

各計算ケースでは、以下も共通して確認する。

- 書き込み開始後に内部`busy`が`1`となること
- `cmd_o[3]`が計算中に`1`となること
- 計算完了後に`cmd_o[3]`が`0`へ戻ること
- 読み出しコマンド後に`text_o`からハッシュ値が上位32 bit wordから順番に出力されること
- 各32 bit wordおよび256 bitハッシュ値全体が期待値と一致すること

## 入力ブロックと期待されるハッシュ値

### CASE1

入力メッセージは文字列`abc`である。SHA-256 padding後の512 bitブロックは以下の通りである。

| word | 値 |
| --- | --- |
| W0 | `32'h61626380` |
| W1 | `32'h00000000` |
| W2 | `32'h00000000` |
| W3 | `32'h00000000` |
| W4 | `32'h00000000` |
| W5 | `32'h00000000` |
| W6 | `32'h00000000` |
| W7 | `32'h00000000` |
| W8 | `32'h00000000` |
| W9 | `32'h00000000` |
| W10 | `32'h00000000` |
| W11 | `32'h00000000` |
| W12 | `32'h00000000` |
| W13 | `32'h00000000` |
| W14 | `32'h00000000` |
| W15 | `32'h00000018` |

期待されるSHA-256ハッシュ値は以下の通りである。

| ハッシュ値のword | 期待値 |
| --- | --- |
| D0 | `32'hba7816bf` |
| D1 | `32'h8f01cfea` |
| D2 | `32'h414140de` |
| D3 | `32'h5dae2223` |
| D4 | `32'hb00361a3` |
| D5 | `32'h96177a9c` |
| D6 | `32'hb410ff61` |
| D7 | `32'hf20015ad` |

### CASE2

入力メッセージは空入力である。実データは存在せず、paddingとメッセージ長のみで1ブロックを構成する。

| word | 値 |
| --- | --- |
| W0 | `32'h80000000` |
| W1 | `32'h00000000` |
| W2 | `32'h00000000` |
| W3 | `32'h00000000` |
| W4 | `32'h00000000` |
| W5 | `32'h00000000` |
| W6 | `32'h00000000` |
| W7 | `32'h00000000` |
| W8 | `32'h00000000` |
| W9 | `32'h00000000` |
| W10 | `32'h00000000` |
| W11 | `32'h00000000` |
| W12 | `32'h00000000` |
| W13 | `32'h00000000` |
| W14 | `32'h00000000` |
| W15 | `32'h00000000` |

期待されるSHA-256ハッシュ値は以下の通りである。

| ハッシュ値のword | 期待値 |
| --- | --- |
| D0 | `32'he3b0c442` |
| D1 | `32'h98fc1c14` |
| D2 | `32'h9afbf4c8` |
| D3 | `32'h996fb924` |
| D4 | `32'h27ae41e4` |
| D5 | `32'h649b934c` |
| D6 | `32'ha495991b` |
| D7 | `32'h7852b855` |

### CASE3

入力メッセージは、OpenCores付属テストベンチで用いられている以下の文字列である。

```text
abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq
```

この入力は56 byte、すなわち448 bitである。SHA-256のpaddingにより、2個の512 bitブロックとして処理される。

1ブロック目は`cmd_i=3'b010`で入力する。

| word | 値 |
| --- | --- |
| W0 | `32'h61626364` |
| W1 | `32'h62636465` |
| W2 | `32'h63646566` |
| W3 | `32'h64656667` |
| W4 | `32'h65666768` |
| W5 | `32'h66676869` |
| W6 | `32'h6768696a` |
| W7 | `32'h68696a6b` |
| W8 | `32'h696a6b6c` |
| W9 | `32'h6a6b6c6d` |
| W10 | `32'h6b6c6d6e` |
| W11 | `32'h6c6d6e6f` |
| W12 | `32'h6d6e6f70` |
| W13 | `32'h6e6f7071` |
| W14 | `32'h80000000` |
| W15 | `32'h00000000` |

2ブロック目は`cmd_i=3'b110`で入力する。

| word | 値 |
| --- | --- |
| W0 | `32'h00000000` |
| W1 | `32'h00000000` |
| W2 | `32'h00000000` |
| W3 | `32'h00000000` |
| W4 | `32'h00000000` |
| W5 | `32'h00000000` |
| W6 | `32'h00000000` |
| W7 | `32'h00000000` |
| W8 | `32'h00000000` |
| W9 | `32'h00000000` |
| W10 | `32'h00000000` |
| W11 | `32'h00000000` |
| W12 | `32'h00000000` |
| W13 | `32'h00000000` |
| W14 | `32'h00000000` |
| W15 | `32'h000001c0` |

期待されるSHA-256ハッシュ値は以下の通りである。

| ハッシュ値のword | 期待値 |
| --- | --- |
| D0 | `32'h248d6a61` |
| D1 | `32'hd20638b8` |
| D2 | `32'he5c02693` |
| D3 | `32'h0c3e6039` |
| D4 | `32'ha33ce459` |
| D5 | `32'h64ff2167` |
| D6 | `32'hf6ecedd4` |
| D7 | `32'h19db06c1` |

## 実シミュレーション結果

Vivado Behavioral Simulationを実行した結果、全49判定が合格した。`TB_FAIL`は出力されず、最終結果は`TB_RESULT: PASS`であった。

| ケース | 実シミュレーション結果 | 判定 |
| --- | --- | --- |
| RESET | `cmd_o=4'b0000`、`text_o=32'h00000000`、`busy=0`を確認 | 合格 |
| CASE1 | ハッシュ値が`ba7816bf 8f01cfea 414140de 5dae2223 b00361a3 96177a9c b410ff61 f20015ad`と一致 | 合格 |
| CASE2 | ハッシュ値が`e3b0c442 98fc1c14 9afbf4c8 996fb924 27ae41e4 649b934c a495991b 7852b855`と一致 | 合格 |
| CASE3 | ハッシュ値が`248d6a61 d20638b8 e5c02693 0c3e6039 a33ce459 64ff2167 f6ecedd4 19db06c1`と一致 | 合格 |

## 期待されるログ出力

- DUT:
  - `TB_DUT_PATH: during reset ...`
  - `TB_DUT_PATH: CASE1 calculation complete ...`
  - `TB_DUT_PATH: CASE2 calculation complete ...`
  - `TB_DUT_PATH: CASE3 block0 calculation complete ...`
  - `TB_DUT_PATH: CASE3 block1 calculation complete ...`
  - `TB_DUT_PATH: CASE1 digest read complete ...`
  - `TB_DUT_PATH: CASE2 digest read complete ...`
  - `TB_DUT_PATH: CASE3 digest read complete ...`
- テストベンチ:
  - `TB_PATH: simulation start`
  - `TB_PATH: reset sequence start`
  - `TB_PATH: CASE1 start`
  - `TB_PATH: CASE2 start`
  - `TB_PATH: CASE3 start`
  - `TB_CASE: CASE1 write block ...`
  - `TB_CASE: CASE2 write block ...`
  - `TB_CASE: CASE3 block0 write block ...`
  - `TB_CASE: CASE3 block1 write block ...`
  - `TB_INFO: CASE1 digest_word0 ...`
  - `TB_INFO: CASE2 digest_word0 ...`
  - `TB_INFO: CASE3 digest_word0 ...`
  - `TB_SUMMARY: pass=49 fail=0`
  - `TB_RESULT: PASS`
