# RS-232回路 評価報告書

## 評価対象
- 対象回路:
  - `rxuartlite.v`
- テストベンチ:
  - `tb_rxuartlite.v`

## 評価目的
- 選定した RS-232/UART 回路が、期待値表どおりに動作することを確認する。
- シミュレーションログから、以下の両方が判別できることを確認する。
  - 回路の入出力値
  - 回路本体およびテストベンチの実行パス

## 評価項目
本評価では、正常受信動作と関連するログ出力を 17 個のチェック項目として確認した。

### チェック項目一覧（17項目）
| No. | 評価項目 | 判定条件 | 実測結果 | 合否 |
| --- | --- | --- | --- | --- |
| 1 | 受信データ値 | `rx_data=8'h28` | `rx_data=8'h28` | 合格 |
| 2 | 受信完了 | `rx_done=1` | `rx_done=1` | 合格 |
| 3 | 受信完了タイミング | `rx_done` が 1 クロックだけ立つ | `rx_done` が 1 クロックで立つ | 合格 |
| 4 | 有効データ保持 | `rx_data_valid=1` | `rx_data_valid=1` | 合格 |
| 5 | パリティエラーなし | `rx_parity_error=0` | `rx_parity_error=0` | 合格 |
| 6 | フレーミングエラーなし | `rx_framing_error=0` | `rx_framing_error=0` | 合格 |
| 7 | オーバーランエラーなし | `rx_overrun_error=0` | `rx_overrun_error=0` | 合格 |
| 8 | 受信データのクリア | `pulse_data_read()` 後 `rx_data_valid=0` | `rx_data_valid=0` | 合格 |
| 9 | クリア後オーバーランなし | `pulse_data_read()` 後 `rx_overrun_error=0` | `rx_overrun_error=0` | 合格 |
| 10 | TB_PATH 開始ログ | `TB_PATH: simulation start` が出力される | 出力あり | 合格 |
| 11 | TB_PATH ケース開始ログ | `TB_PATH: normal receive test start` が出力される | 出力あり | 合格 |
| 12 | ケース成功ログ | `PASS: normal receive test passed` が出力される | 出力あり | 合格 |
| 13 | TB_SUMMARY pass | `pass=17` が最終サマリに表示される | 表示あり | 合格 |
| 14 | TB_SUMMARY fail | `fail=0` が最終サマリに表示される | 表示あり | 合格 |
| 15 | TB_FAIL 未発生 | `TB_FAIL` が 0 件である | 未発生 | 合格 |
| 16 | UART TX パスログ | `uart_tx PATH` が出力される | 出力あり | 合格 |
| 17 | UART RX パスログ | `uart_rx PATH` が出力される | 出力あり | 合格 |

## 合格条件
- `tb_rxuartlite.v` 内のチェックで `TB_FAIL` が 0 件であること
- 最終サマリに `fail=0` と表示されること
- シミュレーションログに `TB_PATH`、`TB_INFO`、`uart_tx PATH`、`uart_rx PATH` が含まれること

## Vivadoでの実行手順
1. Vivado プロジェクトを開く。
2. `tb_rxuartlite.v` を simulation top に設定する。
3. Behavioral Simulation を実行する。
4. Console ログを保存する。
5. 以下の信号を含む波形を保存する。
   - `tx_line`
   - `rx_line`
   - `rx_data`
   - `rx_done`
   - `rx_data_valid`


## シミュレーションログ
Vivado 実行時のログを以下に示す。

```text
[0] TB_PATH: simulation start
[0] rxuartlite STATE: initial -> IDLE
[795000] TB_PATH: normal receive test start, send data=0x55
[800000] TB_TX: START bit=0
[905000] rxuartlite STATE: IDLE -> BIT_ZERO
[960000] TB_TX: DATA bit0=1
run all
[1065000] rxuartlite STATE: BIT_ZERO -> BIT_ONE
[1066000] rxuartlite DATA: state=BIT_ZERO sampled_bit=1 data_reg_after=0x80
[1120000] TB_TX: DATA bit1=0
[1225000] rxuartlite STATE: BIT_ONE -> BIT_TWO
[1226000] rxuartlite DATA: state=BIT_ONE sampled_bit=0 data_reg_after=0x40
[1280000] TB_TX: DATA bit2=1
[1385000] rxuartlite STATE: BIT_TWO -> BIT_THREE
[1386000] rxuartlite DATA: state=BIT_TWO sampled_bit=1 data_reg_after=0xa0
[1440000] TB_TX: DATA bit3=0
[1545000] rxuartlite STATE: BIT_THREE -> BIT_FOUR
[1546000] rxuartlite DATA: state=BIT_THREE sampled_bit=0 data_reg_after=0x50
[1600000] TB_TX: DATA bit4=1
[1705000] rxuartlite STATE: BIT_FOUR -> BIT_FIVE
[1706000] rxuartlite DATA: state=BIT_FOUR sampled_bit=1 data_reg_after=0xa8
[1760000] TB_TX: DATA bit5=0
[1865000] rxuartlite STATE: BIT_FIVE -> BIT_SIX
[1866000] rxuartlite DATA: state=BIT_FIVE sampled_bit=0 data_reg_after=0x54
[1920000] TB_TX: DATA bit6=1
[2025000] rxuartlite STATE: BIT_SIX -> BIT_SEVEN
[2026000] rxuartlite DATA: state=BIT_SIX sampled_bit=1 data_reg_after=0xaa
[2080000] TB_TX: DATA bit7=0
[2185000] rxuartlite STATE: BIT_SEVEN -> STOP
[2186000] rxuartlite DATA: state=BIT_SEVEN sampled_bit=0 data_reg_after=0x55
[2240000] TB_TX: STOP bit=1
[2345000] rxuartlite STATE: STOP -> WAIT
[2345000] rxuartlite DONE: o_wr=1 o_data=0x55
[2355000] rxuartlite STATE: WAIT -> IDLE
[2705000] PASS: normal receive test passed
```

## 評価結果まとめ
### CASE1 正常送受信
| 項目 | 入力条件 | 期待値 | 実測値 | 判定 |
| --- | --- | --- | --- | --- |
| 送受信 | `pulse_start(8'h28)` | `rx_data=8'h28` | `rx_data=8'h28` | 合格 |
| 受信完了 | `pulse_start(8'h28)` | `rx_done=1` | `rx_done=1` | 合格 |
| 有効データ保持 | 正常受信後 | `rx_data_valid=1` | `rx_data_valid=1` | 合格 |
| パリティ異常なし | 正常受信後 | `rx_parity_error=0` | `rx_parity_error=0` | 合格 |
| フレーミング異常なし | 正常受信後 | `rx_framing_error=0` | `rx_framing_error=0` | 合格 |
| 読出し後クリア | `pulse_data_read()` 後 | `rx_data_valid=0` | `rx_data_valid=0` | 合格 |

### 総括
| 項目 | 結果 |
| --- | --- |
| 総判定 | 合格 |
| 判定数 | `pass=17` |
| 不合格数 | `fail=0` |
| 結論 | 上記の 17 項目すべてが合格し、対象回路の主要機能が期待どおりに動作したことを確認した |

## 波形キャプチャ貼付欄

### 図1 正常送受信波形
- 対象ケース: CASE1
- 推奨表示信号:
  - `tx_line`
  - `rx_line`
  - `rx_data`
  - `rx_done`
  - `rx_data_valid`
- 推奨表示時間帯: `1.0 us` から `1.2 us`
- 説明:
  - 正常な送受信により `rx_data=0x28`、`rx_done=1`、`rx_parity_error=0`、`rx_framing_error=0` となることを確認した。

![図1 正常送受信波形](./images/rxuartlite_case1.png)
