---
name: gen-context-templates
description: Template container for the /gen-context command. Do not invoke directly — use the command instead.
user-invocable: false
---

# Generate Project Docs — Templates

This skill directory holds templates used by the `/gen-context` command (which also generates AGENTS.md files).

- `/gen-context` instructions: `.claude/commands/gen-context.md`

## Available Templates

| Template | Used By | Purpose |
|----------|---------|---------|
| `templates/project-context.md` | `/gen-context` | Project overview, tech stack, domain concepts |
| `templates/architecture.md` | `/gen-context` | System architecture, data flow, deployment |
| `templates/conventions.md` | `/gen-context` | Code style, naming, TypeScript/React patterns |
| `templates/development-guide.md` | `/gen-context` | Development rules, workflows, setup |
| `templates/mcp.md` | `/gen-context` | MCP servers configuration reference |
| `templates/root-agents.md` | `/gen-context` | Root AGENTS.md navigation hub (CLAUDE.md symlinks to it) |
| `templates/agents.md` | `/gen-context` | Workspace-level AGENTS.md for monorepo packages |
| `templates/review-agent.md` | `/gen-context` | Rovo Dev AI code review instructions (`.rovodev/.review-agent.md`) |
| `templates/review-agent-placeholders.md` | `/gen-context` | Placeholder filling instructions for `review-agent.md` |
