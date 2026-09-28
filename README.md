# AI Agent Toolkit

Personal, portable Claude Code toolkit — subagents, skills, and slash commands backed up here so they can be reinstalled on any device.

Two scopes are tracked:

- **`claude/`** — user-level items that live in `~/.claude/` (available in every project on the machine).
- **`projects/time-in-status/`** — items scoped to the `time-in-status` repo, meant for that project's `.claude/` folder.

## Contents

### User-level (`claude/`)

**Agents** (`claude/agents/` → `~/.claude/agents/`)

| Agent | Purpose |
|-------|---------|
| `analyze-jira-task` | Pull a Jira issue + comments, linked issues, sub-tasks, and referenced Confluence into a structured analysis (read-only). |
| `architectural-review` | Ticket-aware branch review with full Jira/Confluence context and Forge/Atlaskit-focused checks. |
| `branch-change-summary` | Factual "what the branch did vs. what the ticket asked" summary (no quality judgments). |
| `jira-ears-requirements` | Turn a Jira issue into an EARS requirements doc written to the project root. |
| `worklog-writer` | Split a target number of hours into realistic Jira worklog entries from the diff + ticket. |

**Skills** (`claude/skills/` → `~/.claude/skills/`)

| Skill | Purpose |
|-------|---------|
| `saasjet-coding-standards` | SaaSJet conventions + the 15 mandatory development rules for TS/JS/React/Forge/ADS. |
| `bitbucket-api` | Read Bitbucket Cloud (pipelines, step logs, PRs, commits) via the REST API instead of the browser. Needs `BITBUCKET_EMAIL` + `BITBUCKET_API_TOKEN` as user env vars — see "Bitbucket API token setup" below. |

> `~/.claude/skills/generate-ai-docs` was empty on this machine, so it is not tracked.

### Project-scoped: time-in-status (`projects/time-in-status/`)

**Skills** (`skills/` → `<repo>/.claude/skills/`) — 16 total

- `gen-context-templates` — template container for the `/gen-context` command (instructions + templates).
- `speckit-*` (15) — Spec Kit workflow skills: `agent-context-update`, `analyze`, `checklist`, `clarify`, `constitution`, `git-commit`, `git-feature`, `git-initialize`, `git-remote`, `git-validate`, `implement`, `plan`, `specify`, `tasks`, `taskstoissues`.

**Commands** (`commands/` → `<repo>/.claude/commands/`)

- `gen-context` — generate structured project documentation from codebase analysis.

## Install on another device

Clone the repo, then copy each scope to its target.

**User-level (all projects):**

```powershell
git clone https://github.com/VladBoyko11/ai-agent-toolkit.git
cd ai-agent-toolkit

# Agents and skills available in every project
Copy-Item .\claude\agents\* $env:USERPROFILE\.claude\agents\ -Recurse -Force
Copy-Item .\claude\skills\* $env:USERPROFILE\.claude\skills\ -Recurse -Force
```

**Project-scoped (into the time-in-status repo):**

```powershell
$repo = "C:\path\to\time-in-status"
Copy-Item .\projects\time-in-status\skills\*   "$repo\.claude\skills\"   -Recurse -Force
Copy-Item .\projects\time-in-status\commands\* "$repo\.claude\commands\" -Recurse -Force
```

On macOS/Linux use `cp -R ./claude/agents/* ~/.claude/agents/` etc.

## Bitbucket API token setup

The `bitbucket-api` skill needs two **user-level environment variables** — never commit the token itself, only these instructions.

1. Create an API token: Atlassian account → **Security** → **Create and manage API tokens** → **Create API token**. Give it repository/pipeline/PR read scopes (`read:repository:bitbucket`, `read:pipeline:bitbucket`, `read:pullrequest:bitbucket`); add matching `write:*` scopes only if you'll use write calls.
2. Set the two variables so every new shell picks them up.

**macOS (zsh, the default shell since Catalina):**

```bash
echo 'export BITBUCKET_EMAIL="you@saasjet.com"' >> ~/.zshrc
echo 'export BITBUCKET_API_TOKEN="paste-your-token-here"' >> ~/.zshrc
source ~/.zshrc
```

If your login shell is bash instead, append to `~/.bash_profile` (or `~/.bashrc`) the same way.

3. Verify (this only proves the vars are set — it never prints the token):

```bash
[ -n "$BITBUCKET_EMAIL" ] && [ -n "$BITBUCKET_API_TOKEN" ] && echo "both set" || echo "missing"
```

4. Restart Claude Code (or open a new terminal) so the new shell environment is picked up.

**Windows (PowerShell)** — same two variables, persisted per-user:

```powershell
[Environment]::SetEnvironmentVariable('BITBUCKET_EMAIL', 'you@saasjet.com', 'User')
[Environment]::SetEnvironmentVariable('BITBUCKET_API_TOKEN', (Read-Host 'Bitbucket API token'), 'User')
```

`Read-Host` prompts for the token separately so it never lands in shell history.

## Safety

Reusable instructions only. Never commit `.env` files, tokens, local auth, chat histories, caches, SQLite databases, or generated runtime state (see `.gitignore`). Tracked items may describe *where* runtime credentials live, but never store the credentials themselves.
