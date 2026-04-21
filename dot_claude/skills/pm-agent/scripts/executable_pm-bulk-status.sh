#!/bin/bash
# pm-bulk-status.sh - 子 Issue の一括ステータス変更
# Usage: pm-bulk-status.sh --parent N --status "Done" --project N --owner login
#
# 親 Issue 配下の子 Issue、または特定 Iteration の全 Issue の
# Kanban Status を一括変更する。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/pm-utils.sh"

usage() {
  cat <<EOF
使い方: $0 --status <value> --project <N> --owner <login> [オプション]

対象の指定（いずれか必須）:
  --parent <issue_number>  親 Issue 配下の子 Issue を対象
  --iteration <name>       指定 Iteration の全 Issue を対象
  --issues <numbers>       Issue 番号をカンマ区切りで直接指定

オプション:
  --repo <owner/repo>      リポジトリ（デフォルト: 自動検出）
  --status <value>         設定する Status 値（必須。例: Todo, In Progress, Done）
  --project <number>       プロジェクト番号（必須）
  --owner <login>          プロジェクトオーナー（必須。@me または組織名）
  --recursive              親 Issue の全子孫に適用（--parent 時のみ）
  --close                  Status を Done にした場合、Issue も Close する
  --dry-run                実行せずにプレビュー
  -h, --help               このヘルプを表示

使用例:
  # 親 Issue 配下の子を Done に
  $0 --parent 10 --status Done --project 1 --owner @me

  # 全子孫に再帰的に適用
  $0 --parent 10 --status Done --project 1 --owner @me --recursive

  # 特定 Iteration の全 Issue を Done に + Close
  $0 --iteration "Sprint 1" --status Done --project 1 --owner @me --close

  # Issue 番号を直接指定
  $0 --issues 7,8,9 --status "In Progress" --project 1 --owner @me
EOF
  exit 1
}

# デフォルト値
PARENT_ISSUE=""
TARGET_ITERATION=""
ISSUE_LIST=""
REPO=""
STATUS_VALUE=""
PROJECT_NUMBER=""
PROJECT_OWNER=""
RECURSIVE=false
CLOSE_ISSUES=false
DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --parent)
      PARENT_ISSUE="$2"
      shift 2
      ;;
    --iteration)
      TARGET_ITERATION="$2"
      shift 2
      ;;
    --issues)
      ISSUE_LIST="$2"
      shift 2
      ;;
    --repo)
      REPO="$2"
      shift 2
      ;;
    --status)
      STATUS_VALUE="$2"
      shift 2
      ;;
    --project)
      PROJECT_NUMBER="$2"
      shift 2
      ;;
    --owner)
      PROJECT_OWNER="$2"
      shift 2
      ;;
    --recursive)
      RECURSIVE=true
      shift
      ;;
    --close)
      CLOSE_ISSUES=true
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    -h | --help) usage ;;
    -*)
      echo "不明なオプション: $1"
      usage
      ;;
    *)
      shift
      ;;
  esac
done

# 必須引数の検証
[[ -z "$STATUS_VALUE" ]] && {
  echo "エラー: --status は必須です"
  usage
}
[[ -z "$PROJECT_NUMBER" ]] && {
  echo "エラー: --project は必須です"
  usage
}
[[ -z "$PROJECT_OWNER" ]] && {
  echo "エラー: --owner は必須です"
  usage
}
[[ -z "$PARENT_ISSUE" && -z "$TARGET_ITERATION" && -z "$ISSUE_LIST" ]] && {
  echo "エラー: --parent, --iteration, --issues のいずれかが必須です"
  usage
}

REPO="${REPO:-$(get_repo)}"

echo "═══════════════════════════════════════════════"
echo "📋 pm-bulk-status.sh"
echo "───────────────────────────────────────────────"
echo "  リポジトリ: $REPO"
echo "  プロジェクト: #$PROJECT_NUMBER"
echo "  Status: → $STATUS_VALUE"
[[ -n "$PARENT_ISSUE" ]] && echo "  対象: #$PARENT_ISSUE の子 Issue"
[[ -n "$TARGET_ITERATION" ]] && echo "  対象: Iteration \"$TARGET_ITERATION\""
[[ -n "$ISSUE_LIST" ]] && echo "  対象: Issue $ISSUE_LIST"
[[ "$RECURSIVE" == true ]] && echo "  モード: 再帰"
[[ "$CLOSE_ISSUES" == true ]] && echo "  Close: 有効"
[[ "$DRY_RUN" == true ]] && echo "  モード: ドライラン"
echo "═══════════════════════════════════════════════"
echo ""

# プロジェクト情報取得
echo "プロジェクト情報を取得中..."
PROJECT_ID=$(get_project_id "$PROJECT_OWNER" "$PROJECT_NUMBER")

if [[ -z "$PROJECT_ID" || "$PROJECT_ID" == "null" ]]; then
  echo "エラー: プロジェクト #$PROJECT_NUMBER が見つかりません" >&2
  exit 1
fi

FIELDS_JSON=$(get_project_fields "$PROJECT_ID")

# Status フィールドと選択肢を取得
STATUS_FIELD_ID=$(echo "$FIELDS_JSON" | jq -r '.[] | select(.name == "Status") | .id' | head -1)
STATUS_OPTION_ID=$(echo "$FIELDS_JSON" | jq -r --arg s "$STATUS_VALUE" '.[] | select(.name == "Status") | .options[]? | select(.name == $s) | .id' | head -1)

if [[ -z "$STATUS_FIELD_ID" ]]; then
  echo "エラー: Status フィールドが見つかりません" >&2
  exit 1
fi
if [[ -z "$STATUS_OPTION_ID" ]]; then
  echo "エラー: Status の選択肢 '$STATUS_VALUE' が見つかりません" >&2
  echo "利用可能な選択肢:"
  echo "$FIELDS_JSON" | jq -r '.[] | select(.name == "Status") | .options[]? | "  - \(.name)"'
  exit 1
fi

# 対象 Issue 一覧を取得
target_issues="[]"

if [[ -n "$PARENT_ISSUE" ]]; then
  if [[ "$RECURSIVE" == true ]]; then
    echo "全子孫を取得中..."
    target_issues=$(get_all_descendants "$REPO" "$PARENT_ISSUE")
  else
    echo "子 Issue を取得中..."
    target_issues=$(get_child_issues "$REPO" "$PARENT_ISSUE")
  fi
elif [[ -n "$ISSUE_LIST" ]]; then
  # カンマ区切りの Issue 番号を JSON 配列に変換
  target_issues=$(echo "$ISSUE_LIST" | tr ',' '\n' | jq -R '{number: (. | tonumber), title: ""}' | jq -s '.')
elif [[ -n "$TARGET_ITERATION" ]]; then
  # Iteration のアイテムを GraphQL で取得
  echo "Iteration \"$TARGET_ITERATION\" の Issue を取得中..."
  # pm-sprint-report.sh と同じ方法で全アイテムを取得し、Iteration でフィルタ
  all_items_query="query(\$projectId: ID!) {
    node(id: \$projectId) {
      ... on ProjectV2 {
        items(first: 100) {
          nodes {
            content {
              ... on Issue { number title }
            }
            fieldValues(first: 20) {
              nodes {
                ... on ProjectV2ItemFieldIterationValue {
                  title
                }
              }
            }
          }
        }
      }
    }
  }"
  target_issues=$(gh api graphql -f projectId="$PROJECT_ID" -f query="$all_items_query" | \
    jq --arg it "$TARGET_ITERATION" '[
      .data.node.items.nodes[] |
      select(.content != null) |
      select([.fieldValues.nodes[] | .title? // empty] | any(. == $it)) |
      {number: .content.number, title: .content.title}
    ]')
fi

TOTAL=$(echo "$target_issues" | jq 'length')

if [[ "$TOTAL" -eq 0 ]]; then
  print_warn "対象の Issue が見つかりません"
  exit 0
fi

echo "  対象: $TOTAL 件"
echo ""

# 注: update_single_select_field は pm-utils.sh に定義済み

updated_count=0
fail_count=0

while IFS= read -r item; do
  [[ -z "$item" ]] && continue
  issue_num=$(echo "$item" | jq -r '.number')
  issue_title=$(echo "$item" | jq -r '.title')

  if [[ "$DRY_RUN" == true ]]; then
    echo "  更新予定 #$issue_num: $issue_title → $STATUS_VALUE"
    [[ "$CLOSE_ISSUES" == true && "$STATUS_VALUE" == "Done" ]] && echo "    + Close"
    continue
  fi

  # プロジェクトに追加済みか確認し、item_id を取得
  item_id=$(ensure_project_item "$REPO" "$issue_num" "$PROJECT_ID" "$PROJECT_NUMBER") || {
    print_warn "#$issue_num のプロジェクトへの追加に失敗"
    ((fail_count++)) || true
    continue
  }

  # Status 更新
  if update_single_select_field "$PROJECT_ID" "$item_id" "$STATUS_FIELD_ID" "$STATUS_OPTION_ID" >/dev/null 2>&1; then
    print_success "#$issue_num → $STATUS_VALUE"
    ((updated_count++)) || true

    # Close オプション
    if [[ "$CLOSE_ISSUES" == true && "$STATUS_VALUE" == "Done" ]]; then
      if gh issue close "$issue_num" --repo "$REPO" >/dev/null 2>&1; then
        echo "   ↳ Closed"
      else
        print_warn "#$issue_num の Close に失敗"
      fi
    fi
  else
    print_warn "#$issue_num の Status 更新に失敗"
    ((fail_count++)) || true
  fi
done < <(echo "$target_issues" | jq -c '.[]')

echo ""
echo "═══════════════════════════════════════════════"
echo "📊 結果サマリー"
echo "───────────────────────────────────────────────"
if [[ "$DRY_RUN" == true ]]; then
  echo "  モード: ドライラン（変更は行われていません）"
  echo "  対象: $TOTAL 件"
else
  echo "  更新: $updated_count 件"
  [[ $fail_count -gt 0 ]] && echo "  失敗: $fail_count 件"
fi
echo "═══════════════════════════════════════════════"

[[ $fail_count -gt 0 ]] && exit 1
exit 0
