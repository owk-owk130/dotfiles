---
name: update-docs
description: "コード変更に応じてドキュメント（CLAUDE.md, README.md）を自動更新する"
---

# Update Documentation

コードの変更内容を検出し、関連するドキュメントを最新の仕様に更新する。

## 手順

1. `git diff --name-only` で変更ファイルを検出（引数で対象を指定可能）
2. 変更ファイルのパスから影響を受けるドキュメントを特定
3. 実際のコードとドキュメントを比較して不整合を検出
4. 不整合があれば修正内容をユーザーに提示して確認を求める
5. 承認後に修正を実行

## 変更ファイルとドキュメントのマッピング

| 変更ファイルのパス | 影響を受けるドキュメント | 確認項目 |
|-------------------|------------------------|---------|
| `server/src/mastra/agents/` | `server/CLAUDE.md` | エージェント一覧（ID, 説明） |
| `server/src/mastra/tools/` | `server/CLAUDE.md` | ツール一覧（変数名, ID, 説明） |
| `server/src/routes/` | `server/CLAUDE.md`, `server/README.md` | API エンドポイント一覧 |
| `server/src/db/schema.ts` | `server/CLAUDE.md` | データベーステーブル定義 |
| `web/src/components/` | `web/CLAUDE.md` | ディレクトリ構成 |
| `web/src/pages/` | `web/CLAUDE.md` | MPA 構成、ディレクトリ構成 |
| `package.json` | ルート `README.md`, `CLAUDE.md` | 開発コマンド |

## 確認方法

### エージェント一覧
```bash
# 実際のエージェントIDを取得
grep -r "id:" server/src/mastra/agents/*.ts | grep -E "^\s+id:"
```

### ツール一覧
```bash
# 実際のツールIDを取得
grep -r "id:" server/src/mastra/tools/*.ts | grep "createTool" -A 2
```

### API エンドポイント
```bash
# ルート定義を確認
grep -r "createRoute" server/src/routes/
```

## 更新時の注意

- モデル名など頻繁に変わる情報は記載しない
- ID や変数名は実際のコードから取得して正確に記載
- 説明文は簡潔に（実装詳細はコードを参照）

## 引数

- 引数なし: `git diff --name-only HEAD` で未コミットの変更を対象
- `--staged`: ステージ済みの変更のみを対象
- `--all`: プロジェクト全体のドキュメントを検証（変更有無に関わらず）
