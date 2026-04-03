# Pre-Push Checklist
Fix any failures before pushing.

## Required files (repo root)
- README.md — badges, description, quick start, license section (English default)
- LICENSE — full text matching package manifest license field if present
- .gitignore — must exclude all patterns from pre-commit checklist; AI artifacts trackable only if team-agreed and secret-free

## Lock files (must be committed, not gitignored)
package.json→package-lock.json/yarn.lock/pnpm-lock.yaml | Cargo.toml→Cargo.lock (binaries only) | pyproject.toml→poetry.lock/uv.lock | go.mod→go.sum | Gemfile→Gemfile.lock | composer.json→composer.lock

## Verify
1. ls README.md LICENSE .gitignore
2. cat .gitignore — check exclusions
3. git ls-files | grep -iE '\.env|\.pem|\.key|\.log|credentials'
4. Lock file present if manifest exists
5. All pass → push
