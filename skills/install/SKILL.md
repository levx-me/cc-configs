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
3. **hooks/** — PreToolUse bash hooks (value: `hooks`) — default selected
4. **settings.json** — Merge settings template (value: `settings`) — default selected

Store selected values as COMPONENTS (comma-joined, e.g. `claude,rules`).

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

Construct the command from user selections and run it:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/install.sh" \
  --components=<COMPONENTS> \
  --hooks=<HOOKS>
```

Example (CLAUDE.md + rules + hooks with auto-allow and git-guard):
```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/install.sh" \
  --components=claude,rules,hooks \
  --hooks=auto-allow,git-guard
```

If `hooks` is not in COMPONENTS, omit the `--hooks` flag entirely.

## Step 5: Report results

Display the install script output to the user.

If rtk-rewrite was selected and `rtk` is not in PATH, remind:
```
RTK 미설치: cargo install rtk 로 설치하세요.
https://github.com/rtk-ai/rtk
```

Tell user to **restart Claude Code** for CLAUDE.md and hooks changes to take effect.
