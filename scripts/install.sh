#!/bin/bash
set -euo pipefail

# cc-configs installer
# Usage: install.sh [--components=claude,rules,hooks,settings] [--hooks=auto-allow,git-guard,rtk-rewrite]

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Parse arguments
COMPONENTS="claude,rules,hooks,settings"  # default: all
HOOKS="auto-allow,git-guard,rtk-rewrite"  # default: all hooks

for arg in "$@"; do
  case "$arg" in
    --components=*) COMPONENTS="${arg#--components=}" ;;
    --hooks=*)      HOOKS="${arg#--hooks=}" ;;
  esac
done

has_component() { echo "$COMPONENTS" | tr ',' '\n' | grep -qx "$1"; }
has_hook()      { echo "$HOOKS"       | tr ',' '\n' | grep -qx "$1"; }

# Validate
if [ ! -d "$CLAUDE_HOME" ]; then
  error "$CLAUDE_HOME does not exist. Install Claude Code first."
  exit 1
fi

# Backup
BACKUP_DIR="$CLAUDE_HOME/backups/config-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"
info "Backup: $BACKUP_DIR"

backup_if_exists() {
  local target="$1"
  if [ -e "$target" ] && [ ! -L "$target" ]; then
    cp -r "$target" "$BACKUP_DIR/"
  fi
}

copy_file() {
  local src="$1" dest="$2"
  backup_if_exists "$dest"
  [ -L "$dest" ] && rm "$dest"
  cp "$src" "$dest"
  info "  Installed: $(basename "$dest")"
}

INSTALLED=()

# --- CLAUDE.md ---
if has_component "claude"; then
  info "=== CLAUDE.md ==="
  copy_file "$REPO_DIR/CLAUDE.md" "$CLAUDE_HOME/CLAUDE.md"
  INSTALLED+=("CLAUDE.md")
fi

# --- rules/ ---
if has_component "rules"; then
  info "=== rules/ ==="
  mkdir -p "$CLAUDE_HOME/rules"
  for f in "$REPO_DIR"/rules/*.md; do
    [ -f "$f" ] || continue
    copy_file "$f" "$CLAUDE_HOME/rules/$(basename "$f")"
    INSTALLED+=("rules/$(basename "$f")")
  done
fi

# --- hooks/ ---
if has_component "hooks"; then
  info "=== hooks/ ==="
  mkdir -p "$CLAUDE_HOME/hooks"

  install_hook() {
    local src="$1"
    if [ -f "$src" ]; then
      copy_file "$src" "$CLAUDE_HOME/hooks/$(basename "$src")"
      INSTALLED+=("hooks/$(basename "$src")")
    fi
  }

  has_hook "auto-allow"  && install_hook "$REPO_DIR/hooks/bash-auto-allow.sh"
  has_hook "git-guard"   && install_hook "$REPO_DIR/hooks/git-guard-hook.sh"
  has_hook "rtk-rewrite" && install_hook "$REPO_DIR/hooks/rtk-rewrite.sh"

  # Copy checklist markdown files always (referenced by git-guard)
  for f in "$REPO_DIR"/hooks/*.md; do
    [ -f "$f" ] || continue
    copy_file "$f" "$CLAUDE_HOME/hooks/$(basename "$f")"
  done

  chmod +x "$CLAUDE_HOME"/hooks/*.sh 2>/dev/null || true

  # Warn if rtk-rewrite selected but rtk not installed
  if has_hook "rtk-rewrite" && ! command -v rtk &>/dev/null; then
    warn "rtk-rewrite hook installed but 'rtk' is not in PATH."
    warn "Install RTK: cargo install rtk"
  fi
fi

# --- settings.json ---
if has_component "settings"; then
  info "=== settings.json ==="
  TEMPLATE="$REPO_DIR/settings.json.template"
  TARGET="$CLAUDE_HOME/settings.json"

  if [ ! -f "$TEMPLATE" ]; then
    warn "settings.json.template not found. Skipping."
  else
    RENDERED=$(sed "s|{{CLAUDE_HOME}}|$CLAUDE_HOME|g" "$TEMPLATE")

    if [ -f "$TARGET" ]; then
      backup_if_exists "$TARGET"
      PLUGIN_FIELDS=$(jq '{
        enabledPlugins: .enabledPlugins,
        extraKnownMarketplaces: .extraKnownMarketplaces,
        statusLine: .statusLine,
        permissions: {allow: .permissions.allow}
      } | with_entries(select(.value != null))' "$TARGET" 2>/dev/null || echo '{}')
      echo "$RENDERED" | jq --argjson p "$PLUGIN_FIELDS" '. * $p' > "$TARGET"
      info "  settings.json merged"
    else
      echo "$RENDERED" > "$TARGET"
      info "  settings.json created"
    fi
    INSTALLED+=("settings.json")
  fi
fi

# --- Done ---
info ""
info "=== Done ==="
info "Installed: ${INSTALLED[*]:-none}"
info "Backup: $BACKUP_DIR"
