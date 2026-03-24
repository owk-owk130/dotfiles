#!/bin/zsh
# Sync new custom skills to chezmoi source
# Runs on SessionEnd to detect newly added skills (non-symlink directories)

SKILLS_DIR="$HOME/.claude/skills"

[ -d "$SKILLS_DIR" ] || exit 0

added=()

for dir in "$SKILLS_DIR"/*/; do
  [ -d "$dir" ] || continue
  # Skip symlinks (marketplace-installed skills)
  [ -L "${dir%/}" ] && continue

  name=$(basename "$dir")
  # Check if already managed by chezmoi
  if ! chezmoi managed --path-style absolute 2>/dev/null | grep -q "\.claude/skills/$name\b"; then
    chezmoi add "$dir" 2>/dev/null && added+=("$name")
  fi
done

if [ ${#added[@]} -gt 0 ]; then
  echo "chezmoi: synced new skills: ${added[*]}" >&2
fi
