# Obsidian CLI コマンドリファレンス

Vault指定: `vault=owaki` （単一Vaultなら省略可）

## ファイル操作

| コマンド | 説明 |
|---|---|
| `obsidian files` | ノート一覧。`folder=`, `ext=`, `total` オプション |
| `obsidian file file="Note"` | ファイル情報 |
| `obsidian read file="Note"` | ノート内容を取得 |
| `obsidian create name="Note"` | ノート作成。`content=`, `template=`, `overwrite`, `open` |
| `obsidian append file="Note" content="text"` | 末尾に追記。`inline` で改行なし |
| `obsidian prepend file="Note" content="text"` | 先頭に追記 |
| `obsidian move file="Note" to="Folder/"` | 移動（リンク自動更新） |
| `obsidian rename file="Note" name="NewName"` | リネーム |
| `obsidian delete file="Note"` | 削除（ゴミ箱へ） |

## 検索

| コマンド | 説明 |
|---|---|
| `obsidian search query="term"` | 全文検索。`path=`, `limit=`, `case`, `total` |
| `obsidian search:context query="term"` | マッチ行のコンテキスト付き検索 |
| `obsidian search query="[tag:name]"` | タグ検索 |
| `obsidian search query="[property:value]"` | プロパティ検索 |

## デイリーノート

| コマンド | 説明 |
|---|---|
| `obsidian daily` | 今日のデイリーノートを開く |
| `obsidian daily:read` | デイリーノートの内容取得 |
| `obsidian daily:append content="text"` | デイリーノートに追記 |
| `obsidian daily:prepend content="text"` | デイリーノートの先頭に追記 |
| `obsidian daily:path` | デイリーノートのパス取得 |

## プロパティ（YAML frontmatter）

| コマンド | 説明 |
|---|---|
| `obsidian properties` | Vault全体のプロパティ一覧 |
| `obsidian properties file="Note"` | ファイルのプロパティ |
| `obsidian property:read name="key" file="Note"` | プロパティ値の読み取り |
| `obsidian property:set name="key" value="val" file="Note"` | プロパティ設定。`type=text\|list\|number\|checkbox\|date\|datetime` |
| `obsidian property:remove name="key" file="Note"` | プロパティ削除 |

## タグ・リンク

| コマンド | 説明 |
|---|---|
| `obsidian tags` | タグ一覧。`sort=count`, `counts` |
| `obsidian tags file="Note"` | ファイルのタグ |
| `obsidian tag name="tagname"` | タグ情報。`total`, `verbose` |
| `obsidian backlinks file="Note"` | 被リンク一覧 |
| `obsidian links file="Note"` | 発リンク一覧 |
| `obsidian orphans` | 孤立ノート（被リンクなし） |
| `obsidian deadends` | 行き止まりノート（発リンクなし） |
| `obsidian unresolved` | 未解決リンク |

## タスク

| コマンド | 説明 |
|---|---|
| `obsidian tasks` | 全タスク一覧。`done`, `todo`, `verbose` |
| `obsidian tasks file="Note"` | ファイル内のタスク |
| `obsidian task ref="path:line" done` | タスクを完了にする |
| `obsidian task ref="path:line" toggle` | タスク状態をトグル |

## テンプレート

| コマンド | 説明 |
|---|---|
| `obsidian templates` | テンプレート一覧 |
| `obsidian template:read name="Template"` | テンプレート内容を読む |
| `obsidian template:insert name="Template"` | アクティブファイルにテンプレートを挿入 |

## Vault情報

| コマンド | 説明 |
|---|---|
| `obsidian vault` | Vault情報。`info=name\|path\|files\|folders\|size` |
| `obsidian vaults` | Vault一覧 |
| `obsidian folders` | フォルダ一覧 |
| `obsidian outline file="Note"` | 見出し構造。`format=tree\|md\|json` |
| `obsidian wordcount file="Note"` | 文字数・単語数 |
| `obsidian recents` | 最近開いたファイル |
| `obsidian bookmarks` | ブックマーク一覧 |
| `obsidian aliases` | エイリアス一覧 |

## 出力形式

`format=` パラメータで指定可能: `json`, `csv`, `tsv`, `md`, `paths`, `yaml`, `tree`, `text`
（コマンドにより対応形式が異なる）
