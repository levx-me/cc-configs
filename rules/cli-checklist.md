---
description: Checklist for building agent-friendly CLI tools
globs:
  - "**/cli/**"
  - "**/bin/**"
  - "**/commands/**"
  - "**/cmd/**"
---

# Quick Reference Checklist when building a CLI tool that agents will use

[ ]  --json flag for structured output
[ ]  JSON to stdout, messages to stderr
[ ]  Meaningful exit codes (not just 0/1)
[ ]  Idempotent operations (or clear conflict handling)
[ ]  Comprehensive --help with examples
[ ]  --dry-run for destructive commands
[ ]  --yes/--force to bypass prompts
[ ]  --quiet for pipe-friendly bare output
[ ]  Consistent field names and types across commands
[ ]  Consistent noun-verb hierarchy (e.g., `noun verb`)
[ ]  Actionable error messages with error codes
[ ]  Batch operations for bulk work
[ ]  Non-interactive TTY detection
