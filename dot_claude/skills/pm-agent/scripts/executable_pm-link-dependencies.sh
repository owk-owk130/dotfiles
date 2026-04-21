#!/bin/bash
# pm-link-dependencies.sh - Issue 間の依存関係を設定
# Usage: pm-link-dependencies.sh <dependencies.json> [--repo owner/repo] [--dry-run]
#
# Issue body に依存関係マーカーを埋め込む。
# 既存の依存関係セクションがあれば更新し、なければ追加する。
# マーカー形式: <!-- pm-agent:deps --> ... <!-- /pm-agent:deps -->

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/pm-utils.sh"

DEPS_START="<!-- pm-agent:deps -->"
DEPS_END="<!-- /pm-agent:deps -->"

usage() {
  cat <<EOF
使い方: $0 <dependencies.json> [オプション]

オプション:
  --repo <owner/repo>    リポジトリ（デフォルト: 自動検出）
  --dry-run              変更せずにプレビュー
  -h, --help             このヘルプを表示

入力 JSON 形式:
[
  {"issue": 7, "blocked_by": [5, 6]},
  {"issue": 8, "blocks": [9, 10]},
  {"issue": 11, "blocked_by": [7], "blocks": [12]}
]

Issue body への埋め込み:
  <!-- pm-agent:deps -->
  **Dependencies**
  - Blocked by #5, #6
  - Blocks #9
  <!-- /pm-agent:deps -->
EOF
  exit 1
}

DEPS_FILE=""
REPO=""
DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --repo)
      REPO="$2"
      shift 2
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
      DEPS_FILE="$1"
      shift
      ;;
  esac
done

[[ -z "$DEPS_FILE" ]] && {
  echo "エラー: dependencies.json は必須です"
  usage
}
[[ ! -f "$DEPS_FILE" ]] && {
  echo "エラー: ファイルが見つかりません: $DEPS_FILE"
  exit 1
}

REPO="${REPO:-$(get_repo)}"

echo "═══════════════════════════════════════════════"
echo "📋 pm-link-dependencies.sh"
echo "───────────────────────────────────────────────"
echo "  リポジトリ: $REPO"
[[ "$DRY_RUN" == true ]] && echo "  モード: ドライラン"
echo "═══════════════════════════════════════════════"
echo ""

# 依存関係セクションを生成
build_deps_section() {
  local blocked_by="$1" blocks="$2"
  local section=""
  section+="$DEPS_START"$'\n'
  section+="**Dependencies**"$'\n'

  if [[ -n "$blocked_by" && "$blocked_by" != "null" ]]; then
    local refs
    refs=$(echo "$blocked_by" | jq -r '[.[] | "#\(.)"] | join(", ")')
    section+="- Blocked by $refs"$'\n'
  fi
  if [[ -n "$blocks" && "$blocks" != "null" ]]; then
    local refs
    refs=$(echo "$blocks" | jq -r '[.[] | "#\(.)"] | join(", ")')
    section+="- Blocks $refs"$'\n'
  fi

  section+="$DEPS_END"
  echo "$section"
}

# 既存 body の依存関係セクションを置換または追加
update_body_with_deps() {
  local current_body="$1" deps_section="$2"

  if echo "$current_body" | grep -qF "$DEPS_START"; then
    # 既存セクションを置換（sed でマーカー間を差し替え）
    # 一時ファイル経由で安全に処理
    local tmp_body tmp_deps tmp_result
    tmp_body=$(mktemp)
    tmp_deps=$(mktemp)
    tmp_result=$(mktemp)
    printf '%s' "$current_body" > "$tmp_body"
    printf '%s' "$deps_section" > "$tmp_deps"

    awk -v start="$DEPS_START" -v end="$DEPS_END" -v depsfile="$tmp_deps" '
      $0 ~ start { skip=1; while ((getline line < depsfile) > 0) print line; next }
      $0 ~ end { skip=0; next }
      !skip { print }
    ' "$tmp_body" > "$tmp_result"

    cat "$tmp_result"
    rm -f "$tmp_body" "$tmp_deps" "$tmp_result"
  else
    # 新規追加
    if [[ -n "$current_body" ]]; then
      printf '%s\n\n%s' "$current_body" "$deps_section"
    else
      echo "$deps_section"
    fi
  fi
}

success_count=0
fail_count=0

while IFS= read -r entry; do
  issue_num=$(echo "$entry" | jq -r '.issue')
  blocked_by=$(echo "$entry" | jq -c '.blocked_by // empty')
  blocks=$(echo "$entry" | jq -c '.blocks // empty')

  if [[ -z "$issue_num" || "$issue_num" == "null" ]]; then
    print_warn "issue 番号が未指定のエントリをスキップ"
    continue
  fi

  if [[ -z "$blocked_by" && -z "$blocks" ]]; then
    print_skip "#$issue_num: 依存関係の指定なし"
    continue
  fi

  if [[ "$DRY_RUN" == true ]]; then
    echo "📝 #$issue_num:"
    [[ -n "$blocked_by" ]] && echo "  Blocked by: $(echo "$blocked_by" | jq -r '[.[] | "#\(.)"] | join(", ")')"
    [[ -n "$blocks" ]] && echo "  Blocks: $(echo "$blocks" | jq -r '[.[] | "#\(.)"] | join(", ")')"
    echo ""
    continue
  fi

  # 現在の body を取得
  current_body=$(gh api "repos/$REPO/issues/$issue_num" --jq '.body // ""' 2>/dev/null) || {
    print_warn "#$issue_num の取得に失敗"
    ((fail_count++)) || true
    continue
  }

  deps_section=$(build_deps_section "$blocked_by" "$blocks")
  new_body=$(update_body_with_deps "$current_body" "$deps_section")

  if gh api "repos/$REPO/issues/$issue_num" \
    -X PATCH \
    -f body="$new_body" \
    --silent 2>/dev/null; then
    print_success "#$issue_num に依存関係を設定"
    ((success_count++)) || true
  else
    print_warn "#$issue_num の更新に失敗"
    ((fail_count++)) || true
  fi
done < <(jq -c '.[]' "$DEPS_FILE")

echo ""
echo "═══════════════════════════════════════════════"
echo "📊 結果サマリー"
echo "───────────────────────────────────────────────"
if [[ "$DRY_RUN" == true ]]; then
  echo "  モード: ドライラン（変更は行われていません）"
else
  echo "  成功: $success_count 件"
  [[ $fail_count -gt 0 ]] && echo "  失敗: $fail_count 件"
fi
echo "═══════════════════════════════════════════════"

[[ $fail_count -gt 0 ]] && exit 1
exit 0
