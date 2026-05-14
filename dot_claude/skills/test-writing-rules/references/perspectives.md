# テスト観点 3 軸 詳細

書き始める前にこの軸を順に当て、ケース候補を列挙してから技法（`techniques.md`）で具体化する。

## 軸 1: 入出力の分類

「正常系だけ書いて満足する」を避けるため、入力空間を 4 種に分けて漏れを潰す。

### 正常系 (happy path)

仕様通りの代表的入力で仕様通りの出力が返ること。最低 1 ケースは置く。複数の正常系が論理的に区別できる場合（例: ログイン済み / 未ログイン）はそれぞれに 1 ケース。

### 準正常系 (edge cases)

仕様の許容範囲だが、扱いを間違いやすい入力:

- **境界**: 0, 1, 上限値, 上限+1, 空配列, 1 要素配列
- **空・null 系**: `""`, `[]`, `{}`, `null`, `undefined`, `NaN`, `0`, `-0`
- **特殊値**: 重複要素、順不同、Unicode（絵文字・サロゲートペア・結合文字）、改行を含む文字列、極端に長い文字列、極端に大きい / 小さい数値、`Infinity`
- **冗長性**: 末尾空白、大文字小文字差、全角半角差、BOM 付き文字列
- **時刻系**: 過去・未来、タイムゾーン跨ぎ、うるう年、夏時間境界

### 異常系 (error path)

仕様で定義されたエラー応答を返すべき入力。エラーの **型・メッセージ・コードまでアサート** する。「エラーが出ること」だけでは弱い。エラー伝達形式は問わない（Result/Either/throw のいずれでも、その型まで検証する）:

```ts
// Result を返す設計
const r = parseConfig(invalid);
expect(r.ok).toBe(false);
expect(r.error).toBeInstanceOf(ValidationError);
expect(r.error.message).toMatch(/missing field "name"/);

// throw する設計
expect(() => parseConfig(invalid)).toThrow(ValidationError);
expect(() => parseConfig(invalid)).toThrow(/missing field "name"/);
```

### 例外系 (exception path)

仕様外の前提崩壊（プログラムバグ、不変条件違反、上流の異常状態）で起きる throw / reject の経路。ユーザー入力起因の異常系と分けて、想定外入力で SpecificError が確実に上がることを `expect(...).rejects.toThrow(SpecificError)` で型まで確認する。

## 軸 2: 機能横断の観点

AI 生成コードで欠落しがちなため明示的に当てる。

| 観点 | 具体的に何を確認するか |
| --- | --- |
| **冪等性** | 同じ入力で 2 回呼んでも同じ結果になるか / 副作用が重複しないか |
| **並行性** | 同時実行で race condition が起きないか / lock の取得順 |
| **順序依存** | 入力順を変えても結果が変わらないことを確認、もしくは順序が結果に影響することを明示 |
| **タイムアウト・リトライ** | 上流が遅延・失敗したときの挙動、リトライ回数・バックオフ |
| **部分失敗** | 複数ステップの中で 1 つ失敗したときのロールバック / 中断 / 残骸 |
| **リソースリーク** | open したハンドル・接続・タイマー・サブスクリプションが close されるか |
| **入力サニタイズ** | SQL / シェル / HTML / パスのインジェクション余地 |
| **i18n・エンコーディング** | 多言語入出力、UTF-8/UTF-16 境界、ロケール依存ソート・大小比較 |
| **観測性** | ログ・メトリクス・トレースが期待通り出るか（重要パスのみ） |

## 軸 3: ドメイン特有の観点

対象機能のドメインに応じて当てる。プロジェクトに応じて追加する。

### LLM / Agent

- context window 溢れ
- ストリーミング途中で接続切断
- 不正 JSON 応答 / 部分応答
- tool call の空・重複・無限ループ
- structured output のスキーマ違反
- PII / secret の漏洩
- プロンプトインジェクション耐性
- レート制限・リトライ予算

### Cloudflare ランタイム

- KV の eventual consistency
- D1 のトランザクション境界・lock
- R2 の eventual visibility / multipart upload 中断
- Durable Objects の分離境界・hibernation
- Workers の CPU time / sub-request 数上限
- Cron Trigger の重複起動

### ブラウザ / フロントエンド

- localStorage / sessionStorage の容量制限・QuotaExceededError
- Network 失敗・slow 3G
- focus / blur / route 変化時の状態保持
- a11y（キーボード操作・スクリーンリーダー）
- レスポンシブ / DPI 差
- Back/Forward ナビゲーション、bfcache

### バックエンド API

- 認可境界（他テナントのデータが見えないか）
- ページング境界（最初・最後・空）
- N+1 クエリ
- contract（OpenAPI / Proto との整合）

### バッチ / ワークフロー

- 中断・再開で重複処理が起きないか
- 失敗ステップのリトライ起点
- 入力 0 件、巨大件数

## ミューテーション思考の例

書いたケースが本当に効くか、頭の中で実装を mutate して落ちるか確認:

| 元のコード | mutation | このテストで落ちるべき |
| --- | --- | --- |
| `if (x > 10)` | `if (x >= 10)` | 境界値（10 と 11）で挙動差を見るケース |
| `a && b` | `a \|\| b` | 片方 true / 片方 false の組合せ |
| `return x` | `return undefined` | 戻り値そのものを assert |
| `arr.filter(p)` | `arr` | 空配列を返すべき入力 |
| `Math.max(a,b)` | `Math.min(a,b)` | a < b と a > b 両方 |

落ちないなら、そのテストは仕様ではなく実装を写しているだけの可能性が高い。
