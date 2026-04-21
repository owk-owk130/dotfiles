#!/bin/bash
# pm-sprint-report.sh - スプリントレポート生成
# Usage: pm-sprint-report.sh [--iteration "Sprint 1"] --project N --owner login
#
# Iteration 別の進捗サマリーを表示する。
# Projects V2 の GraphQL API で全アイテムを取得し、Iteration + Status で集計。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/pm-utils.sh"

usage() {
  cat <<EOF
使い方: $0 [オプション]

オプション:
  --project <number>       プロジェクト番号（必須）
  --owner <login>          プロジェクトオーナー（必須。@me または組織名）
  --iteration <name>       特定 Iteration のレポートのみ表示（Issue 一覧付き）
  --all                    未設定の Iteration も含めて表示
  -h, --help               このヘルプを表示

使用例:
  $0 --project 1 --owner @me
  $0 --project 1 --owner @me --iteration "Sprint 1"
EOF
  exit 1
}

# デフォルト値
PROJECT_NUMBER=""
PROJECT_OWNER=""
TARGET_ITERATION=""
SHOW_ALL=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --project)
      PROJECT_NUMBER="$2"
      shift 2
      ;;
    --owner)
      PROJECT_OWNER="$2"
      shift 2
      ;;
    --iteration)
      TARGET_ITERATION="$2"
      shift 2
      ;;
    --all)
      SHOW_ALL=true
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

[[ -z "$PROJECT_NUMBER" ]] && {
  echo "エラー: --project は必須です"
  usage
}
[[ -z "$PROJECT_OWNER" ]] && {
  echo "エラー: --owner は必須です"
  usage
}

echo "プロジェクト情報を取得中..."
PROJECT_ID=$(get_project_id "$PROJECT_OWNER" "$PROJECT_NUMBER")

if [[ -z "$PROJECT_ID" || "$PROJECT_ID" == "null" ]]; then
  echo "エラー: プロジェクト #$PROJECT_NUMBER が見つかりません" >&2
  exit 1
fi

# 全アイテムをページネーション付きで取得
fetch_project_items() {
  local project_id="$1"
  local all_items="[]"
  local cursor=""

  while true; do
    local after_clause=""
    [[ -n "$cursor" ]] && after_clause=", after: \"$cursor\""

    local query="query(\$projectId: ID!) {
      node(id: \$projectId) {
        ... on ProjectV2 {
          items(first: 100${after_clause}) {
            pageInfo { hasNextPage endCursor }
            nodes {
              content {
                ... on Issue {
                  number
                  title
                  state
                }
              }
              fieldValues(first: 20) {
                nodes {
                  ... on ProjectV2ItemFieldSingleSelectValue {
                    name
                    field { ... on ProjectV2SingleSelectField { name } }
                  }
                  ... on ProjectV2ItemFieldNumberValue {
                    number
                    field { ... on ProjectV2Field { name } }
                  }
                  ... on ProjectV2ItemFieldIterationValue {
                    title
                    field { ... on ProjectV2IterationField { name } }
                  }
                }
              }
            }
          }
        }
      }
    }"

    local result
    result=$(gh api graphql -f projectId="$project_id" -f query="$query")

    local page_items
    page_items=$(echo "$result" | jq '[
      .data.node.items.nodes[] |
      select(.content != null) |
      {
        number: .content.number,
        title: .content.title,
        issue_state: .content.state,
        status: ([.fieldValues.nodes[] | select(.field.name == "Status") | .name][0] // "なし"),
        iteration: ([.fieldValues.nodes[] | select(.field.name? // "" | test("Iteration|Sprint"; "i")) | .title][0] // "未設定"),
        estimate: ([.fieldValues.nodes[] | select(.field.name == "Estimate") | .number][0] // 0)
      }
    ]')

    all_items=$(echo "[$all_items, $page_items]" | jq -s 'add | add')

    local has_next
    has_next=$(echo "$result" | jq -r '.data.node.items.pageInfo.hasNextPage')
    [[ "$has_next" != "true" ]] && break
    cursor=$(echo "$result" | jq -r '.data.node.items.pageInfo.endCursor')
  done

  echo "$all_items"
}

ITEMS_JSON=$(fetch_project_items "$PROJECT_ID")
TOTAL_ITEMS=$(echo "$ITEMS_JSON" | jq 'length')

echo ""
echo "═══════════════════════════════════════════════"
echo "📊 スプリントレポート"
echo "───────────────────────────────────────────────"
echo "  プロジェクト: #$PROJECT_NUMBER"
echo "  合計アイテム: $TOTAL_ITEMS 件"
echo "═══════════════════════════════════════════════"

ITERATIONS=$(echo "$ITEMS_JSON" | jq -r '[.[].iteration] | unique | .[]')

if [[ -n "$TARGET_ITERATION" ]]; then
  ITERATIONS="$TARGET_ITERATION"
fi

while IFS= read -r iteration; do
  [[ -z "$iteration" ]] && continue

  if [[ "$iteration" == "未設定" && "$SHOW_ALL" != true && -z "$TARGET_ITERATION" ]]; then
    continue
  fi

  iter_items=$(echo "$ITEMS_JSON" | jq --arg it "$iteration" '[.[] | select(.iteration == $it)]')
  iter_count=$(echo "$iter_items" | jq 'length')
  [[ "$iter_count" -eq 0 ]] && continue

  todo=$(echo "$iter_items" | jq '[.[] | select(.status == "Todo")] | length')
  in_progress=$(echo "$iter_items" | jq '[.[] | select(.status == "In Progress")] | length')
  in_review=$(echo "$iter_items" | jq '[.[] | select(.status == "In Review")] | length')
  done_count=$(echo "$iter_items" | jq '[.[] | select(.status == "Done")] | length')
  no_status=$(echo "$iter_items" | jq --arg s "なし" '[.[] | select(.status == $s)] | length')

  total_estimate=$(echo "$iter_items" | jq '[.[].estimate] | add // 0')
  done_estimate=$(echo "$iter_items" | jq '[.[] | select(.status == "Done") | .estimate] | add // 0')

  if [[ "$iter_count" -gt 0 ]]; then
    progress_pct=$((done_count * 100 / iter_count))
  else
    progress_pct=0
  fi

  # プログレスバー（20文字幅）
  filled=$((progress_pct / 5))
  empty=$((20 - filled))
  bar=""
  for ((b=0; b<filled; b++)); do bar+="█"; done
  for ((b=0; b<empty; b++)); do bar+="░"; done

  echo ""
  echo "┌─────────────────────────────────────────────"
  echo "│ 📅 $iteration"
  echo "├─────────────────────────────────────────────"
  echo "│ 進捗: [$bar] ${progress_pct}% ($done_count/$iter_count)"
  echo "│"
  echo "│ ステータス別:"
  [[ $todo -gt 0 ]] && echo "│   📋 Todo:        $todo 件"
  [[ $in_progress -gt 0 ]] && echo "│   🔄 In Progress: $in_progress 件"
  [[ $in_review -gt 0 ]] && echo "│   👀 In Review:   $in_review 件"
  [[ $done_count -gt 0 ]] && echo "│   ✅ Done:        $done_count 件"
  [[ $no_status -gt 0 ]] && echo "│   ❓ 未設定:      $no_status 件"
  echo "│"
  echo "│ 見積もり: $done_estimate / $total_estimate h"
  echo "└─────────────────────────────────────────────"

  # 特定 Iteration の場合は Issue 一覧も表示
  if [[ -n "$TARGET_ITERATION" ]]; then
    echo ""
    echo "  Issue 一覧:"
    echo "$iter_items" | jq -r '.[] | "  \(if .status == "Done" then "  ✅" elif .status == "In Progress" then "  🔄" else "  📋" end) #\(.number): \(.title) (\(.estimate)h)"'
  fi
done <<< "$ITERATIONS"

echo ""
echo "═══════════════════════════════════════════════"
echo "📈 全体サマリー"
echo "───────────────────────────────────────────────"
total_done=$(echo "$ITEMS_JSON" | jq '[.[] | select(.status == "Done")] | length')
total_estimate_all=$(echo "$ITEMS_JSON" | jq '[.[].estimate] | add // 0')
total_done_estimate=$(echo "$ITEMS_JSON" | jq '[.[] | select(.status == "Done") | .estimate] | add // 0')
echo "  全体進捗: $total_done / $TOTAL_ITEMS 件完了"
echo "  見積もり: $total_done_estimate / $total_estimate_all h"
echo "═══════════════════════════════════════════════"
