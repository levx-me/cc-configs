# Pre-Commit: Never Commit These
If found in staged files, unstage and add to .gitignore.
- Secrets: .env, .env.*, *.pem, *.key, *.p12, *credentials*
- AI artifacts: CLAUDE.md, .claude/, AGENTS.md, .omc/, .cursorrules, .cursor/, .aider*, .github/copilot-instructions.md
- Dependencies: node_modules/, .venv/, venv/, __pycache__/, target/, vendor/, .gradle/, Pods/, .bundle/
- Build: dist/, build/, out/, .next/, *.pyc, *.o, *.so, *.dylib, *.class, *.jar
- OS/IDE: .DS_Store, Thumbs.db, .idea/, .vscode/ (unless shared), *.swp
- Logs/binaries: *.log, *.zip, *.tar.gz, *.dmg, *.iso
Verify: git diff --cached --name-only | grep -iE '\.env|\.pem|\.key|\.log|credentials|node_modules|__pycache__'
