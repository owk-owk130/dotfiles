# GraphQL API リファレンス

Projects V2 のセットアップ時に使用するフィールド作成・ビュー作成の GraphQL。
クエリ/更新操作はスクリプト（pm-utils.sh, pm-project-fields.sh）に実装済み。

## フィールド名の正

**重要**: `pm-project-fields.sh` が検索するフィールド名と一致させること（ハードコード）:

| フィールド名 | データ型 | 用途 |
|-------------|---------|------|
| `Status` | SINGLE_SELECT | Kanban Status (Todo / In Progress / In Review / Done) |
| `Priority` | SINGLE_SELECT | 優先度 (High / Medium / Low) |
| `Ticket Type` | SINGLE_SELECT | 4 層チケット分類 (Epic / Feature / Story / Task / Bug) |
| `Estimate` | NUMBER | 見積もり時間 |
| `Iteration` | ITERATION | スプリント |

## 認証

```bash
gh api graphql -f query='YOUR_QUERY'
```

## フィールド作成

### Status（Single Select）

GitHub Projects V2 はデフォルトで `Status` フィールドを持つため、通常は追加作成不要。既存オプション: `Todo` / `In Progress` / `Done`。`In Review` を追加したい場合は `updateProjectV2Field` で拡張する。

### Priority（Single Select）

```graphql
mutation CreatePriorityField($projectId: ID!) {
  createProjectV2Field(input: {
    projectId: $projectId
    dataType: SINGLE_SELECT
    name: "Priority"
    singleSelectOptions: [
      {name: "High", color: RED, description: "最優先"}
      {name: "Medium", color: YELLOW, description: "通常"}
      {name: "Low", color: GRAY, description: "後回し可"}
    ]
  }) {
    projectV2Field {
      ... on ProjectV2SingleSelectField {
        id
        name
        options { id name }
      }
    }
  }
}
```

### Ticket Type（Single Select）

```graphql
mutation CreateTicketTypeField($projectId: ID!) {
  createProjectV2Field(input: {
    projectId: $projectId
    dataType: SINGLE_SELECT
    name: "Ticket Type"
    singleSelectOptions: [
      {name: "Epic", color: PURPLE, description: "マイルストーン・日付確定のゴール"}
      {name: "Feature", color: BLUE, description: "1-3 スプリントで完了する機能要件"}
      {name: "Story", color: GREEN, description: "1 スプリント以内で完了するユーザー価値"}
      {name: "Task", color: GRAY, description: "一度の作業で完了する実装タスク"}
      {name: "Bug", color: RED, description: "不具合修正"}
    ]
  }) {
    projectV2Field {
      ... on ProjectV2SingleSelectField {
        id
        name
        options { id name }
      }
    }
  }
}
```

### Estimate（Number）

```graphql
mutation CreateEstimateField($projectId: ID!) {
  createProjectV2Field(input: {
    projectId: $projectId
    dataType: NUMBER
    name: "Estimate"
  }) {
    projectV2Field {
      ... on ProjectV2Field { id name }
    }
  }
}
```

### Iteration

```graphql
mutation CreateIterationField($projectId: ID!) {
  createProjectV2Field(input: {
    projectId: $projectId
    dataType: ITERATION
    name: "Iteration"
  }) {
    projectV2Field {
      ... on ProjectV2IterationField {
        id
        name
        configuration { duration startDay }
      }
    }
  }
}
```

## フィールド作成順

1. `Priority` / `Ticket Type`（SINGLE_SELECT）
2. `Estimate`（NUMBER）
3. `Iteration`（ITERATION）
4. `Status` は既定で存在するため、必要なら `In Review` オプションを追加

作成後、`pm-project-fields.sh --list-fields` で全フィールドが揃っているか検証。

## ビュー作成

```graphql
mutation CreateView($projectId: ID!, $name: String!, $layout: ProjectV2ViewLayout!) {
  createProjectV2View(input: {
    projectId: $projectId
    name: $name
    layout: $layout
  }) {
    projectV2View { id name layout }
  }
}
```

レイアウト: `TABLE_LAYOUT` / `BOARD_LAYOUT` / `ROADMAP_LAYOUT`

## エラーハンドリング

| エラータイプ | 対処 |
|-------------|------|
| `NOT_FOUND` | プロジェクト ID 確認、権限確認 |
| `RATE_LIMITED` | 待機後リトライ、バッチサイズ削減 |
| `UNPROCESSABLE` (Field already exists) | 既存フィールドを使用（名前衝突確認） |
