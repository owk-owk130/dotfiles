# Dotfiles

chezmoi + mise で管理する開発環境の設定ファイル群。

## セットアップ

### 新規マシン

```bash
# chezmoi をインストール
brew install chezmoi

# dotfiles を clone して適用
chezmoi init --apply https://github.com/owk-owk130/dotfiles.git

# mise 管理のランタイムをインストール
mise install
```

### 日常の操作

```bash
# リモートの変更を取得して適用
chezmoi update

# 新しい設定ファイルを管理下に追加
chezmoi add ~/.newconfig

# 管理中のファイルを編集（エディタが開く）
chezmoi edit ~/.zshrc

# 編集後に適用
chezmoi apply

# ランタイムバージョンの変更
mise use node@22       # プロジェクト単位
mise use -g python@3.12  # グローバル
```

## 構成

```
dot_zshrc                 # -> ~/.zshrc
dot_gitconfig             # -> ~/.gitconfig
dot_Brewfile              # -> ~/.Brewfile
dot_p10k.zsh              # -> ~/.p10k.zsh
dot_config/
  mise/config.toml        # ランタイムバージョン管理
  sheldon/plugins.toml    # シェルプラグイン管理
  nvim/                   # Neovim 設定
  gh/                     # GitHub CLI 設定
  git/ignore              # グローバル gitignore
  ghostty/config          # Ghostty ターミナル設定
  yazi/                   # yazi ファイラー設定
  flutter/                # Flutter SDK 設定
  uv/                     # uv (Python パッケージマネージャ)
dot_docker/               # Docker 設定
```

## chezmoi の命名規則

| ソースのプレフィックス | 展開先 |
|---|---|
| `dot_` | `.` に変換（例: `dot_zshrc` → `~/.zshrc`） |
| `private_` | パーミッション 600/700 で配置 |
| `readonly_` | パーミッション 444 で配置 |

## mise で管理しているランタイム

| ツール | 用途 |
|---|---|
| node | JavaScript ランタイム |
| python | Python |
| ruby | Ruby |
| java | Java |
| flutter | モバイル開発 |
| bun / pnpm / yarn | パッケージマネージャ |

## 使用ツール

- [chezmoi](https://chezmoi.io/) - dotfiles 管理
- [mise](https://mise.jdx.dev/) - ランタイムバージョン管理
- [Sheldon](https://sheldon.cli.rs/) - シェルプラグインマネージャ
- [Powerlevel10k](https://github.com/romkatv/powerlevel10k) - zsh プロンプトテーマ

## Mac セットアップ手順

chezmoi apply 後に手動で行う設定。

### macOS システム設定

- キーボード > 入力ソース > ライブ変換を解除
- キーボード > 入力ソース > 修飾キー > Caps Lock を Control に変更
- Dock > 自動的に表示/非表示

### アプリ設定

- **Raycast**: Command + Space で起動するように設定
- **1Password**: Git の SSH 署名を設定（https://qiita.com/tonnsama/items/d4c52983e1930d2ec8a8）

### 開発環境

```bash
# Homebrew パッケージの一括インストール
brew bundle --file=~/.Brewfile

# Flutter の確認
flutter doctor
```

### App Store からインストール

- Xcode
- MeetingBar
