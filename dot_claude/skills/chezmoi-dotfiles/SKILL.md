---
name: chezmoi-dotfiles
description: >
  dotfile（設定ファイル）の編集・更新を chezmoi 経由で安全に行う。
  Use when: (1) ~/.config/ や ~/. 配下の dotfile を編集・作成する場合,
  (2) シェル設定（.zshrc, .zprofile 等）を変更する場合,
  (3) ターミナル・エディタ等の設定ファイル（ghostty, nvim, mise, gh, git, sheldon, yazi, docker 等）を更新する場合,
  (4) ユーザーが「dotfile」「設定ファイル」「config」に言及した場合,
  (5) Brewfile を更新する場合,
  (6) Claude Code の設定（~/.claude/ 配下）を変更する場合。
  対象パスの例: ~/.config/ghostty/, ~/.config/nvim/, ~/.config/mise/, ~/.zshrc, ~/.gitconfig, ~/.docker/, ~/.claude/ 等。
---

# Chezmoi Dotfiles

dotfile は chezmoi で管理されている。ターゲットファイルを直接編集してはならない。

## ワークフロー

1. **ソースパスを特定する**
   ```bash
   chezmoi source-path <target-path>
   ```

2. **ソースファイルを Read → Edit する**
   - ターゲットパス（`~/.config/...` 等）を直接編集しない

3. **反映する**
   ```bash
   chezmoi apply <target-path>
   ```

## chezmoi のファイル命名規則

| プレフィックス | 意味 |
|---|---|
| `dot_` | `.` に変換 |
| `private_` | パーミッション 0600 |
| `readonly_` | パーミッション 0444 |
| `executable_` | パーミッション 0755 |

## ソースディレクトリ

`~/Documents/dotfiles/`

## ~/.claude/ の管理範囲

chezmoi で管理しているもの:
- `CLAUDE.md` — グローバル指示
- `settings.json` — グローバル設定
- `agents/*.md` — カスタムサブエージェント定義
- `skills/*/` — カスタムスキル（自作のみ。マーケットプレイス由来の symlink は除外）

管理しないもの（ランタイム/マシン固有）:
- `settings.local.json`, `projects/`, `history.jsonl`, `sessions/`, `plugins/`, `cache/`, `debug/` 等

## 注意事項

- 新規 dotfile を追加する場合は `chezmoi add <file>` を使う
- テンプレート（`.tmpl`）ファイルの場合、Go template 構文に注意する
