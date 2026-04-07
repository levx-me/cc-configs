# cc-configs

> Deploy levx's Claude Code global settings to any machine in seconds.

A Claude Code plugin that interactively installs CLAUDE.md, rules, hooks, and settings into `~/.claude`.

**[한국어 문서 →](./README.ko.md)**

---

## Installation

### As a Claude Code plugin (recommended)

Inside Claude Code:

```
/plugin marketplace add https://github.com/levx-me/cc-configs
/plugin install cc-configs@levx-me
/cc-configs:install
```

Select the components you want — they get deployed to `~/.claude` automatically.

---

### Manual install

```bash
git clone git@github.com:levx-me/cc-configs.git
cd cc-configs
./scripts/install.sh
```

Selective install:

```bash
./scripts/install.sh --components=claude,rules
./scripts/install.sh --components=hooks --hooks=auto-allow,git-guard
```

---

## What's included

### CLAUDE.md
Global Claude Code instructions. Includes the [oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode) orchestration block for automatic multi-agent workflows.

### rules/
Markdown rules automatically injected into every project.

| File | Contents |
|------|----------|
| `cli-checklist.md` | CLI tool building checklist |
| `readme-guide.md` | README writing guide |
| `refactor-safety.md` | Safe refactoring rules |
| `wiki.md` | Wiki writing guide |

### hooks/
Bash scripts that run on `PreToolUse` events.

| Hook | Behavior |
|------|----------|
| `bash-auto-allow` | Auto-allow Bash commands, blocking dangerous patterns (rm -rf, sudo, force push, etc.) |
| `git-guard` | Injects safety checklists before `git commit` and `git push` |
| `rtk-rewrite` | Transparently rewrites commands through RTK for token savings (requires RTK) |

### settings.json
Renders `settings.json.template` with your actual `~/.claude` path and smart-merges into your existing settings. Plugin-managed fields (`enabledPlugins`, `statusLine`, etc.) are always preserved.

---

## Updating

On a new machine or after pulling changes:

```bash
cd cc-configs && git pull && ./scripts/install.sh
```

Or if the plugin is installed:

```
/cc-configs:install
```

---

## Syncing local changes back

```bash
./sync.sh
git add -A && git commit -m "chore: sync local changes"
git push
```

---

## Optional dependencies

| Tool | Purpose | Install |
|------|---------|---------|
| [oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode) | Multi-agent orchestration | `claude plugin install oh-my-claudecode@omc` |
| [RTK](https://github.com/rtk-ai/rtk) | Token-saving CLI proxy (60–90% savings) | `cargo install rtk` |
| [jq](https://jqlang.github.io/jq/) | Required by hook scripts | `brew install jq` |

---

## Caveats

- Never commit secrets (`.mcp.json`, `.env`, etc.)
- `enabledPlugins`, `extraKnownMarketplaces`, and `statusLine` are managed by Claude Code — preserved on every install

---

## License

MIT
