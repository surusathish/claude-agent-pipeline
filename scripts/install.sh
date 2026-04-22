#!/bin/bash
# Installs agents to ~/.claude/agents/ (global, available in all projects)
# Usage: bash scripts/install.sh

AGENTS_DIR="$HOME/.claude/agents"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$SCRIPT_DIR/../agents"

mkdir -p "$AGENTS_DIR"

for file in "$SOURCE_DIR"/*.md; do
  name=$(basename "$file")
  dest="$AGENTS_DIR/$name"
  if [ -f "$dest" ]; then
    echo "  skipping $name (already exists — delete manually to overwrite)"
  else
    cp "$file" "$dest"
    echo "  installed $name"
  fi
done

echo ""
echo "Done. Agents available in all Claude Code projects."
echo "To verify: ls ~/.claude/agents/"
