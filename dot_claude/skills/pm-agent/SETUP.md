# 運用リファレンス

このファイルはデフォルト設定、スクリプト詳細、レアケース操作（Iteration 継承/分散配置、チェックポイント）、トラブルシューティングを扱う補助ドキュメント。

## デフォルト設定

### GitHub Settings

| 設定 | デフォルト値 | 説明 |
|------|-------------|------|
| owner | `@me` | 個人の場合は `@me`、組織の場合は組織名 |
| project_number | `1` | `gh project list` で確認 |

### 粒度ルール

| ルール | 値 | 説明 |
|--------|-----|------|
| 実装タスク最大時間 | **3時間** | 超えたら分割提案 |
| 警告閾値 | 2時間 | 警告表示 |

### レート制限

| 設定 | 値 | 説明 |
|------|-----|------|
| バッチサイズ | 20件 | 一度に処理する最大Issue数 |
| 遅延 | 1000ms | バッチ間の待機時間 |
| リトライ | 3回 | 最大リトライ回数 |

## 前提条件

```bash
# 認証状態確認
gh auth status

# project スコープが必要な場合
gh auth refresh -s project
```

必要なスコープ: `repo`（Issue 作成・編集）、`project`（Projects 操作）

## 初回 Project セットアップ

pm-agent は Projects V2 に以下のフィールドが揃っている前提で動作する。初回利用時に Project オーナー権限で設定する（organization admin 権限は不要）。

### 必須フィールド

| フィールド | 型 | オプション値 | GitHub template 対応 |
|-----------|-----|-----------|---------------------|
| `Status` | SINGLE_SELECT | Todo / In Progress / Done | デフォルト存在 |
| `Priority` | SINGLE_SELECT | **High / Medium / Low** | template は `P0 / P1 / P2`。要リネーム |
| `Estimate` | NUMBER | - | Team planning template に存在 |
| `Iteration` | ITERATION | - | Team planning template に存在 |
| `Ticket Type` | SINGLE_SELECT | Epic / Feature / Story / Task / Bug | **手動作成必須**（GitHub built-in `Type` は organization admin 権限が必要なため不採用） |

### セットアップ手順

1. GitHub Projects V2 を Team planning または Feature release テンプレートで作成
2. `Priority` のオプション値を `P0/P1/P2` → `High/Medium/Low` にリネーム
3. `Ticket Type` を手動追加（SINGLE_SELECT、オプション: Epic / Feature / Story / Task / Bug）
4. 検証: `scripts/pm-project-fields.sh --list-fields --project N --owner login`

各フィールド作成の GraphQL は `GRAPHQL.md` 参照。

## スクリプト一覧

| スクリプト | 用途 | 必須 |
|-----------|------|------|
| `pm-utils.sh` | 共通ユーティリティ | - |
| `pm-security.sh` | セキュリティユーティリティ | - |
| `pm-setup-labels.sh` | ラベル作成 | - |
| `pm-bulk-issues.sh` | Issue 一括作成（`--dry-run` で重複検出、`source_ref` で議事録紐付け） | ✅ |
| `pm-bulk-update.sh` | 既存 Issue 一括編集（タイトル / 本文 / ラベル / ステート） | - |
| `pm-bulk-status.sh` | 子 Issue 一括ステータス変更 | - |
| `pm-link-hierarchy.sh` | Sub-issue 関係設定 | ✅ |
| `pm-link-dependencies.sh` | Issue 間の依存関係設定（body 埋め込み） | - |
| `pm-project-fields.sh` | Projects V2 フィールド設定（`--bulk` 対応） | - |
| `pm-sprint-report.sh` | スプリントレポート生成 | - |
| `pm-cascade-iteration.sh` | 親→子への Iteration 自動継承（`--recursive` 対応） | - |
| `pm-distribute-iterations.sh` | 子 Issue を複数 Iteration に分散配置 | - |

## レアケース操作例

### Iteration 継承（親→子）

親 Issue の Iteration を子 Issue に自動継承:

```bash
# 直接の子のみ
scripts/pm-cascade-iteration.sh 10 \
  --project 1 --owner @me

# 全子孫に再帰的に適用（Epic → Feature → Story → Task）
scripts/pm-cascade-iteration.sh 10 \
  --project 1 --owner @me --recursive
```

オプション: `--recursive`（全子孫）、`--max-depth <N>`（最大深度、デフォルト: 10）、`--dry-run`

### Iteration 分散配置

子 Issue（Features 等）を複数の Iteration に分散配置:

```bash
# 子 Issue 一覧を確認
scripts/pm-distribute-iterations.sh 10 \
  --project 1 --owner @me --list

# 3 つのスプリントに分散配置
scripts/pm-distribute-iterations.sh 10 \
  --project 1 --owner @me \
  --iterations "Sprint 1,Sprint 2,Sprint 3"

# カスタム順序で配置 + 子孫にも cascade
scripts/pm-distribute-iterations.sh 10 \
  --project 1 --owner @me \
  --iterations "Sprint 1,Sprint 2,Sprint 3" \
  --order "15,12,18,14,16,13" \
  --cascade
```

オプション: `--iterations <list>`（必須）、`--order <numbers>`、`--cascade`、`--list`、`--dry-run`

### チェックポイント機能

`pm-bulk-issues.sh` はチェックポイント機能を持ち、途中失敗時に再開可能:

```bash
# デフォルトのチェックポイントファイル
/tmp/claude/pm-checkpoint.json

# カスタムチェックポイント
scripts/pm-bulk-issues.sh issues.json \
  --checkpoint /tmp/claude/my-checkpoint.json
```

チェックポイントファイル形式:

```json
{
  "created": [
    {"number": "1", "title": "タスク1"},
    {"number": "2", "title": "タスク2"}
  ]
}
```

## トラブルシューティング

| エラー | 原因 | 解決方法 |
|--------|------|----------|
| HTTP 401: Bad credentials | 認証切れ | `gh auth refresh -s project` |
| Resource not accessible | スコープ不足 | `gh auth refresh -s repo,project` |
| API rate limit exceeded | レート制限 | 待機後リトライ、バッチサイズ削減 |
| Field already exists | フィールド重複 | 既存フィールドを確認して使用 |

## 確認コマンド

```bash
# プロジェクト詳細確認
gh project view PROJECT_NUMBER --owner @me

# フィールド一覧
scripts/pm-project-fields.sh \
  --project 1 --owner @me --list-fields
```
