# cc-configs Skill Conversion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Convert claude-code-configs repo into a Claude Code marketplace plugin with `/cc-configs:install` skill.

**Architecture:** Root `SKILL.md` acts as plugin manifest; `skills/install/SKILL.md` is the interactive skill body that calls `scripts/install.sh` with `--components` and `--hooks` flags; `scripts/install.sh` is a refactored version of the existing `install.sh` with argument-based selective installation.

**Tech Stack:** Bash, Claude Code Skill (Markdown), jq

---

## File Map

| Action | Path |
|--------|------|
| Create | `SKILL.md` |
| Create | `skills/install/SKILL.md` |
| Create | `scripts/install.sh` |
| Delete | `install.sh` |
| Modify | `README.md` |

---

### Task 1: Refactor install.sh → scripts/install.sh

**Files:**
- Create: `scripts/install.sh`
- Delete: `install.sh`

- [ ] **Step 1: Create scripts/ directory**

```bash
mkdir -p /tmp/claude-code-configs/scripts
```

- [ ] **Step 2: Write scripts/install.sh**

Create `/tmp/claude-code-configs/scripts/install.sh` with this content:

```bash
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

has_component() { echo "$COMPONENTS" | grep -qw "$1"; }
has_hook()      { echo "$HOOKS" | grep -qw "$1"; }

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
    local name="$1" src="$2"
    if [ -f "$src" ]; then
      copy_file "$src" "$CLAUDE_HOME/hooks/$(basename "$src")"
      INSTALLED+=("hooks/$(basename "$src")")
    fi
  }

  has_hook "auto-allow"  && install_hook "auto-allow"  "$REPO_DIR/hooks/bash-auto-allow.sh"
  has_hook "git-guard"   && install_hook "git-guard"   "$REPO_DIR/hooks/git-guard-hook.sh"
  has_hook "rtk-rewrite" && install_hook "rtk-rewrite" "$REPO_DIR/hooks/rtk-rewrite.sh"

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
        "permissions": {"allow": .permissions.allow}
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
info "Installed: ${INSTALLED[*]}"
info "Backup: $BACKUP_DIR"
```

- [ ] **Step 3: Make executable**

```bash
chmod +x /tmp/claude-code-configs/scripts/install.sh
```

- [ ] **Step 4: Verify script parses args correctly**

```bash
cd /tmp/claude-code-configs
bash scripts/install.sh --components=claude --help 2>&1 || true
# Should not error on unknown flags, just install claude component
bash -n scripts/install.sh && echo "Syntax OK"
```

Expected: `Syntax OK`

- [ ] **Step 5: Delete old install.sh**

```bash
rm /tmp/claude-code-configs/install.sh
```

- [ ] **Step 6: Commit**

```bash
cd /tmp/claude-code-configs
git add scripts/install.sh install.sh
git commit -m "refactor: move install.sh to scripts/install.sh with --components/--hooks args"
```

---

### Task 2: Create root SKILL.md (plugin manifest)

**Files:**
- Create: `SKILL.md`

- [ ] **Step 1: Write root SKILL.md**

Create `/tmp/claude-code-configs/SKILL.md`:

```markdown
# cc-configs

Claude Code global configuration manager — installs CLAUDE.md, rules, hooks, and settings to `~/.claude`.

## Skills

- `install` — Interactive install of config files to `~/.claude`

## Quick Start

```bash
# Add marketplace
claude /plugin marketplace add https://github.com/levx/claude-code-configs

# Install plugin
claude plugin install cc-configs@levx

# Deploy configs
/cc-configs:install
```

## Manual Install

```bash
git clone git@github.com:levx/claude-code-configs.git
cd claude-code-configs
./scripts/install.sh
```
```

- [ ] **Step 2: Commit**

```bash
cd /tmp/claude-code-configs
git add SKILL.md
git commit -m "feat: add root SKILL.md as plugin manifest"
```

---

### Task 3: Create skills/install/SKILL.md

**Files:**
- Create: `skills/install/SKILL.md`

- [ ] **Step 1: Create directory**

```bash
mkdir -p /tmp/claude-code-configs/skills/install
```

- [ ] **Step 2: Write skills/install/SKILL.md**

Create `/tmp/claude-code-configs/skills/install/SKILL.md`:

````markdown
# cc-configs Install Skill

Install levx's Claude Code config files to `~/.claude` interactively.

**When invoked, execute the steps below immediately. Do not summarize.**

## Step 1: Detect plugin root

The plugin root is available as `${CLAUDE_PLUGIN_ROOT}`. Verify the install script exists:

```bash
ls "${CLAUDE_PLUGIN_ROOT}/scripts/install.sh"
```

If missing, tell the user:
```
scripts/install.sh not found in plugin root.
Please reinstall the plugin: claude plugin install cc-configs@levx
```
And stop.

## Step 2: Select components

Use AskUserQuestion (multiSelect: true):

**Question:** "어떤 컴포넌트를 설치할까요?"

**Options:**
1. **CLAUDE.md** — Global Claude instructions (value: `claude`) — default selected
2. **rules/** — Auto-injected project rules (value: `rules`) — default selected
3. **hooks/** — PreToolUse bash hooks (value: `hooks`)
4. **settings.json** — Merge settings template (value: `settings`)

Store selected values as COMPONENTS (comma-joined).

If no components selected, tell user "Nothing selected. Exiting." and stop.

## Step 3: Select hooks (only if hooks selected)

If `hooks` is in COMPONENTS, use AskUserQuestion (multiSelect: true):

**Question:** "어떤 훅을 설치할까요?"

**Options:**
1. **bash-auto-allow** — 위험 패턴 제외 Bash 명령 자동 허용 (value: `auto-allow`) — default selected
2. **git-guard** — git commit/push 시 안전 체크리스트 주입 (value: `git-guard`) — default selected
3. **rtk-rewrite** — RTK 토큰 절약 프록시 자동 재작성 (value: `rtk-rewrite`)

Store selected values as HOOKS (comma-joined). If none selected, remove `hooks` from COMPONENTS.

## Step 4: Run install script

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/install.sh" \
  --components=<COMPONENTS> \
  --hooks=<HOOKS>
```

Replace `<COMPONENTS>` and `<HOOKS>` with actual selections.

Example:
```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/install.sh" \
  --components=claude,rules,hooks \
  --hooks=auto-allow,git-guard
```

## Step 5: Report results

Display the install script output to the user.

If rtk-rewrite was selected and `rtk` is not in PATH, remind:
```
RTK 미설치: cargo install rtk 로 설치하세요.
https://github.com/rtk-ai/rtk
```

Tell user to **restart Claude Code** for CLAUDE.md and hooks changes to take effect.
````

- [ ] **Step 3: Commit**

```bash
cd /tmp/claude-code-configs
git add skills/
git commit -m "feat: add skills/install/SKILL.md for /cc-configs:install"
```

---

### Task 4: Update README.md

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Rewrite README.md**

Replace the Quick Start section and Structure section to reflect the new plugin-based workflow. Full new content:

```markdown
# Claude Code Configs

A Claude Code marketplace plugin for managing global settings (`~/.claude`).

## Quick Start

### As a Claude Code plugin (recommended)

```bash
# Add this repo as a marketplace source (one time)
claude /plugin marketplace add https://github.com/levx/claude-code-configs

# Install the plugin
claude plugin install cc-configs@levx

# Deploy configs interactively
/cc-configs:install
```

### Manual install

```bash
git clone git@github.com:levx/claude-code-configs.git
cd claude-code-configs
./scripts/install.sh
# or selectively:
./scripts/install.sh --components=claude,rules --hooks=auto-allow,git-guard
```

## Structure

```
├── SKILL.md                       # Plugin manifest
├── skills/
│   └── install/
│       └── SKILL.md               # /cc-configs:install skill
├── scripts/
│   └── install.sh                 # Installer (--components / --hooks args)
├── CLAUDE.md                      # Global Claude instructions (includes OMC)
├── RTK.md                         # RTK token-saving CLI guide
├── rules/
│   ├── cli-checklist.md
│   ├── readme-guide.md
│   └── refactor-safety.md
├── hooks/
│   ├── bash-auto-allow.sh
│   ├── git-guard-hook.sh
│   ├── rtk-rewrite.sh
│   ├── pre-commit-checklist.md
│   └── pre-push-checklist.md
└── settings.json.template
```

## scripts/install.sh Options

```bash
./scripts/install.sh                                      # Install all
./scripts/install.sh --components=claude,rules            # Selective
./scripts/install.sh --components=hooks --hooks=git-guard # Specific hooks
```

**Components:** `claude`, `rules`, `hooks`, `settings`
**Hooks:** `auto-allow`, `git-guard`, `rtk-rewrite`

## Syncing local changes back

```bash
./sync.sh && git add -A && git commit -m "chore: sync local changes"
```

## Dependencies (Optional)

| Tool | Purpose | Install |
|------|---------|---------|
| [oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode) | Multi-agent orchestration | `claude plugin install oh-my-claudecode@omc` |
| [RTK](https://github.com/rtk-ai/rtk) | Token-saving CLI proxy | `cargo install rtk` |
| [jq](https://jqlang.github.io/jq/) | Hook dependency | `brew install jq` |

## Caveats

- Never commit secrets (`.mcp.json`, `.env`, etc.)
- `enabledPlugins`, `statusLine` are managed by Claude Code — preserved during merge

## License

MIT
```

- [ ] **Step 2: Commit**

```bash
cd /tmp/claude-code-configs
git add README.md
git commit -m "docs: update README for plugin-based workflow"
```

---

### Task 5: End-to-end verification

- [ ] **Step 1: Verify repo structure**

```bash
find /tmp/claude-code-configs -not -path '*/.git/*' -type f | sort
```

Expected files:
```
CLAUDE.md
README.md
RTK.md
SKILL.md
docs/superpowers/plans/2026-04-07-cc-configs-skill.md
docs/superpowers/specs/2026-04-07-cc-configs-skill-design.md
hooks/bash-auto-allow.sh
hooks/git-guard-hook.sh
hooks/pre-commit-checklist.md
hooks/pre-push-checklist.md
hooks/rtk-rewrite.sh
rules/cli-checklist.md
rules/readme-guide.md
rules/refactor-safety.md
rules/wiki.md
scripts/install.sh
settings.json.template
skills/install/SKILL.md
sync.sh
```

- [ ] **Step 2: Dry-run install script (claude only)**

```bash
CLAUDE_HOME=/tmp/cc-configs-test bash /tmp/claude-code-configs/scripts/install.sh \
  --components=claude
```

Expected:
```
[INFO] Backup: /tmp/cc-configs-test/backups/config-...
[INFO] === CLAUDE.md ===
[INFO]   Installed: CLAUDE.md
[INFO] === Done ===
```

- [ ] **Step 3: Verify test install**

```bash
ls /tmp/cc-configs-test/CLAUDE.md && echo "PASS" || echo "FAIL"
diff /tmp/cc-configs-test/CLAUDE.md /tmp/claude-code-configs/CLAUDE.md && echo "Content matches"
```

- [ ] **Step 4: Cleanup test dir**

```bash
rm -rf /tmp/cc-configs-test
```

- [ ] **Step 5: Final commit check**

```bash
cd /tmp/claude-code-configs && git log --oneline -8
```
