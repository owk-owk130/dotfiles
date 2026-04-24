---
name: copilot-review-apply
description: "PR に付いた GitHub Copilot のレビューコメントを取得し、妥当なものだけ修正を適用する。レビュー未到達なら一定時間待機し、届いたら処理する。棄却したコメントには見送り理由を返信する。"
---

# Apply Copilot Review

PR（引数で指定 or 現在ブランチから推定）に付いた GitHub Copilot のレビューを取り込み、妥当と判断したものだけコードに反映する。PR 作成直後でまだレビューが届いていないケースに対応するため、一定時間はポーリングで待機する。

## 呼び出し方

- レビュー到達待ちを含む場合（PR 作成直後）: `/loop /copilot-review-apply`（interval なしの dynamic mode で呼ぶ）
- 既にレビュー済みの PR を処理する場合: `/copilot-review-apply <PR番号>` で 1 回実行

## 手順

### 1. 対象 PR の特定

引数で PR 番号が渡されていればそれを使う。なければ現在ブランチから推定する。

```bash
gh pr view --json number,url,headRepositoryOwner,headRepository,createdAt \
  -q '{n:.number,url:.url,owner:.headRepositoryOwner.login,repo:.headRepository.name,createdAt:.createdAt}'
```

### 2. Copilot レビューの取得状況を確認

レビュー本体（reviews）と、インラインコメント（comments）を取得する。

```bash
# レビュー本体（到達判定に使う）
gh api "repos/{owner}/{repo}/pulls/{n}/reviews" --paginate

# インラインコメント（ファイル/行に紐づく指摘）
gh api "repos/{owner}/{repo}/pulls/{n}/comments" --paginate
```

Copilot の投稿者名は `Copilot` または `copilot-pull-request-reviewer[bot]`。`user.login` で両方にマッチさせる。

### 3. 未到達時の待機ループ

Copilot の review が 1 件も見つからない場合：

- **経過時間チェック**: PR の `createdAt`（または skill 初回起動時刻）と現在時刻を比較
- **5 分以内**: `ScheduleWakeup` で 60〜120 秒後に再実行（`delaySeconds: 90` 目安）し、自分はその回を終了する
- **5 分超過**: 「Copilot レビューが 5 分以内に届きませんでした」と報告して終了（`ScheduleWakeup` を呼ばずにループを閉じる）

dynamic mode 外で呼ばれている場合は `ScheduleWakeup` が使えないため、その旨を報告して終了する。

### 4. 二重適用の防止

取得した各インラインコメントについて、既に返信スレッドがぶら下がっているものはスキップする。

```bash
# コメントのスレッド返信を取得（in_reply_to_id が自分の id と一致するもの）
gh api "repos/{owner}/{repo}/pulls/{n}/comments" --paginate \
  | jq '[.[] | select(.in_reply_to_id != null)]'
```

自分（bot ではないユーザー）の返信が既についているコメントは処理済みとみなす。

### 5. 妥当性の判定

未処理のコメントを Claude が読んで判定する。判定前に必ず該当ファイルを `Read` で確認する（`diff_hunk` だけで判断しない）。

- **妥当（適用する）**
  - 明確なバグ・未定義参照・型エラーなどの指摘
  - セキュリティ上の問題
  - 既存コードベースのスタイル/規約から逸脱している箇所の指摘
  - 可読性を明確に改善する修正提案
- **棄却（適用しない）**
  - 既存コードや設計方針と矛盾する提案
  - 好みの範疇のリファクタ（nitpick）で明確な改善がないもの
  - 前提を誤解している指摘（周辺コンテキストを読めば不要とわかるもの）
  - YAGNI 原則に反する追加提案

### 6. 妥当なコメントの修正適用

`Edit` で該当箇所を修正する。複数コメントが同じファイルに及ぶ場合はまとめて適用する。

修正後は CLAUDE.md のグローバルルールに従い、必要なら `test` / `lint` / `format` を実行して確認する。

### 7. 棄却コメントへの返信

棄却した各コメントには、見送り理由を添えて返信スレッドを立てる。

```bash
gh api -X POST "repos/{owner}/{repo}/pulls/{n}/comments/{comment_id}/replies" \
  -f body="この指摘は〇〇の理由で見送ります。"
```

返信文は 1〜2 文で簡潔に、理由を具体的に書く（例：「既存の○○モジュールと整合させるため現状維持」「YAGNI のため追加実装は見送り」）。

### 8. 結果サマリの提示

ユーザーに以下を報告する：

- 取得したコメント総数 / 新規処理分
- 適用した件数（修正ファイル一覧）
- 棄却した件数（各コメントの URL と見送り理由）
- スキップ（処理済み）件数

コメント処理が終わったら `ScheduleWakeup` は呼ばずにループを閉じる。

## 注意事項

- **コミット / プッシュは明示指示があるまで実行しない**（ユーザーの CLAUDE.md ルール）
- 待機ループは最大 5 分。それ以降は自動で打ち切る
- 判定は必ず対象ファイルの現行コードを読んでから行う
- Copilot の投稿者名は環境によって `Copilot` / `copilot-pull-request-reviewer[bot]` など揺れがあるので、どちらもマッチさせる
- 返信は「スレッド内返信」（`/comments/{id}/replies` エンドポイント）を使い、新規コメントを立てない
- 既に返信済みのコメントは対象外（二重適用防止）
