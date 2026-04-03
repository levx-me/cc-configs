#!/bin/bash
set -euo pipefail

# Reverse sync: ~/.claude -> repo
# Symlinked files are already in sync; this script handles settings.json only.

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

# --- settings.json -> settings.json.template ---

SOURCE="$CLAUDE_HOME/settings.json"
TARGET="$REPO_DIR/settings.json.template"

if [ ! -f "$SOURCE" ]; then
  warn "$SOURCE not found. Skipping."
  exit 0
fi

if ! command -v jq &>/dev/null; then
  warn "jq is required: brew install jq"
  exit 1
fi

# Strip plugin-managed fields + replace absolute paths with placeholder
jq 'del(.enabledPlugins, .extraKnownMarketplaces, .statusLine)' "$SOURCE" \
  | sed "s|$CLAUDE_HOME|{{CLAUDE_HOME}}|g" \
  > "$TARGET"

info "settings.json.template synced"
info ""
info "Review changes: cd $REPO_DIR && git diff"
