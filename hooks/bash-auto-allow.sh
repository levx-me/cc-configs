#!/usr/bin/env bash
# Auto-allow most Bash commands.
# Commands that modify/delete system files fall through (exit 0) → Claude Code prompts user.
# Cross-platform: macOS, Linux, Windows (Git Bash / WSL)

INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

[ -z "$CMD" ] && exit 0

# Helper: ERE match (no -P, compatible with macOS/Linux/Git Bash grep)
matches() { echo "$CMD" | grep -qE "$1"; }

# System paths to protect (macOS + Linux)
is_system_path() {
  echo "$1" | grep -qE '^/(etc|bin|sbin|System|Library|private/etc|private/var|dev/(sd|disk)|usr/(?!local))'
}

# --- Block rules (exit 0 = Claude Code asks user) ---

# 1. sudo / runas (Windows)
matches '(^|;|&&|\|\|)[[:space:]]*(sudo|runas)[[:space:]]' && exit 0

# 2. Destructive system commands
matches '(^|;|&&|\|\|)[[:space:]]*(shutdown|reboot|halt|poweroff|init[[:space:]]+0)[[:space:]]' && exit 0
matches '(^|;|&&|\|\|)[[:space:]]*(mkfs|fdisk|parted|gdisk)[[:space:]]' && exit 0
matches '(^|;|&&|\|\|)[[:space:]]*diskutil[[:space:]]+(erase|reformat|zeroDisk|secureErase)' && exit 0
matches '(^|;|&&|\|\|)[[:space:]]*dd[[:space:]]' && exit 0

# 3. Fork bomb
matches ':\(\)\{' && exit 0

# 4. Piped remote execution
matches '(curl|wget)[^|]*\|[[:space:]]*(ba)?sh' && exit 0

# 5. Git safety
matches 'git[[:space:]]+push[[:space:]].*--force' && exit 0
matches 'git[[:space:]]+reset[[:space:]]+--hard' && exit 0

# 6. Write/delete ops targeting system paths
WRITE_OPS_RE='(^|;|&&|\|\|)[[:space:]]*(rm|rmdir|mv|cp|chmod|chown|chflags|ln|truncate|tee|install)[[:space:]]'
SYSTEM_PATHS_RE='[[:space:]](/etc/|/private/etc/|/bin/|/sbin/|/System/|/Library/|/private/var/|/dev/sd|/dev/disk)'

if matches "$WRITE_OPS_RE"; then
  # Block if targeting system paths
  matches "$SYSTEM_PATHS_RE" && exit 0
  # Block /usr/ unless /usr/local/
  if matches '[[:space:]]/usr/' && ! matches '[[:space:]]/usr/local/'; then
    exit 0
  fi
fi

# 7. Redirection into system paths
REDIRECT_RE='>+[[:space:]]*(/(etc|bin|sbin|System|Library|private/(etc|var))/)'
matches "$REDIRECT_RE" && exit 0
# Redirection into /usr/ but not /usr/local/
if matches '>+[[:space:]]*/usr/' && ! matches '>+[[:space:]]*/usr/local/'; then
  exit 0
fi

# Windows: block writes to C:\Windows, C:\System32 etc (Git Bash paths)
matches '(^|;|&&|\|\|)[[:space:]]*(rm|del|rmdir|copy|move|icacls)[[:space:]].*[Cc]:\\(Windows|System32|Program Files)' && exit 0
matches '>+[[:space:]]*[Cc]:\\(Windows|System32)' && exit 0

# --- Auto-allow everything else ---
jq -n '{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow",
    "permissionDecisionReason": "bash-auto-allow: not a system-file operation"
  }
}'
