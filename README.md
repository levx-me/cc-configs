# Claude Code Configs

A repository for managing and sharing Claude Code global settings (`~/.claude`).

## Structure

```
├── CLAUDE.md                  # Global instructions (includes OMC orchestration)
├── RTK.md                     # RTK token-saving CLI guide
├── rules/
│   ├── cli-checklist.md       # CLI tool building checklist
│   ├── readme-guide.md        # README writing guide
│   └── refactor-safety.md     # Refactoring safety rules
├── hooks/
│   ├── bash-auto-allow.sh     # Auto-allow Bash commands (blocks dangerous patterns)
│   ├── git-guard-hook.sh      # Injects checklists on git commit/push
│   ├── rtk-rewrite.sh         # RTK token-saving auto-rewrite
│   ├── pre-commit-checklist.md
│   └── pre-push-checklist.md
├── settings.json.template     # Settings template (with path placeholders)
├── install.sh                 # Install script
└── sync.sh                    # Reverse sync script
```

## Quick Start

```bash
git clone https://github.com/xd-protocol/claude-code-configs.git
cd claude-code-configs
./install.sh
```

`install.sh` performs the following:

1. Backs up existing settings to `~/.claude/backups/`
2. Creates **symlinks** for `CLAUDE.md`, `RTK.md`, `rules/`, `hooks/` → `~/.claude`
3. Renders `settings.json.template` with path substitution and **merges** into `~/.claude/settings.json` (preserving existing plugin settings)

## Dependencies (Optional)

These settings work fully when combined with the tools below.
**Always install via official channels.** This repo only manages configuration, not tool installation.

| Tool | Purpose | Install |
|------|---------|---------|
| [oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode) | Multi-agent orchestration | `claude plugin install oh-my-claudecode@omc` |
| [RTK](https://github.com/rtk-ai/rtk) | Token-saving CLI proxy | `cargo install rtk` |
| [claude-mem](https://github.com/thedotmack/claude-mem) | Cross-session memory | `claude plugin install claude-mem@thedotmack` |
| [jq](https://jqlang.github.io/jq/) | Hook script dependency | `brew install jq` |

> **Install order:** Install dependencies first → run `./install.sh`. Plugin-managed fields (`enabledPlugins`, `statusLine`, etc.) in `settings.json` are preserved during merge.

## Workflow

### Syncing local changes back to the repo

```
Edit/test settings locally
    │
    ├─ Modified rules, hooks, CLAUDE.md, or RTK.md
    │   └→ Already reflected in repo (symlinked)
    │      git add && git commit
    │
    └─ Modified settings.json
        └→ ./sync.sh && git add && git commit
```

`sync.sh` strips plugin-managed fields from `~/.claude/settings.json` and replaces absolute paths with `{{CLAUDE_HOME}}` to update `settings.json.template`.

### Syncing to another machine

```bash
cd claude-code-configs
git pull
./install.sh
```

## Customization

### settings.json.template

`{{CLAUDE_HOME}}` is automatically replaced with `~/.claude` at install time.

Fields you may want to customize:

- **`permissions.allow`** — Auto-allowed tool/command patterns. Add or remove domains and commands for your projects.
- **`permissions.defaultMode`** — `"acceptEdits"` (auto-approve file edits) or `"default"` (confirm all edits)
- **`hooks`** — Add or remove hook scripts. Place new hooks in the `hooks/` directory and register them here.
- **`language`** — Claude response language
- **`effortLevel`** — `"high"`, `"medium"`, or `"low"`

### rules/

Add `.md` files to the `rules/` directory and Claude Code will automatically pick them up. One file = one rule.

### hooks/

To add a new hook script:

1. Create the script in `hooks/` (must be `chmod +x`)
2. Register it in the `hooks` section of `settings.json.template`
3. Re-run `./install.sh` or manually create a symlink

## Caveats

- **No secrets**: Never commit files containing tokens or keys (`.mcp.json`, `.env`, etc.).
- **Absolute paths**: `settings.json` contains machine-specific absolute paths. Always use the `{{CLAUDE_HOME}}` placeholder in `settings.json.template`.
- **Plugin settings**: `enabledPlugins`, `extraKnownMarketplaces`, and `statusLine` should be managed by official plugin installation on each machine.

## License

MIT
