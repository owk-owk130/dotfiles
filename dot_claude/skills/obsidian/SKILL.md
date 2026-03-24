---
name: obsidian
description: "Obsidian Vaultのノートを操作する。ノートの読み取り・作成・編集・検索・削除、デイリーノート操作、タグ・プロパティ管理を公式Obsidian CLIで実行する。Use when: (1) ユーザーが /obsidian コマンドでノート操作を依頼した場合, (2) Obsidianのノートを読みたい・書きたい・検索したい場合, (3) デイリーノートの操作, (4) ノートのメタデータ（タグ・プロパティ）を操作したい場合。"
---

# Obsidian

公式 Obsidian CLI (`obsidian` コマンド) を使ってVault `owaki` のノートを操作する。

## 前提条件

- Obsidian アプリが起動中であること（CLIはアプリと通信して動作する）
- CLIが有効化されていること（設定 > 一般 > 詳細設定 > Command line interface）

## CLI実行方法

CLIのPATHはログインシェルで設定されるため、Bashツールからは `zsh -l -c` で実行する。

```bash
zsh -l -c 'obsidian read file="ノート名"'
```

複数コマンド実行時:
```bash
zsh -l -c 'obsidian search query="keyword" && obsidian read file="Result"'
```

contentにシングルクォートや特殊文字を含む場合:
```bash
zsh -l -c "obsidian append file=\"Note\" content=\"追記内容\""
```

## コマンドリファレンス

詳細なコマンド一覧は [references/commands.md](references/commands.md) を参照。

## 基本ワークフロー

### ノートを読む

```bash
zsh -l -c 'obsidian read file="ノート名"'
```

### ノートを検索する

```bash
# 全文検索
zsh -l -c 'obsidian search query="検索語"'
# コンテキスト付き検索（マッチ行の前後も表示）
zsh -l -c 'obsidian search:context query="検索語"'
# タグで検索
zsh -l -c 'obsidian search query="[tag:タグ名]"'
```

### ノートを作成する

```bash
zsh -l -c 'obsidian create name="新しいノート"'
# テンプレート使用
zsh -l -c 'obsidian create name="ノート名" template="テンプレート名"'
# 初期内容付き
zsh -l -c 'obsidian create name="ノート名" content="# タイトル\n\n本文"'
```

### ノートに追記する

```bash
zsh -l -c 'obsidian append file="ノート名" content="追記内容"'
# 先頭に追記
zsh -l -c 'obsidian prepend file="ノート名" content="追記内容"'
```

### デイリーノート

```bash
# 今日のデイリーノートを読む
zsh -l -c 'obsidian daily:read'
# デイリーノートに追記
zsh -l -c 'obsidian daily:append content="追記内容"'
```

### ファイル一覧・構造把握

```bash
# ファイル一覧
zsh -l -c 'obsidian files'
# フォルダ一覧
zsh -l -c 'obsidian folders'
# ノートの見出し構造
zsh -l -c 'obsidian outline file="ノート名"'
```

## 注意事項

- ファイル名にスペースを含む場合はクォートで囲む: `file="My Note"`
- パスにフォルダを含む場合: `file="Folder/Note"`
- `\n` で改行、`\t` でタブを挿入可能
- 削除はゴミ箱に移動（`permanent` で完全削除だが非推奨）
- 内容の書き込み時は Markdown 形式を使う
- 出力形式は `format=json|csv|tsv|md|paths|yaml|tree|text` で指定可能
