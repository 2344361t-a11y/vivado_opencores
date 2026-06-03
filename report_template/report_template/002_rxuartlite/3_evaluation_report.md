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
[0] TB_PATH: reset sequence start
[0] uart_rx PATH: reset -> IDLE
[0] uart_tx PATH: reset -> IDLE
[5000] uart_rx PATH: reset -> IDLE
[5000] uart_tx PATH: reset -> IDLE
[15000] uart_rx PATH: reset -> IDLE
[15000] uart_tx PATH: reset -> IDLE
[20000] TB_PATH: reset released
[20000] TB_PATH: CASE1 normal loopback start
[30000] TB_CASE: pulse_start data=0x28
[35000] uart_tx PATH: IDLE->START data=0x28 parity=0
[55000] uart_rx PATH: IDLE->START start_detected
[115000] uart_rx PATH: START->DATA start_confirmed
[135000] uart_tx PATH: START->DATA
[215000] uart_rx DATA: bit_index=0 bit_value=0
[235000] uart_tx DATA: bit_index=0 bit_value=0
[315000] uart_rx DATA: bit_index=1 bit_value=0
[335000] uart_tx DATA: bit_index=1 bit_value=0
[415000] uart_rx DATA: bit_index=2 bit_value=0
[435000] uart_tx DATA: bit_index=2 bit_value=0
[515000] uart_rx DATA: bit_index=3 bit_value=1
[535000] uart_tx DATA: bit_index=3 bit_value=1
[615000] uart_rx DATA: bit_index=4 bit_value=0
[635000] uart_tx DATA: bit_index=4 bit_value=0
[715000] uart_rx DATA: bit_index=5 bit_value=1
[735000] uart_tx DATA: bit_index=5 bit_value=1
[815000] uart_rx DATA: bit_index=6 bit_value=0
[835000] uart_tx DATA: bit_index=6 bit_value=0
[915000] uart_rx DATA: bit_index=7 bit_value=0
[915000] uart_rx PATH: DATA->PARITY
[935000] uart_tx DATA: bit_index=7 bit_value=0
[935000] uart_tx PATH: DATA->PARITY
[1015000] uart_rx PATH: PARITY->STOP rx_parity=0 expected=0 parity_error=0
[1035000] uart_tx PATH: PARITY->STOP parity=0
[1115000] uart_rx PATH: STOP->IDLE rx_done=1 data=0x28 overrun=0
[1125000] TB_INFO: rx_done=1 data=0x28 data_valid=1 overrun=0
[1125000] TB_PASS:                                                       CASE1 rx_data must be 0x28
[1125000] TB_PASS:                                                       CASE1 data_valid must be 1
[1125000] TB_PASS:                                                     CASE1 parity_error must be 0
[1125000] TB_PASS:                                                    CASE1 framing_error must be 0
[1130000] TB_CASE: pulse_data_read
[1135000] TB_INFO: data_read=1 data_valid=1 overrun=0
[1135000] uart_rx PATH: data_read -> clear data_valid/overrun
[1135000] uart_tx PATH: STOP->IDLE tx_complete
[1145000] TB_PASS:                                           CASE1 data_valid must clear after read
[1145000] TB_PATH: CASE2 parity error start
[1160000] TB_CASE: inject_frame data=0x55 parity=1 stop=1
[1165000] uart_rx PATH: IDLE->START start_detected
[1225000] uart_rx PATH: START->DATA start_confirmed
[1325000] uart_rx DATA: bit_index=0 bit_value=1
[1425000] uart_rx DATA: bit_index=1 bit_value=0
[1525000] uart_rx DATA: bit_index=2 bit_value=1
[1625000] uart_rx DATA: bit_index=3 bit_value=0
[1725000] uart_rx DATA: bit_index=4 bit_value=1
[1825000] uart_rx DATA: bit_index=5 bit_value=0
[1925000] uart_rx DATA: bit_index=6 bit_value=1
[2025000] uart_rx DATA: bit_index=7 bit_value=0
[2025000] uart_rx PATH: DATA->PARITY
[2125000] uart_rx PATH: PARITY->STOP rx_parity=1 expected=0 parity_error=1
[2135000] TB_INFO: parity_error=1 rx_data=0x55
[2145000] TB_INFO: parity_error=1 rx_data=0x55
[2155000] TB_INFO: parity_error=1 rx_data=0x55
[2165000] TB_INFO: parity_error=1 rx_data=0x55
[2175000] TB_INFO: parity_error=1 rx_data=0x55
[2185000] TB_INFO: parity_error=1 rx_data=0x55
[2195000] TB_INFO: parity_error=1 rx_data=0x55
[2205000] TB_INFO: parity_error=1 rx_data=0x55
[2215000] TB_INFO: parity_error=1 rx_data=0x55
[2225000] TB_INFO: parity_error=1 rx_data=0x55
[2225000] uart_rx PATH: STOP->IDLE error framing=0 parity=1
[2235000] TB_INFO: parity_error=1 rx_data=0x55
[2260000] TB_PASS:                                        CASE2 rx_done must stay 0 on parity error
[2260000] TB_PASS:                                                     CASE2 parity_error must be 1
[2260000] TB_PASS:                                                   CASE2 data_valid must remain 0
[2265000] TB_PATH: CASE3 framing error start
[2280000] TB_CASE: inject_frame data=0x33 parity=0 stop=0
[2285000] uart_rx PATH: IDLE->START start_detected
[2345000] uart_rx PATH: START->DATA start_confirmed
[2445000] uart_rx DATA: bit_index=0 bit_value=1
[2545000] uart_rx DATA: bit_index=1 bit_value=1
[2645000] uart_rx DATA: bit_index=2 bit_value=0
[2745000] uart_rx DATA: bit_index=3 bit_value=0
[2845000] uart_rx DATA: bit_index=4 bit_value=1
[2945000] uart_rx DATA: bit_index=5 bit_value=1
[3045000] uart_rx DATA: bit_index=6 bit_value=0
[3145000] uart_rx DATA: bit_index=7 bit_value=0
[3145000] uart_rx PATH: DATA->PARITY
[3245000] uart_rx PATH: PARITY->STOP rx_parity=0 expected=0 parity_error=0
[3345000] uart_rx PATH: STOP->IDLE error framing=1 parity=0
[3355000] TB_INFO: framing_error=1 rx_line=0
[3355000] uart_rx PATH: IDLE->START start_detected
[3380000] TB_PASS:                                       CASE3 rx_done must stay 0 on framing error
[3380000] TB_PASS:                                                    CASE3 framing_error must be 1
[3380000] TB_PASS:                                                   CASE3 data_valid must remain 0
[3385000] TB_PATH: CASE4 overrun start
[3400000] TB_CASE: pulse_start data=0xa5
[3405000] uart_tx PATH: IDLE->START data=0xa5 parity=0
[3415000] uart_rx PATH: START->IDLE false_start
[3425000] uart_rx PATH: IDLE->START start_detected
[3485000] uart_rx PATH: START->DATA start_confirmed
[3505000] uart_tx PATH: START->DATA
[3585000] uart_rx DATA: bit_index=0 bit_value=1
[3605000] uart_tx DATA: bit_index=0 bit_value=1
[3685000] uart_rx DATA: bit_index=1 bit_value=0
[3705000] uart_tx DATA: bit_index=1 bit_value=0
[3785000] uart_rx DATA: bit_index=2 bit_value=1
[3805000] uart_tx DATA: bit_index=2 bit_value=1
[3885000] uart_rx DATA: bit_index=3 bit_value=0
[3905000] uart_tx DATA: bit_index=3 bit_value=0
[3985000] uart_rx DATA: bit_index=4 bit_value=0
[4005000] uart_tx DATA: bit_index=4 bit_value=0
[4085000] uart_rx DATA: bit_index=5 bit_value=1
[4105000] uart_tx DATA: bit_index=5 bit_value=1
[4185000] uart_rx DATA: bit_index=6 bit_value=0
[4205000] uart_tx DATA: bit_index=6 bit_value=0
[4285000] uart_rx DATA: bit_index=7 bit_value=1
[4285000] uart_rx PATH: DATA->PARITY
[4305000] uart_tx DATA: bit_index=7 bit_value=1
[4305000] uart_tx PATH: DATA->PARITY
[4385000] uart_rx PATH: PARITY->STOP rx_parity=0 expected=0 parity_error=0
[4405000] uart_tx PATH: PARITY->STOP parity=0
[4485000] uart_rx PATH: STOP->IDLE rx_done=1 data=0xa5 overrun=0
[4495000] TB_INFO: rx_done=1 data=0xa5 data_valid=1 overrun=0
[4495000] TB_PASS:                                                 CASE4 first rx_data must be 0xA5
[4495000] TB_PASS:                                                 CASE4 first data_valid must be 1
[4505000] uart_tx PATH: STOP->IDLE tx_complete
[4520000] TB_CASE: pulse_start data=0x3c
[4525000] uart_tx PATH: IDLE->START data=0x3c parity=0
[4545000] uart_rx PATH: IDLE->START start_detected
[4605000] uart_rx PATH: START->DATA start_confirmed
[4625000] uart_tx PATH: START->DATA
[4705000] uart_rx DATA: bit_index=0 bit_value=0
[4725000] uart_tx DATA: bit_index=0 bit_value=0
[4805000] uart_rx DATA: bit_index=1 bit_value=0
[4825000] uart_tx DATA: bit_index=1 bit_value=0
[4905000] uart_rx DATA: bit_index=2 bit_value=1
[4925000] uart_tx DATA: bit_index=2 bit_value=1
[5005000] uart_rx DATA: bit_index=3 bit_value=1
[5025000] uart_tx DATA: bit_index=3 bit_value=1
[5105000] uart_rx DATA: bit_index=4 bit_value=1
[5125000] uart_tx DATA: bit_index=4 bit_value=1
[5205000] uart_rx DATA: bit_index=5 bit_value=1
[5225000] uart_tx DATA: bit_index=5 bit_value=1
[5305000] uart_rx DATA: bit_index=6 bit_value=0
[5325000] uart_tx DATA: bit_index=6 bit_value=0
[5405000] uart_rx DATA: bit_index=7 bit_value=0
[5405000] uart_rx PATH: DATA->PARITY
[5425000] uart_tx DATA: bit_index=7 bit_value=0
[5425000] uart_tx PATH: DATA->PARITY
[5505000] uart_rx PATH: PARITY->STOP rx_parity=0 expected=0 parity_error=0
[5525000] uart_tx PATH: PARITY->STOP parity=0
[5605000] uart_rx PATH: STOP->IDLE rx_done=1 data=0x3c overrun=1
[5615000] TB_INFO: rx_done=1 data=0x3c data_valid=1 overrun=1
[5615000] TB_PASS:                                                CASE4 second rx_data must be 0x3C
[5615000] TB_PASS:                                                    CASE4 overrun_error must be 1
[5615000] TB_PASS:                                          CASE4 data_valid must stay 1 until read
[5620000] TB_CASE: pulse_data_read
[5625000] TB_INFO: data_read=1 data_valid=1 overrun=1
[5625000] uart_rx PATH: data_read -> clear data_valid/overrun
[5625000] uart_tx PATH: STOP->IDLE tx_complete
[5635000] TB_PASS:                                        CASE4 overrun_error must clear after read
[5635000] TB_SUMMARY: pass=17 fail=0
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

### CASE2 パリティエラー検出
| 項目 | 入力条件 | 期待値 | 実測値 | 判定 |
| --- | --- | --- | --- | --- |
| 異常フレーム注入 | `inject_frame(8'h55, 1'b1, 1'b1)` | `rx_data=8'h55` | `rx_data=8'h55` | 合格 |
| パリティエラー検出 | 上記入力後 | `rx_parity_error=1` | `rx_parity_error=1` | 合格 |
| 正常受信不成立 | 上記入力後 | `rx_done=0` | `rx_done=0` | 合格 |
| 有効データ未設定 | 上記入力後 | `rx_data_valid=0` | `rx_data_valid=0` | 合格 |

### CASE3 フレーミングエラー検出
| 項目 | 入力条件 | 期待値 | 実測値 | 判定 |
| --- | --- | --- | --- | --- |
| 異常フレーム注入 | `inject_frame(8'h33, 1'b0, 1'b0)` | `rx_data=8'h33` を受信途中で観測 | `rx_data=8'h33` 相当のビット列を観測 | 合格 |
| フレーミングエラー検出 | 上記入力後 | `rx_framing_error=1` | `rx_framing_error=1` | 合格 |
| 正常受信不成立 | 上記入力後 | `rx_done=0` | `rx_done=0` | 合格 |
| 有効データ未設定 | 上記入力後 | `rx_data_valid=0` | `rx_data_valid=0` | 合格 |

### CASE4 オーバーランエラー検出
| 項目 | 入力条件 | 期待値 | 実測値 | 判定 |
| --- | --- | --- | --- | --- |
| 1回目正常受信 | `pulse_start(8'hA5)` | `rx_data=8'hA5` | `rx_data=8'hA5` | 合格 |
| 1回目受信後状態 | 1回目正常受信後 | `rx_data_valid=1` | `rx_data_valid=1` | 合格 |
| 2回目正常受信 | 未読のまま `pulse_start(8'h3C)` | `rx_data=8'h3C` | `rx_data=8'h3C` | 合格 |
| オーバーラン検出 | 2回目正常受信後 | `rx_overrun_error=1` | `rx_overrun_error=1` | 合格 |
| 未読状態保持 | 2回目正常受信後 | `rx_data_valid=1` | `rx_data_valid=1` | 合格 |
| 読出し後クリア | `pulse_data_read()` 後 | `rx_overrun_error=0` | `rx_overrun_error=0` | 合格 |

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

### 図2 パリティエラー検出波形
- 対象ケース: CASE2
- 推奨表示信号:
  - `rx_line`
  - `rx_data`
  - `rx_done`
  - `rx_parity_error`
  - `rx_data_valid`
- 推奨表示時間帯: `2.1 us` から `2.3 us`
- 説明:
  - parity bit を意図的に不正値とした結果、`rx_parity_error=1`、`rx_done=0` となることを確認した。

![図2 パリティエラー検出波形](./images/case2.png)

### 図3 フレーミングエラー検出波形
- 対象ケース: CASE3
- 推奨表示信号:
  - `rx_line`
  - `rx_done`
  - `rx_framing_error`
  - `rx_data_valid`
- 推奨表示時間帯: `3.24 us` から `3.36 us`
- 説明:
  - stop bit を意図的に不正値とした結果、`rx_framing_error=1`、`rx_done=0` となることを確認した。

![図3 フレーミングエラー検出波形](./images/case3.png)

### 図4 オーバーランエラー検出波形
- 対象ケース: CASE4
- 推奨表示信号:
  - `tx_line`
  - `rx_data`
  - `rx_done`
  - `rx_data_valid`
  - `rx_overrun_error`
  - `data_read`
- 推奨表示時間帯: `4.45 us` から `5.65 us`
- 説明:
  - 未読データを残したまま次フレームを受信させることで `rx_overrun_error=1` となり、`data_read` 後にクリアされることを確認した。

![図4 オーバーランエラー検出波形](./images/case4.png)
