#!/bin/bash
set -euo pipefail

# Claude Code global settings installer
# Copies config files from this repo into ~/.claude with smart merging.

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# --- Validation ---

if [ ! -d "$CLAUDE_HOME" ]; then
  error "$CLAUDE_HOME does not exist. Install Claude Code first."
  exit 1
fi

# --- Backup ---

BACKUP_DIR="$CLAUDE_HOME/backups/config-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"
info "Backing up existing settings: $BACKUP_DIR"

backup_if_exists() {
  local target="$1"
  if [ -e "$target" ] && [ ! -L "$target" ]; then
    cp -r "$target" "$BACKUP_DIR/"
    info "  Backed up: $(basename "$target")"
  fi
}

# --- Copy helper ---

copy_file() {
  local src="$1"
  local dest="$2"

  backup_if_exists "$dest"

  # Remove existing symlink if present (migration from old symlink approach)
  if [ -L "$dest" ]; then
    rm "$dest"
  fi

  cp "$src" "$dest"
  info "  Copied: $(basename "$dest")"
}

# --- 1. CLAUDE.md (merge: preserve OMC block from existing) ---

info ""
info "=== CLAUDE.md ==="

CLAUDE_MD_SRC="$REPO_DIR/CLAUDE.md"
CLAUDE_MD_DEST="$CLAUDE_HOME/CLAUDE.md"

if [ -f "$CLAUDE_MD_SRC" ]; then
  # Remove existing symlink if present
  if [ -L "$CLAUDE_MD_DEST" ]; then
    rm "$CLAUDE_MD_DEST"
  fi

  if [ -f "$CLAUDE_MD_DEST" ]; then
    backup_if_exists "$CLAUDE_MD_DEST"

    # Extract OMC block from existing file
    OMC_BLOCK=""
    if grep -q '<!-- OMC:START -->' "$CLAUDE_MD_DEST" 2>/dev/null; then
      OMC_BLOCK=$(sed -n '/<!-- OMC:START -->/,/<!-- OMC:END -->/p' "$CLAUDE_MD_DEST")
    fi

    # Extract non-OMC content from repo source
    NON_OMC=$(sed '/<!-- OMC:START -->/,/<!-- OMC:END -->/d' "$CLAUDE_MD_SRC")

    # Assemble: existing OMC block + repo's non-OMC content
    if [ -n "$OMC_BLOCK" ]; then
      printf '%s\n\n%s\n' "$OMC_BLOCK" "$NON_OMC" > "$CLAUDE_MD_DEST"
    else
      echo "$NON_OMC" > "$CLAUDE_MD_DEST"
    fi
    info "  CLAUDE.md merged (OMC block preserved, base content updated)"
  else
    cp "$CLAUDE_MD_SRC" "$CLAUDE_MD_DEST"
    info "  CLAUDE.md created"
  fi
fi

# --- 2. RTK.md ---

info ""
info "=== RTK.md ==="

if [ -f "$REPO_DIR/RTK.md" ]; then
  copy_file "$REPO_DIR/RTK.md" "$CLAUDE_HOME/RTK.md"
fi

# --- 3. Rules ---

info ""
info "=== Rules ==="

mkdir -p "$CLAUDE_HOME/rules"

for rule_file in "$REPO_DIR"/rules/*.md; do
  [ -f "$rule_file" ] || continue
  name=$(basename "$rule_file")
  copy_file "$rule_file" "$CLAUDE_HOME/rules/$name"
done

# --- 4. Hooks ---

info ""
info "=== Hooks ==="

mkdir -p "$CLAUDE_HOME/hooks"

for hook_file in "$REPO_DIR"/hooks/*; do
  [ -f "$hook_file" ] || continue
  name=$(basename "$hook_file")
  copy_file "$hook_file" "$CLAUDE_HOME/hooks/$name"
done

# Ensure scripts are executable
chmod +x "$CLAUDE_HOME"/hooks/*.sh 2>/dev/null || true

# --- 5. Merge settings.json ---

info ""
info "=== Settings ==="

TEMPLATE="$REPO_DIR/settings.json.template"
TARGET="$CLAUDE_HOME/settings.json"

if [ ! -f "$TEMPLATE" ]; then
  warn "settings.json.template not found. Skipping."
else
  # Replace {{CLAUDE_HOME}} placeholder with actual path
  RENDERED=$(sed "s|{{CLAUDE_HOME}}|$CLAUDE_HOME|g" "$TEMPLATE")

  if [ -f "$TARGET" ]; then
    # Merge: use template as base, overlay plugin-managed fields from existing settings
    backup_if_exists "$TARGET"

    EXISTING="$TARGET"
    PLUGIN_FIELDS=$(jq '{
      enabledPlugins: .enabledPlugins,
      extraKnownMarketplaces: .extraKnownMarketplaces,
      statusLine: .statusLine
    } | with_entries(select(.value != null))' "$EXISTING" 2>/dev/null || echo '{}')

    echo "$RENDERED" | jq --argjson plugins "$PLUGIN_FIELDS" '. + $plugins' > "$TARGET"
    info "  settings.json merged (template + existing plugin settings preserved)"
  else
    # No existing file — create from template
    echo "$RENDERED" > "$TARGET"
    info "  settings.json created"
  fi
fi

# --- Done ---

info ""
info "=== Installation complete ==="
info ""
info "Install the following dependencies via official channels:"
info "  - oh-my-claudecode: claude plugin install oh-my-claudecode@omc"
info "  - RTK:              cargo install rtk"
info "  - claude-mem:       claude plugin install claude-mem@thedotmack"
info "  - jq:               brew install jq"
info ""
info "Backup location: $BACKUP_DIR"
info ""
info "To update after git pull: re-run ./install.sh"
