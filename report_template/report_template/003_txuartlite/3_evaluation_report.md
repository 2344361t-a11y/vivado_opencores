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
