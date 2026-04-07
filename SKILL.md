# cc-configs

Claude Code global configuration manager — installs CLAUDE.md, rules, hooks, and settings to `~/.claude`.

## Skills

- `install` — Interactive install of config files to `~/.claude`

## Quick Start

```bash
# Add marketplace (one time)
claude /plugin marketplace add https://github.com/levx/claude-code-configs

# Install plugin
claude plugin install cc-configs@levx

# Deploy configs interactively
/cc-configs:install
```

## Manual Install

```bash
git clone git@github.com:levx/claude-code-configs.git
cd claude-code-configs
./scripts/install.sh
```
