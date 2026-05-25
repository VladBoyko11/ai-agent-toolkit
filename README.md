# AI Agent Toolkit

Personal Claude skills toolkit. This repository stores portable Claude skills that can be copied into the user-level Claude configuration directory.

## Contents

- `claude/skills/analyze-jira-task`
- `claude/skills/architectural-review`

The local `~/.claude/skills/generate-ai-docs` directory was empty when this repository was initialized, so it is not tracked.

## Install

Copy the tracked skills into Claude's user-level skills directory:

```powershell
Copy-Item .\claude\skills\* $env:USERPROFILE\.claude\skills\ -Recurse -Force
```

## Safety

This repo should contain reusable instructions only. Do not commit `.env` files, tokens, local auth files, chat histories, caches, SQLite databases, or generated runtime state.

The tracked skills may describe where runtime credentials live, but the credentials themselves are not stored here.