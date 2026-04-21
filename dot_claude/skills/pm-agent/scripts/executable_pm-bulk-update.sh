#!/bin/bash
# pm-bulk-update.sh - 既存 Issue の一括編集
# Usage: pm-bulk-update.sh <updates.json> [--repo owner/repo] [--dry-run]
#
# JSON ファイルから既存 Issue のタイトル・本文・ラベル・ステートを一括変更する。
# gh issue edit / gh issue close / gh issue reopen コマンドベース。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/pm-utils.sh"

usage() {
  cat <<EOF
使い方: $0 <updates.json> [オプション]

オプション:
  --repo <owner/repo>    リポジトリ（デフォルト: 自動検出）
  --dry-run              変更せずに差分をプレビュー
  --batch-size <N>       バッチあたりの件数（デフォルト: 20）
  --delay <sec>          バッチ間の待機秒数（デフォルト: 1）
  -h, --help             このヘルプを表示

入力 JSON 形式:
[
  {
    "issue": 123,
    "title": "新しいタイトル",
    "body": "新しい本文",
    "state": "closed",
    "add_labels": ["bug", "urgent"],
    "remove_labels": ["wontfix"],
    "milestone": 2
  }
]

フィールドはすべて省略可能。指定されたフィールドのみ変更される。
EOF
  exit 1
}

# デフォルト値
UPDATES_FILE=""
REPO=""
DRY_RUN=false
BATCH_SIZE=20
DELAY_SEC=1

# 引数の解析
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
    --batch-size)
      BATCH_SIZE="$2"
      shift 2
      ;;
    --delay)
      DELAY_SEC="$2"
      shift 2
      ;;
    -h | --help) usage ;;
    -*)
      echo "不明なオプション: $1"
      usage
      ;;
    *)
      UPDATES_FILE="$1"
      shift
      ;;
  esac
done

[[ -z "$UPDATES_FILE" ]] && {
  echo "エラー: updates.json は必須です"
  usage
}
[[ ! -f "$UPDATES_FILE" ]] && {
  echo "エラー: ファイルが見つかりません: $UPDATES_FILE"
  exit 1
}

REPO="${REPO:-$(get_repo)}"

echo "═══════════════════════════════════════════════"
echo "📋 pm-bulk-update.sh"
echo "───────────────────────────────────────────────"
echo "  リポジトリ: $REPO"
[[ "$DRY_RUN" == true ]] && echo "  モード: ドライラン"
echo "═══════════════════════════════════════════════"
echo ""

success_count=0
fail_count=0
count=0

while IFS= read -r entry; do
  issue_num=$(echo "$entry" | jq -r '.issue')
  new_title=$(echo "$entry" | jq -r '.title // empty')
  new_body=$(echo "$entry" | jq -r '.body // empty')
  new_state=$(echo "$entry" | jq -r '.state // empty')
  add_labels=$(echo "$entry" | jq -r '.add_labels // [] | join(",")')
  remove_labels=$(echo "$entry" | jq -r '.remove_labels // [] | join(",")')
  new_milestone=$(echo "$entry" | jq -r '.milestone // empty')

  if [[ -z "$issue_num" || "$issue_num" == "null" ]]; then
    print_warn "issue 番号が未指定のエントリをスキップ"
    continue
  fi

  # ドライラン: 現在の状態を取得して差分を表示
  if [[ "$DRY_RUN" == true ]]; then
    current=$(gh api "repos/$REPO/issues/$issue_num" \
      --jq '{title: .title, state: .state, labels: [.labels[].name], milestone: .milestone.number}' 2>/dev/null) || {
      print_warn "#$issue_num の取得に失敗"
      continue
    }
    current_title=$(echo "$current" | jq -r '.title')

    echo "📝 #$issue_num: $current_title"
    [[ -n "$new_title" ]] && echo "  タイトル: $current_title → $new_title"
    [[ -n "$new_body" ]] && echo "  本文: (変更あり)"
    if [[ -n "$new_state" ]]; then
      current_state=$(echo "$current" | jq -r '.state')
      echo "  ステート: $current_state → $new_state"
    fi
    [[ -n "$add_labels" ]] && echo "  ラベル追加: $add_labels"
    [[ -n "$remove_labels" ]] && echo "  ラベル削除: $remove_labels"
    if [[ -n "$new_milestone" ]]; then
      current_milestone=$(echo "$current" | jq -r '.milestone // "なし"')
      echo "  マイルストーン: $current_milestone → #$new_milestone"
    fi
    echo ""
    continue
  fi

  # gh issue edit の引数を構築
  edit_args=(--repo "$REPO")
  has_edit=false

  if [[ -n "$new_title" ]]; then
    safe_title=$(sanitize_string "$new_title" 256)
    edit_args+=(--title "$safe_title")
    has_edit=true
  fi
  if [[ -n "$new_body" ]]; then
    safe_body=$(sanitize_markdown "$new_body" 65536)
    edit_args+=(--body "$safe_body")
    has_edit=true
  fi
  if [[ -n "$add_labels" ]]; then
    edit_args+=(--add-label "$add_labels")
    has_edit=true
  fi
  if [[ -n "$remove_labels" ]]; then
    edit_args+=(--remove-label "$remove_labels")
    has_edit=true
  fi

  # milestone は REST API で設定
  if [[ -n "$new_milestone" ]]; then
    if assign_milestone "$REPO" "$issue_num" "$new_milestone" 2>/dev/null; then
      echo "   ↳ マイルストーン #$new_milestone に割り当て済み"
    else
      print_warn "#$issue_num へのマイルストーン割り当てに失敗"
    fi
  fi

  # edit 実行
  if [[ "$has_edit" == true ]]; then
    if gh issue edit "$issue_num" "${edit_args[@]}" >/dev/null 2>&1; then
      print_success "#$issue_num を更新しました"
    else
      print_warn "#$issue_num の更新に失敗"
      ((fail_count++)) || true
      continue
    fi
  fi

  # state 変更
  if [[ "$new_state" == "closed" ]]; then
    if gh issue close "$issue_num" --repo "$REPO" >/dev/null 2>&1; then
      echo "   ↳ Closed"
    else
      print_warn "#$issue_num の Close に失敗"
    fi
  elif [[ "$new_state" == "open" ]]; then
    if gh issue reopen "$issue_num" --repo "$REPO" >/dev/null 2>&1; then
      echo "   ↳ Reopened"
    else
      print_warn "#$issue_num の Reopen に失敗"
    fi
  fi

  ((success_count++)) || true

  # レート制限対策
  ((count++)) || true
  if ((count % BATCH_SIZE == 0)); then
    print_wait "バッチ完了（$count 件）、${DELAY_SEC}秒待機中..."
    sleep "$DELAY_SEC"
  fi
done < <(jq -c '.[]' "$UPDATES_FILE")

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
