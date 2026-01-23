# 🏠 Dotfiles

Modern development environment managed with **chezmoi** + **mise**.

## ✨ Features

### 🔧 Runtime Management (mise)
- **Node.js** 24.1.0
- **Python** 3.14.0
- **Ruby** 3.3.10
- **Java** 17.0.2
- **Flutter** 3.22.0 (replaces fvm)
- **Package Managers**: bun, yarn, pnpm

### 📁 Configuration Management (chezmoi)
- **Shell**: .zshrc with Sheldon (fast plugin management)
- **Prompt**: Starship (cross-shell prompt)
- **Git**: Global settings and ignore patterns
- **Editors**: nvim, VSCode configurations
- **Tools**: Docker, gh (GitHub CLI), uv (Python)

### ⚡ Key Benefits
- **Fast shell startup** with optimized plugin management
- **Unified runtime management** for all development tools
- **Cross-platform compatibility** for consistent environments

## 🚀 Quick Setup

### New Machine
```bash
# Install chezmoi
brew install chezmoi

# Clone and apply dotfiles
chezmoi init --apply https://github.com/owk-owk130/dotfiles.git

# Install mise-managed tools
mise install
```

### Daily Usage
```bash
# Update configurations
chezmoi update

# Add new dotfiles
chezmoi add ~/.newconfig

# Manage runtime versions
mise use node@20.0.0  # Per-project
mise use -g python@3.12  # Global
```

## 📂 Structure

```
├── dot_zshrc              # Shell configuration
├── dot_gitconfig          # Git global settings
├── dot_Brewfile           # Homebrew dependencies
├── dot_config/
│   ├── mise/              # Runtime version management
│   ├── starship.toml      # Prompt configuration
│   ├── sheldon/           # Shell plugins
│   ├── nvim/              # Neovim configuration
│   ├── gh/                # GitHub CLI settings
│   └── git/               # Git templates and hooks
└── dot_docker/            # Docker configuration
```

## 📋 Requirements

- macOS or Linux
- [Homebrew](https://brew.sh/) (for initial setup)

## 🛠 Tools Used

- [chezmoi](https://chezmoi.io/) - Dotfiles management
- [mise](https://mise.jdx.dev/) - Runtime version management
- [Sheldon](https://sheldon.cli.rs/) - Fast shell plugin manager
- [Starship](https://starship.rs/) - Cross-shell prompt
>>>>>>> master
