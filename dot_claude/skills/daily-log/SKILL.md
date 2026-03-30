---
name: daily-log
description: >
  デイリーノートの管理スキル。朝の計画・随時メモ・開発ログの自動収集を Obsidian デイリーノートに記録する。
  Use when: (1) /daily コマンドを実行した場合,
  (2) 一日の作業記録を残したい場合,
  (3) 作業メモを記録したい場合。
---

# Daily

Obsidian デイリーノートを管理するスキル。

## サブコマンド

| Args | Action |
|------|--------|
| なし | 今日のデイリーノートの内容を表示 |
| `start` | 朝の計画を記録（前日ログの表示 + 今日のやること入力） |
| `memo <text>` | タイムスタンプ付きメモを追記 |
| `log` | Git コミット・PR を自動収集して書き込み |
| `log dry-run` | 収集結果をプレビュー表示のみ |
| `log YYYY-MM-DD` | 指定日のログを収集して書き込み |

---

## 共通設定

### デイリーノートのパス

```
~/Library/Mobile Documents/iCloud~md~obsidian/Documents/owaki/Daily/{YYYY-MM-DD}.md
```

### デイリーノートのテンプレート（新規作成時）

```markdown
---
tags:
  - daily
  - {YYYY-MM}
date: {YYYY/MM/DD}
title: {YYYY_MM_DD}デイリーノート
---

## メモ


## コメント
```

### マーカー方式による冪等書き込み

各セクションは HTML コメントのマーカーで囲む:

- `<!-- daily-start:start -->` / `<!-- daily-start:end -->`
- `<!-- daily-log:start -->` / `<!-- daily-log:end -->`
- `<!-- daily-memo:start -->` / `<!-- daily-memo:end -->`

**書き込みルール**:

1. マーカーが既に存在 → そのブロックを Edit ツールで **置換**
2. マーカーが存在しない → 所定の位置に **挿入**
3. デイリーノートが存在しない → テンプレートから **新規作成**

**挿入位置（マーカーがない場合）**:

```
(frontmatter)

<!-- daily-start:start -->     ← start セクション
...
<!-- daily-start:end -->

<!-- daily-log:start -->       ← log セクション
...
<!-- daily-log:end -->

## メモ

<!-- daily-memo:start -->      ← memo セクション
...
<!-- daily-memo:end -->

## コメント
```

### 注意事項（全サブコマンド共通）

- 既存の `## メモ` `## コメント` セクションの **手書き内容は絶対に変更しない**
- マーカーの HTML コメント自体を削除・変更しない
- デイリーノートの frontmatter を変更しない

---

## `/daily` — デイリーノートの表示

引数なしで実行した場合、今日のデイリーノートを Read ツールで読み込み、内容を表示する。

---

## `/daily start` — 朝の計画

### 手順

1. **前日のデイリーノートを確認**
   - 直近のデイリーノート（前営業日）を探して Read する
   - `<!-- daily-log:start -->` 内の開発ログがあれば表示する
   - 前日のノートがなければスキップ

2. **今日のやることをヒアリング**
   - 「今日やることを教えてください」とユーザーに質問
   - 自由形式のテキストを受け付ける

3. **デイリーノートに書き込み**

```markdown
<!-- daily-start:start -->
## 今日のやること
- {ユーザーが入力した内容を箇条書きに整形}
<!-- daily-start:end -->
```

---

## `/daily memo` — タイムスタンプ付きメモ

### 手順

1. 引数の `<text>` 部分をメモ内容として取得
2. 現在時刻を `HH:MM` 形式で取得（`date +%H:%M`）
3. デイリーノートの memo セクションに追記

### 書き込みルール

- マーカーが存在する場合: `<!-- daily-memo:end -->` の **直前** にメモ行を追加
- マーカーが存在しない場合: `## メモ` の直後にマーカーごと挿入

```markdown
<!-- daily-memo:start -->
- 10:32 認証方式はJWTに決定
- 14:15 レビュー完了、修正点3件      ← 新しいメモが末尾に追加される
<!-- daily-memo:end -->
```

**memo は追記型**: 既存のメモ行は消さず、末尾に追加する。log や start と異なり置換しない。

---

## `/daily log` — 開発ログの自動収集

### 手順

#### 1. 対象日の決定

```bash
TARGET_DATE=$(date +%Y-%m-%d)       # 引数なしの場合
NEXT_DATE=$(date -j -v+1d -f "%Y-%m-%d" "$TARGET_DATE" "+%Y-%m-%d")
```

引数に `YYYY-MM-DD` がある場合はそちらを使用。

#### 2. Git リポジトリの検出

```bash
find ~/Documents/projects -maxdepth 3 -name ".git" -type d \
  ! -path "*/node_modules/*" ! -path "*/archive/*" \
  2>/dev/null | sed 's/\/\.git$//'
```

#### 3. 各リポジトリからコミット収集

```bash
AUTHOR_EMAIL=$(git -C "$REPO" config user.email 2>/dev/null || git config --global user.email)

git -C "$REPO" log \
  --since="${TARGET_DATE}T00:00:00" \
  --until="${NEXT_DATE}T00:00:00" \
  --author="$AUTHOR_EMAIL" \
  --format="%h %s" \
  --all
```

- コミットがないリポジトリはスキップ

#### 4. PR 情報の収集

各リポジトリで GitHub remote がある場合:

```bash
REMOTE=$(git -C "$REPO" remote get-url origin 2>/dev/null)
GH_REPO=$(echo "$REMOTE" | sed -n 's|.*github\.com[:/]\(.*\)\.git$|\1|p; s|.*github\.com[:/]\(.*\)$|\1|p')

if [ -n "$GH_REPO" ]; then
  gh pr list --repo "$GH_REPO" --author @me --state all \
    --json number,title,state,updatedAt \
    --jq ".[] | select(.updatedAt >= \"${TARGET_DATE}T00:00:00Z\")"
fi
```

- `gh` コマンドがエラーの場合はスキップして続行
- PR 取得に時間がかかる場合があるので、複数リポジトリは並列で実行する

#### 5. フォーマット生成

```markdown
<!-- daily-log:start -->
## 開発ログ

### {プロジェクト名}

**Commits**
- `abc1234` feat: add auth endpoint
- `def5678` fix: resolve timeout (feat/auth)

**Pull Requests**
- #123 ユーザー認証機能の追加 `MERGED`
- #124 API レスポンス改善 `OPEN`

<!-- daily-log:end -->
```

**フォーマットルール**:

- プロジェクト名はディレクトリ名を使用
- コミットもPRもないプロジェクトは省略
- プロジェクトはアルファベット順にソート
- Commits セクション: `` `ハッシュ7桁` `` + メッセージ
- PR セクション: #番号 + タイトル + `` `OPEN` `` / `` `MERGED` `` / `` `CLOSED` ``
- PR のみ・コミットのみの場合は該当セクションだけ表示
- 全リポジトリで活動なし → 「本日の開発活動はありません。」

#### 6. 書き込み（またはプレビュー）

- `dry-run` の場合: フォーマット結果をユーザーに表示して終了
- 通常: マーカー方式でデイリーノートに書き込み
