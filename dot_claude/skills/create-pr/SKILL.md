---
name: create-pr
description: "現在のブランチからプルリクエストを作成する。ベースブランチを最新化してから変更内容を確認し、PRを作成する。"
---

# Create Pull Request

現在のブランチからプルリクエストを作成する。

## 手順

### 0. ベースブランチの特定

```bash
# リモートのデフォルトブランチ（HEAD が指すブランチ）を取得
BASE_BRANCH=$(git remote show origin | grep 'HEAD branch' | awk '{print $NF}')
```

### 1. ベースブランチを最新化

```bash
git fetch origin "$BASE_BRANCH"
git rebase "origin/$BASE_BRANCH"
```

※ コンフリクトがあれば解決してから続行

### 2. 変更内容の確認

```bash
git status
git log "origin/$BASE_BRANCH..HEAD" --oneline
git diff "origin/$BASE_BRANCH...HEAD"
```

### 3. ドキュメントの更新

**`/update-docs` を実行してドキュメントを最新化する。**

変更があればコミットしてプッシュ。

### 4. プッシュ

```bash
git push
# rebase した場合は --force-with-lease を使用
git push --force-with-lease
```

### 5. PR作成

```bash
gh pr create --base "$BASE_BRANCH"
```

### 6. Copilot レビューの待機と適用

Rulesets で自動追加されていないリポジトリでも Copilot レビューを発火できるよう、明示的にレビュアーに追加する。

```bash
PR_NUMBER=$(gh pr view --json number -q .number)
gh pr edit "$PR_NUMBER" --add-reviewer Copilot 2>/dev/null || echo "Copilot を追加できませんでした（未サポートのリポジトリの可能性）"
```

失敗しても無視して続行する（後続の skill 側で未サポートを検知して即終了する）。

```
/loop /copilot-review-apply
```

interval なしの dynamic mode で起動すると、`copilot-review-apply` skill が最大 5 分までポーリングし、レビューが届いた時点で処理に入る。Copilot レビューが発火しないリポジトリでは skill 側で検知して待機せず終了する。

## PR テンプレート

```markdown
## Summary
- <変更内容の要約を箇条書きで記述>

## 主な変更内容
<技術的な詳細を記述>

## Test plan
- [ ] <テスト項目1>
- [ ] <テスト項目2>
```

## 注意事項

- タイトルは変更内容を簡潔に表現する（70文字以内）
- ベースブランチはリモートのデフォルトブランチ（HEAD が指すブランチ）を自動検出する
- PR 説明文に「Generated with Claude Code」は入れない
