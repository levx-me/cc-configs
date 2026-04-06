# LLM Wiki

Recognize and operate the global wiki (`~/wiki/`) and project wikis (`{project}/wiki/`).

## Location

- **Global**: `~/wiki/` — personal knowledge base accessible from any project
- **Project**: `{cwd}/wiki/` — project-specific knowledge base (if present)

## Detection

1. `~/wiki/CLAUDE.md` exists → global wiki active
2. `{cwd}/wiki/CLAUDE.md` exists → project wiki active
3. Both can coexist — route based on user instruction

## Default Routing

- "add to wiki" / "save to wiki" → project wiki first (if exists), else global
- "global wiki" → explicitly targets `~/wiki/`
- "project wiki" → explicitly targets `{cwd}/wiki/`

## Operations

Read the wiki schema (`~/wiki/CLAUDE.md`) first, then follow its rules.

- **Ingest**: Add source → summary + update related pages + update index/log
- **Query**: Index → find pages → synthesize answer (save to synthesis if valuable)
- **Lint**: Check contradictions, stale content, orphans, missing cross-refs

## Cross-Wiki

- **Promote**: Project wiki → global wiki (knowledge elevation)
- **Import**: Global wiki → project wiki (knowledge retrieval)
- Update both index.md files on cross-wiki operations

## Project Wiki Bootstrap

When the user says "create a wiki for this project":

1. Create `{cwd}/wiki/` with directories: `raw/assets/`, `entities/`, `concepts/`, `sources/`, `synthesis/`
2. Copy wiki schema from `~/wiki/CLAUDE.md` as `{cwd}/wiki/CLAUDE.md` (adapt to project context)
3. Create symlink: `{cwd}/wiki/AGENTS.md → CLAUDE.md`
4. Create `index.md` and `log.md`
5. Add `.gitkeep` to empty directories
6. Append wiki reference to the project root instruction files:
   - **Guard**: First check if `## Wiki` section already exists in the file. If it does, skip — do not duplicate.
   - If `{cwd}/CLAUDE.md` exists → append wiki section (if not already present)
   - If `{cwd}/AGENTS.md` exists → append wiki section (if not already present)
   - If neither exists → create both with wiki instructions

Wiki section to append to project root:

```markdown
## Wiki

This project has a local wiki at `wiki/`. See `wiki/CLAUDE.md` for the schema.
Use the wiki for persistent knowledge: architecture decisions, research notes, entity tracking.
For cross-project knowledge, promote pages to the global wiki (`~/wiki/`).
```

## Format

- Obsidian-compatible: `[[wikilinks]]`, YAML frontmatter, `![[image]]`
- Filenames: lowercase kebab-case
- Tags: frontmatter `tags` array
- Always generate both `CLAUDE.md` and `AGENTS.md` (symlink) for cross-platform agent compatibility
