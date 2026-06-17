---
name: ask-codex
description: Asks Codex CLI for coding assistance. Use for getting a second opinion, code generation, debugging, or delegating coding tasks.
allowed-tools: Bash(codex *)
---

# Ask Codex

Executes the local `codex` CLI to get coding assistance.

**Note:** This skill requires the `codex` CLI to be installed and available in your system's PATH.

> **レビューは公式 codex プラグインを優先**：コミット前レビューは `/codex:review`（stop 時の review-gate で自動）／`/codex:adversarial-review`（ルール観点は `~/.claude/codex-review-ruleset.md` を focus に渡す）を使う。`ask-codex` は主に **`codex exec`（設計相談・タスク委譲）** 用途で使う。

## Args routing

スキル呼び出し時の args に応じてサブコマンドを選択する：

| Args | Action |
|------|--------|
| `review` | `codex review --uncommitted` を実行 |
| `review --base main` | `codex review --base main` を実行 |
| `review --commit SHA` | `codex review --commit SHA` を実行 |
| テキスト（上記以外） | `codex exec "テキスト"` を実行 |
| なし | CLAUDE.md の相談ルールに基づき自律判断 |

## Subcommands

### `codex exec` — 質問・相談

```bash
codex exec "Your question or task here"
```

### `codex review` — コードレビュー

```bash
codex review --uncommitted "レビュー観点や補足"
```

| Option | Description |
|--------|-------------|
| `--uncommitted` | ステージ済み・未ステージ・未追跡の変更をレビュー |
| `--base BRANCH` | 指定ブランチとの差分をレビュー |
| `--commit SHA` | 特定コミットの変更をレビュー |

## Common options (shared)

| Option | Description |
|--------|-------------|
| `-m MODEL` | モデル指定（省略時は config.toml のデフォルト） |
| `-C DIR` | 作業ディレクトリ指定 |

## Examples

**プランニング時に設計方針を相談:**

```bash
codex exec -C /path/to/project "この機能を実装するにあたり、以下の設計方針についてレビューしてほしい: ..."
```

**実装後にコード変更をレビュー:**

```bash
codex review --uncommitted
```

**ブランチ差分のレビュー:**

```bash
codex review --base main
```

**特定コミットのレビュー:**

```bash
codex review --commit abc1234
```

**コーディングの質問:**

```bash
codex exec "How do I implement a binary search in Python?"
```

**自動実行モード:**

```bash
codex exec --full-auto "Add error handling to all API endpoints"
```
