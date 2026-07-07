# time-in-status — project-scoped toolkit

Items scoped to the `time-in-status` repo. Install into that repo's `.claude/` folder (not `~/.claude/`).

## Skills → `<repo>/.claude/skills/`

- `gen-context-templates` — template container for the `/gen-context` command (instructions + templates; not invoked directly).
- `speckit-*` (15) — Spec Kit workflow skills:
  `agent-context-update`, `analyze`, `checklist`, `clarify`, `constitution`,
  `git-commit`, `git-feature`, `git-initialize`, `git-remote`, `git-validate`,
  `implement`, `plan`, `specify`, `tasks`, `taskstoissues`.

## Commands → `<repo>/.claude/commands/`

- `gen-context` — generate structured project documentation from codebase analysis.

## Install

```powershell
$repo = "C:\path\to\time-in-status"
Copy-Item .\skills\*   "$repo\.claude\skills\"   -Recurse -Force
Copy-Item .\commands\* "$repo\.claude\commands\" -Recurse -Force
```
