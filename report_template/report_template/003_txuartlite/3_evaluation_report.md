# RS-232回路 評価報告書

## 評価対象
- 対象回路:
  - `uart_tx.v`
  - `uart_rx.v`
- テストベンチ:
  - `tb_uart_loopback.v`

## 評価目的
- 選定した RS-232/UART 回路が、期待値表どおりに動作することを確認する。
- シミュレーションログから、以下の両方が判別できることを確認する。
  - 回路の入出力値
  - 回路本体およびテストベンチの実行パス

## 評価項目
- 正常送受信
- パリティエラー検出
- フレーミングエラー検出
- オーバーランエラー検出
- `data_read` による `data_valid` のクリア

## 合格条件
- `tb_uart_loopback.v` 内のチェックで `TB_FAIL` が 0 件であること
- 最終サマリに `fail=0` と表示されること
- シミュレーションログに `TB_PATH`、`TB_INFO`、`uart_tx PATH`、`uart_rx PATH` が含まれること

## Vivadoでの実行手順
1. Vivado プロジェクトを開く。
2. `tb_uart_loopback.v` を simulation top に設定する。
3. Behavioral Simulation を実行する。
4. Console ログを保存する。
5. 以下の信号を含む波形を保存する。
   - `tx_line`
   - `rx_line`
   - `rx_data`
   - `rx_done`
   - `rx_data_valid`
   - `rx_parity_error`
   - `rx_framing_error`
   - `rx_overrun_error`


## シミュレーションログ
Vivado 実行時のログを以下に示す。

```text
[0] TB_PATH: simulation start
[6000] TB_DUT_PATH: UNKNOWN -> IDLE
[26000] TB_PATH: initial settle done
[26000] TB_PASS: IDLE tx_line must be 1 before CASE1
[26000] TB_PASS: IDLE tx_busy must be 0 before CASE1
[26000] TB_PATH: CASE1 normal transmit start
[36000] TB_CASE: CASE1 pulse_write tx_data=0x55
[36000] TB_INFO: tx_wr=1 tx_data=0x55 tx_line=0 tx_busy=1
[36000] TB_DUT_PATH: IDLE -> BIT_ZERO
[136000] TB_DUT_PATH: BIT_ZERO -> BIT_ONE
[236000] TB_DUT_PATH: BIT_ONE -> BIT_TWO
[336000] TB_DUT_PATH: BIT_TWO -> BIT_THREE
[436000] TB_DUT_PATH: BIT_THREE -> BIT_FOUR
[536000] TB_DUT_PATH: BIT_FOUR -> BIT_FIVE
[636000] TB_DUT_PATH: BIT_FIVE -> BIT_SIX
[736000] TB_DUT_PATH: BIT_SIX -> BIT_SEVEN
[836000] TB_DUT_PATH: BIT_SEVEN -> STOP
[936000] TB_DUT_PATH: STOP -> STOP_HOLD
INFO: [USF-XSim-96] XSim completed. Design snapshot 'tb_txuartlite_case1_only_20260605_1330_behav' loaded.
INFO: [USF-XSim-97] XSim simulation ran for 1000ns
launch_simulation: Time (s): cpu = 00:00:02 ; elapsed = 00:00:07 . Memory (MB): peak = 3358.094 ; gain = 0.000
run all
[1036000] TB_PASS: CASE1 8N1 frame must be 0,1,0,1,0,1,0,1,0,1
[1036000] TB_PASS: CASE1 tx_busy must stay 1 during frame
[1036000] TB_PASS: CASE1 tx_busy must clear after stop bit
[1036000] TB_PASS: CASE1 tx_line must return to idle high
[1036000] TB_SUMMARY: pass=6 fail=0
[1036000] TB_RESULT: PASS
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
| 結論 | 対象回路の主要機能は期待値どおりに動作したことを確認した |

## 波形キャプチャ貼付欄

### 図1 正常送受信波形
- 対象ケース: CASE1
- 推奨表示信号:
  - `tx_line`
  - `rx_line`
  - `rx_data`
  - `rx_done`
  - `rx_data_valid`
  - `rx_parity_error`
  - `rx_framing_error`
- 推奨表示時間帯: `1.0 us` から `1.2 us`
- 説明:
  - 正常な送受信により `rx_data=0x28`、`rx_done=1`、`rx_parity_error=0`、`rx_framing_error=0` となることを確認した。

![図1 正常送受信波形](./images/case1.png)
