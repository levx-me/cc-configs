#!/usr/bin/env bash
# Auto-allow most Bash commands, block dangerous patterns.
# Dangerous commands fall through (exit 0) so Claude Code prompts the user.

INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

[ -z "$CMD" ] && exit 0

# Block list: require manual approval
if echo "$CMD" | grep -qE '^\s*(rm\s+-rf|sudo\s|shutdown|reboot|mkfs|dd\s|:()\{|curl.*\|\s*(ba)?sh|wget.*\|\s*(ba)?sh|chmod\s+777|>\s*/dev/sd|git\s+push\s+.*--force|git\s+reset\s+--hard)'; then
  exit 0
fi

jq -n '{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow",
    "permissionDecisionReason": "bash-auto-allow"
  }
}'
