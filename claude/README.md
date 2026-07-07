# Claude Toolkit — user-level

These items install into `~/.claude/` and are available in every project on the machine.

## Agents

Copy `agents/` → `~/.claude/agents/`.

- `analyze-jira-task` — pulls Jira, comments, linked issues, sub-tasks, and referenced Confluence context for an issue (read-only).
- `architectural-review` — ticket-aware branch review with Jira/Confluence context and Forge-focused checks.
- `branch-change-summary` — factual summary of what a branch implemented vs. what the ticket asked (no quality judgments).
- `jira-ears-requirements` — converts a Jira issue into an EARS requirements document at the project root.
- `worklog-writer` — splits a target number of hours into realistic Jira worklog entries from the diff and ticket.

## Skills

Copy `skills/` → `~/.claude/skills/`.

- `saasjet-coding-standards` — SaaSJet code conventions and the 15 mandatory development rules for TS/JS/React/Forge/ADS.
