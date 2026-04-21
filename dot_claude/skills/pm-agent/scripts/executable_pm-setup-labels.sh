#!/bin/bash
# pm-setup-labels.sh - カスタムラベル作成
# Usage: pm-setup-labels.sh [owner/repo] [options]
#
# プロジェクト用のカスタムラベルを作成する。
# type分類はタイトルの絵文字プレフィックスで行うため、type:*ラベルは不要。
# priority は Projects V2 フィールドで管理するため、ラベルは使用しない。
#
# 冪等: 既存のラベルはスキップ。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/pm-utils.sh"

usage() {
  cat <<EOF
使い方: $0 [owner/repo] [オプション]

オプション:
  --dry-run              ラベルを作成せずにプレビュー
  -h, --help             このヘルプを表示

作成されるラベル:
  - enhancement (カスタムラベル)
  - documentation (カスタムラベル)
  - frontend (カスタムラベル)
  - backend (カスタムラベル)
  - design (カスタムラベル)
  - infra (カスタムラベル)

※ type分類はタイトルの絵文字プレフィックス（🏁🎯📋⚙️🐛）で行います。
※ priority は Projects V2 フィールドで管理します。
EOF
  exit 1
}

# デフォルト値
REPO=""
DRY_RUN=false

# 引数の解析
while [[ $# -gt 0 ]]; do
  case $1 in
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
      REPO="$1"
      shift
      ;;
  esac
done

REPO="${REPO:-$(get_repo)}"

echo "═══════════════════════════════════════════════"
echo "📋 pm-setup-labels.sh"
echo "───────────────────────────────────────────────"
echo "  リポジトリ: $REPO"
[[ "$DRY_RUN" == true ]] && echo "  モード: ドライラン"
echo "═══════════════════════════════════════════════"
echo ""

# カスタムラベル定義: "name|color|description"
LABELS=(
  "enhancement|A2EEEF|機能改善"
  "documentation|0075CA|ドキュメント"
  "frontend|7057FF|フロントエンド"
  "backend|E99695|バックエンド"
  "design|F9D0C4|デザイン"
  "infra|D4C5F9|インフラ"
)

created=0
skipped=0

for label_def in "${LABELS[@]}"; do
  IFS='|' read -r name color description <<< "$label_def"

  # 既存チェック
  if gh api "repos/$REPO/labels/$name" > /dev/null 2>&1; then
    print_skip "既存: $name"
    ((skipped++)) || true
    continue
  fi

  if [[ "$DRY_RUN" == true ]]; then
    echo "作成予定: $name (#$color) - $description"
    continue
  fi

  if gh api "repos/$REPO/labels" \
    -X POST \
    -f name="$name" \
    -f color="$color" \
    -f description="$description" > /dev/null 2>&1; then
    print_success "作成: $name"
    ((created++)) || true
  else
    print_warn "失敗: $name"
  fi
done

echo ""
echo "═══════════════════════════════════════════════"
echo "📊 結果サマリー"
echo "───────────────────────────────────────────────"
if [[ "$DRY_RUN" == true ]]; then
  echo "  モード: ドライラン（ラベルは作成されていません）"
else
  echo "  作成: $created 件"
  echo "  スキップ: $skipped 件（既存）"
fi
echo "═══════════════════════════════════════════════"
