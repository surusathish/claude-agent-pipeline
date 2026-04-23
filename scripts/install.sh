#!/bin/bash
# Installs agents to ~/.claude/agents/ (global, available in all projects)
# Optionally installs CLAUDE.md globally or per-project for auto-pipeline
# Usage: bash scripts/install.sh

AGENTS_DIR="$HOME/.claude/agents"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$SCRIPT_DIR/../agents"
CLAUDE_MD="$SCRIPT_DIR/../CLAUDE.md"
GLOBAL_CLAUDE_MD="$HOME/.claude/CLAUDE.md"

mkdir -p "$AGENTS_DIR"

echo "Installing agents..."
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
echo "Agents installed to ~/.claude/agents/ — @router and all agents now work in every project."
echo ""
echo "─────────────────────────────────────────────────────────"
echo "Auto-pipeline setup (optional)"
echo "─────────────────────────────────────────────────────────"
echo "Without CLAUDE.md, you invoke the pipeline manually: @router <task>"
echo "With CLAUDE.md, every input auto-routes through the pipeline."
echo ""
echo "Where do you want CLAUDE.md installed?"
echo "  1) Global (~/.claude/CLAUDE.md) — pipeline fires in EVERY Claude Code session"
echo "  2) This project only ($(pwd)/CLAUDE.md) — pipeline fires only here"
echo "  3) Skip — I'll use @router manually"
echo ""
read -r -p "Choice [1/2/3]: " choice

case "$choice" in
  1)
    if [ -f "$GLOBAL_CLAUDE_MD" ]; then
      echo "  ~/.claude/CLAUDE.md already exists — skipping (delete manually to overwrite)"
    else
      cp "$CLAUDE_MD" "$GLOBAL_CLAUDE_MD"
      echo "  Copied CLAUDE.md → ~/.claude/CLAUDE.md"
      echo "  Pipeline will auto-run in every Claude Code session globally."
    fi
    ;;
  2)
    dest_claude="$(pwd)/CLAUDE.md"
    if [ -f "$dest_claude" ]; then
      echo "  CLAUDE.md already exists at $dest_claude — skipping (delete manually to overwrite)"
    else
      cp "$CLAUDE_MD" "$dest_claude"
      echo "  Copied CLAUDE.md → $dest_claude"
      echo "  Pipeline will auto-run for every input in this project."
    fi
    ;;
  *)
    echo "  Skipped. Use @router <task> to invoke the pipeline manually in any project."
    ;;
esac

echo ""
echo "Done. To verify agents: ls ~/.claude/agents/"
