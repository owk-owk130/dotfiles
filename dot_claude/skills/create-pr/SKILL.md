---
name: create-pr
description: "現在のブランチからプルリクエストを作成する。ベースブランチを最新化してから変更内容を確認し、PRを作成する。"
---

# Create Pull Request

現在のブランチからプルリクエストを作成する。

## 手順

### 1. ベースブランチを最新化

```bash
git fetch origin develop
git rebase origin/develop
```

※ コンフリクトがあれば解決してから続行

### 2. 変更内容の確認

```bash
git status
git log origin/develop..HEAD --oneline
git diff origin/develop...HEAD
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
gh pr create --base develop
```

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
- ベースブランチはプロジェクトに応じて変更（develop / main）
- PR 説明文に「Generated with Claude Code」は入れない
