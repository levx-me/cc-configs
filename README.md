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
│   ├── refactor-safety.md
│   └── wiki.md
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
./scripts/install.sh                                        # Install all
./scripts/install.sh --components=claude,rules              # Selective
./scripts/install.sh --components=hooks --hooks=git-guard   # Specific hooks
```

**Components:** `claude`, `rules`, `hooks`, `settings`

**Hooks:** `auto-allow`, `git-guard`, `rtk-rewrite`

## Syncing local changes back to the repo

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
- `enabledPlugins`, `extraKnownMarketplaces`, `statusLine` are managed by Claude Code — preserved during merge

## License

MIT
