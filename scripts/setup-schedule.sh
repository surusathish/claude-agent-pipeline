#!/bin/bash
# Sets up daily + weekly usage-reporter via crontab
# Works on: Linux, macOS, Windows WSL

set -e

# Detect OS
detect_os() {
  if grep -qi microsoft /proc/version 2>/dev/null; then
    echo "wsl"
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    echo "macos"
  else
    echo "linux"
  fi
}

OS=$(detect_os)
echo "Detected: $OS"

# Verify claude CLI is available
if ! command -v claude &>/dev/null; then
  echo ""
  echo "ERROR: 'claude' CLI not found in PATH."
  echo "Install it first: https://claude.ai/code"
  exit 1
fi

CLAUDE_PATH=$(command -v claude)
echo "Claude CLI found at: $CLAUDE_PATH"

# WSL: ensure cron daemon is running
if [[ "$OS" == "wsl" ]]; then
  if ! service cron status &>/dev/null; then
    echo "Starting cron daemon (WSL requires this on each boot)..."
    sudo service cron start
    echo ""
    echo "NOTE for WSL users: cron stops when WSL restarts."
    echo "Add this to your ~/.bashrc or ~/.zshrc to auto-start it:"
    echo '  sudo service cron start 2>/dev/null'
  fi
fi

# Build crontab entries
DAILY_ENTRY="0 9 * * * $CLAUDE_PATH -p '@\"usage-reporter\" daily' >> \$HOME/.claude/usage-reports.log 2>&1"
WEEKLY_ENTRY="0 9 * * 1 $CLAUDE_PATH -p '@\"usage-reporter\" weekly' >> \$HOME/.claude/usage-reports.log 2>&1"

# Check if already installed
EXISTING=$(crontab -l 2>/dev/null || true)

if echo "$EXISTING" | grep -q "usage-reporter"; then
  echo ""
  echo "usage-reporter schedule already exists in crontab. Skipping."
  echo "To view: crontab -l"
  echo "To edit: crontab -e"
  exit 0
fi

# Write new crontab
(echo "$EXISTING"; echo "# Claude agent pipeline — usage reports"; echo "$DAILY_ENTRY"; echo "$WEEKLY_ENTRY") | crontab -

echo ""
echo "Scheduled:"
echo "  Daily  — 9am, writes to ~/.claude/usage-reports.log"
echo "  Weekly — Monday 9am, writes to ~/.claude/usage-reports.log"
echo ""
echo "To verify: crontab -l"
echo "To view reports: cat ~/.claude/usage-reports.log"
