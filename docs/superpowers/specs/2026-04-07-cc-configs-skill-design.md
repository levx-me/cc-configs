# cc-configs Skill Design

**Date:** 2026-04-07
**Status:** Approved

## Overview

Convert `claude-code-configs` repository into a Claude Code marketplace plugin with an interactive install skill. Users can install config files to `~/.claude` via `/cc-configs:install` after installing the plugin.

## Goals

- Enable `claude plugin install cc-configs@levx` as the entry point
- Deploy config files interactively via `/cc-configs:install`
- Allow selective component installation (CLAUDE.md, rules, hooks, settings)
- Keep `scripts/install.sh` usable standalone (no Claude dependency)

## Non-Goals

- No sync skill (existing `sync.sh` stays for manual use)
- No automatic install on plugin install (no postInstall hook)

---

## Repository Structure

```
claude-code-configs/
├── SKILL.md                          # Plugin manifest (marketplace entry point)
├── skills/
│   └── install/
│       └── SKILL.md                  # /cc-configs:install skill body
├── scripts/
│   └── install.sh                    # Refactored from install.sh (accepts --components arg)
├── CLAUDE.md
├── RTK.md
├── rules/
├── hooks/
├── settings.json.template
└── sync.sh                           # Unchanged, manual use only
```

---

## Plugin Manifest (root SKILL.md)

Minimal file for marketplace discovery:

```markdown
# cc-configs

Claude Code global configuration manager.

## Skills
- `install` — Deploy config files to ~/.claude (interactive)

## Usage
/cc-configs:install
```

---

## Install Skill Flow (`skills/install/SKILL.md`)

### Step 1: Detect plugin root

The skill reads `CLAUDE_PLUGIN_ROOT` to locate `scripts/install.sh`.

### Step 2: Component selection (AskUserQuestion, multiSelect)

Prompt: "어떤 컴포넌트를 설치할까요?"

| Option | Default |
|--------|---------|
| CLAUDE.md | ✅ selected |
| rules/ | ✅ selected |
| hooks/ | ☐ not selected |
| settings.json | ☐ not selected |

### Step 3: Hook selection (if hooks selected)

Prompt: "어떤 훅을 설치할까요?"

| Hook | Default |
|------|---------|
| bash-auto-allow | ✅ selected |
| git-guard | ✅ selected |
| rtk-rewrite | ☐ not selected (warns if RTK not installed) |

### Step 4: Execute install script

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/install.sh" \
  --components=claude,rules \
  --hooks=auto-allow,git-guard
```

### Step 5: Report results

- List of installed files
- Backup location (`~/.claude/backups/`)
- Warning if rtk-rewrite selected but `rtk` not in PATH

---

## scripts/install.sh Interface

Refactored from existing `install.sh` to accept arguments:

```bash
# Install all
./scripts/install.sh --components=claude,rules,hooks,settings

# Install specific components
./scripts/install.sh --components=claude,rules

# Install with specific hooks
./scripts/install.sh --components=claude,rules,hooks --hooks=auto-allow,git-guard

# Legacy: no args = install all (backwards compatible)
./scripts/install.sh
```

Internally, each component is handled by a function:
- `install_claude_md`
- `install_rules`
- `install_hooks <hook-list>`
- `install_settings`

Backup logic and merge logic remain unchanged.

---

## Marketplace Registration

Users add this repo as a marketplace source:

```bash
claude /plugin marketplace add https://github.com/levx/claude-code-configs
claude plugin install cc-configs@levx
```

Then deploy:

```bash
/cc-configs:install
```

---

## User Flow Summary

```
claude plugin install cc-configs@levx
         ↓
  (skill registered)
         ↓
/cc-configs:install
         ↓
  Select: ✅ CLAUDE.md ✅ rules ☐ hooks ☐ settings
         ↓
  scripts/install.sh --components=claude,rules
         ↓
  ~/.claude/CLAUDE.md, ~/.claude/rules/* installed
  Backup: ~/.claude/backups/config-YYYYMMDD-HHMMSS/
```
