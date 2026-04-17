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

## Step 2: Select plugins

Use AskUserQuestion (multiSelect: true):

**Question:** "Which plugins would you like to install?"

**Options:**
1. **oh-my-claudecode** — Multi-agent orchestration layer (value: `oh-my-claudecode`) — default selected
2. **caveman** — 65–75% response token savings (value: `caveman`) — default selected

Store selected values as PLUGINS (comma-joined). If none selected, set PLUGINS to empty string and exclude `plugins` from COMPONENTS.

## Step 3: Select components

Use AskUserQuestion (multiSelect: true):

**Question:** "Which components would you like to install?"

**Options:**
1. **rules/** — Auto-injected project rules (value: `rules`) — default selected
2. **hooks/** — PreToolUse bash hooks (value: `hooks`) — default selected
3. **settings.json** — Merge settings template (value: `settings`) — default selected

Store selected values as COMPONENTS (comma-joined). If PLUGINS is non-empty, append `plugins` to COMPONENTS.

If nothing selected at all (no plugins, no components), tell user "Nothing selected. Exiting." and stop.

## Step 4: Select hooks (only if hooks selected)

If `hooks` is in COMPONENTS, use AskUserQuestion (multiSelect: true):

**Question:** "Which hooks would you like to install?"

**Options:**
1. **bash-auto-allow** — Auto-allow Bash commands, blocking dangerous patterns (value: `auto-allow`) — default selected
2. **git-guard** — Injects safety checklists before git commit/push (value: `git-guard`) — default selected
3. **rtk-rewrite** — Transparently rewrites commands through RTK for token savings (value: `rtk-rewrite`)

Store selected values as HOOKS (comma-joined). If none selected, remove `hooks` from COMPONENTS.

## Step 5: Run install script

Construct the command from user selections and run it:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/install.sh" \
  --components=<COMPONENTS> \
  --hooks=<HOOKS> \
  --plugins=<PLUGINS>
```

Example (all selected):
```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/install.sh" \
  --components=rules,hooks,settings,plugins \
  --hooks=auto-allow,git-guard \
  --plugins=oh-my-claudecode,caveman
```

If `hooks` is not in COMPONENTS, omit the `--hooks` flag entirely.
If PLUGINS is empty, omit the `--plugins` flag entirely.

## Step 6: Report results

Display the install script output to the user.

If rtk-rewrite was selected and `rtk` is not in PATH, remind:
```
RTK not installed: run cargo install rtk
https://github.com/rtk-ai/rtk
```

Tell user to **restart Claude Code** for hooks changes to take effect.
