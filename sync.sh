#!/bin/bash
set -euo pipefail

# Reverse sync: ~/.claude -> repo
# Copies modified config files back to the repo for committing.

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

# --- 1. CLAUDE.md ---

if [ -f "$CLAUDE_HOME/CLAUDE.md" ] && [ ! -L "$CLAUDE_HOME/CLAUDE.md" ]; then
  cp "$CLAUDE_HOME/CLAUDE.md" "$REPO_DIR/CLAUDE.md"
  info "CLAUDE.md synced"
fi

# --- 2. RTK.md ---

if [ -f "$CLAUDE_HOME/RTK.md" ] && [ ! -L "$CLAUDE_HOME/RTK.md" ]; then
  cp "$CLAUDE_HOME/RTK.md" "$REPO_DIR/RTK.md"
  info "RTK.md synced"
fi

# --- 3. Rules ---

info ""
info "=== Rules ==="
for rule_file in "$CLAUDE_HOME"/rules/*.md; do
  [ -f "$rule_file" ] || continue
  name=$(basename "$rule_file")
  if [ -L "$rule_file" ]; then continue; fi
  if [ -f "$REPO_DIR/rules/$name" ]; then
    cp "$rule_file" "$REPO_DIR/rules/$name"
    info "  rules/$name synced"
  fi
done

# --- 4. Hooks ---

info ""
info "=== Hooks ==="
for hook_file in "$CLAUDE_HOME"/hooks/*; do
  [ -f "$hook_file" ] || continue
  name=$(basename "$hook_file")
  if [ -L "$hook_file" ]; then continue; fi
  if [ -f "$REPO_DIR/hooks/$name" ]; then
    cp "$hook_file" "$REPO_DIR/hooks/$name"
    info "  hooks/$name synced"
  fi
done

# Ensure scripts are executable
chmod +x "$REPO_DIR"/hooks/*.sh 2>/dev/null || true

# --- 5. settings.json -> settings.json.template ---

info ""
info "=== Settings ==="

SOURCE="$CLAUDE_HOME/settings.json"
TARGET="$REPO_DIR/settings.json.template"

if [ -f "$SOURCE" ]; then
  if ! command -v jq &>/dev/null; then
    warn "jq is required for settings.json sync: brew install jq"
  else
    # Strip plugin-managed fields + replace absolute paths with placeholder
    jq 'del(.enabledPlugins, .extraKnownMarketplaces, .statusLine, .permissions.allow)' "$SOURCE" \
      | sed "s|$CLAUDE_HOME|{{CLAUDE_HOME}}|g" \
      > "$TARGET"
    info "  settings.json.template synced"
  fi
else
  warn "settings.json not found in $CLAUDE_HOME. Skipping."
fi

# --- Done ---

info ""
info "=== Reverse sync complete ==="
info ""
info "Review changes: cd $REPO_DIR && git diff"
