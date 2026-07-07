---
description: Generate structured project documentation based on codebase analysis
allowed-tools: Read, Glob, Grep, Bash, Write, Edit, Task, mcp__context7__resolve-library-id, mcp__context7__query-docs, mcp__forge__search-forge-docs
---

# Generate Project Documentation Command

This command generates structured project documentation based on automatic codebase analysis, including workspace-level AGENTS.md files.

By default, it generates all documents. You can add a free-text prompt after the command to guide what to focus on, update, or regenerate (e.g., `/gen-context update architecture and conventions` or `/gen-context focus on the new auth module`).

**Prompt**: $ARGUMENTS

## Instructions

When the user invokes this command, follow these phases:

---

## File Exclusion Rules

All exclusion rules are documented in `.claude/skills/gen-context-templates/instructions/rules.md`. Read that file at the start and apply those rules to ALL phases — every Glob, Grep, Read, and Task agent prompt.

---

## Phase 1: Project Analysis

### 1.1 Discover Existing Documentation

Search for existing documentation: README.md, `docs/` directory, `doc/` directory (includes previously generated files like `doc/architecture.md`, `doc/conventions.md`, `doc/development-guide.md`, `doc/project-context.md`), AGENTS.md, CLAUDE.md, MCP.md, `*/AGENTS.md`. Read each found file. Use as primary source of truth — do NOT contradict existing docs.

### 1.2 Detect Project Type and Tech Stack

Read `package.json` to detect dependencies, scripts, project name/description.

### 1.3 Analyze Project Structure

Identify project type: single project (`src/`), monorepo (`apps/`, `packages/`, `shared/`), fullstack (`frontend/`, `backend/`), workspaces in `package.json`.

### 1.4 Detect Conventions

Search for config files: `**/eslint*`, `**/prettier*`, `**/tsconfig*.json`. Check for shared ESLint presets (if any). Note preset locations and lint command — do NOT list individual rules.

### 1.5 Detect Frameworks and Libraries

From package.json: frontend (React, Vue, etc.), backend (Express, Forge, etc.), build (Vite, Webpack, etc.), testing (Jest, Vitest, etc.), state management.

### 1.6 Detect Stack Migration

Check for multiple technology generations (e.g., Vue + React, Express + Forge). If found, identify which is modern and which is legacy.

### 1.7 MCP Convention Verification (Optional)

If relevant MCP servers are available, use them to verify detected conventions:
- Context7: `mcp__context7__resolve-library-id` → `mcp__context7__query-docs`
- Forge: `mcp__forge__search-forge-docs` (if `manifest.yml`/`manifest.yaml` detected)

---

## Phase 2: Context Setup

### 2.0 Initialize Context File

Create (or overwrite) `.claude/memory/docs-generation-context.md` with header:

```markdown
# Documentation Generation Context
```

### 2.1 Determine Docs Folder & Create Analysis Summary

Determine the docs folder: look for an existing directory that holds project documentation (e.g., `doc/`). Use its name as the docs folder value for all document output paths in later phases. Default to `doc` if none exists.

Compile a **compact** structured summary. Use this exact format — no prose, no raw data:

```
Project: <name> | Type: monorepo | Workspaces: <count>
Modern: <stack> | Legacy: <stack> | Migration: yes|no
Key deps: <10 most important, comma-separated>
Build: <tool> | Test: <framework> | Lint: <config>
Docs folder: <detected docs directory name>
Docs found: <file paths, comma-separated>
MCP: <servers configured>
Platform: <detected platform(s)>
```

Save this summary to the context file — it will be passed to Task agents in later phases.

> **CRITICAL**: When building Task agent prompts in ALL subsequent phases, replace every `<docs-folder>` with the actual docs folder value determined above.

### 2.2 Read Shared Resources

Read these files **once** in the main context (they will be referenced by path in Task agent prompts):

1. `.claude/skills/gen-context-templates/instructions/rules.md` — shared rules
2. `.claude/skills/gen-context-templates/instructions/development-guide.md` — conditional rules table

---

## Phase 3: Document Generation (Parallel Pairs)

Generate documents using Task agents in **parallel pairs**. Each pair launches 2 Task agents simultaneously in a **single message**, waits for both to complete, then proceeds to the next pair.

> **CRITICAL**: Each Task agent receives the compact project summary and performs its own codebase analysis. The main context acts as orchestrator only.

Use the user's free-text prompt ($ARGUMENTS) to determine focus: which documents to generate or update, which areas to emphasize, etc. If no prompt is provided, generate all documents.

### 3.1 Sequential: .mcp.json → MCP.md

> **Note**: These run sequentially because MCP.md documents the `.mcp.json` configuration and must read the up-to-date file.

**Step 1 — .mcp.json** (`subagent_type: "general-purpose"`, `max_turns: 8`):

```
Create `.mcp.json` MCP servers configuration for the project at `<project-root>`.

Context: <paste compact summary from 2.1>

Steps:
1. Read shared rules: `.claude/skills/gen-context-templates/instructions/rules.md`
2. Check if `.mcp.json` already exists — if so, read it
3. Determine which MCP servers to configure based on the project's platform and dependencies:
   - context7 (always): `{"type": "http", "url": "https://mcp.context7.com/mcp"}`
   - forge (if Atlassian Forge detected): `{"type": "http", "url": "https://mcp.atlassian.com/v1/forge/mcp"}`
4. Write `.mcp.json` with the configured servers
5. Return ONLY this JSON:

{"file": ".mcp.json", "status": "created | updated"}

Follow file exclusion rules from `.claude/skills/gen-context-templates/instructions/rules.md`.
```

After `.mcp.json` agent completes, launch Step 2:

**Step 2 — MCP.md** (`subagent_type: "general-purpose"`, `max_turns: 10`):

```
Generate `MCP.md` for the project at `<project-root>`.

Context: <paste compact summary from 2.1>

Steps:
1. Read shared rules: `.claude/skills/gen-context-templates/instructions/rules.md`
2. Read template: `.claude/skills/gen-context-templates/templates/mcp.md`
3. Read `.mcp.json` — it has just been created/updated in the previous step. Document the actual configuration: transport type, server URLs, and any custom settings
4. Read `package.json` to identify key dependencies for the "Relevant libraries" section
5. Check if `apps/forge/manifest.yml` or `apps/forge/manifest.yaml` exists (for Forge server inclusion)
6. Fill all template placeholders (templates contain HTML comments with filling guidance)
7. Write `MCP.md` in the project root
8. Return ONLY this JSON:

{"file": "MCP.md", "status": "created | updated"}

Follow file exclusion rules from `.claude/skills/gen-context-templates/instructions/rules.md`.
```

### 3.2 Pair 2: architecture.md + conventions.md

Launch 2 Task agents in parallel:

**Agent A — architecture.md** (`subagent_type: "general-purpose"`, `max_turns: 12`):

```
Generate `<docs-folder>/architecture.md` for the project at `<project-root>`.

Context: <paste compact summary from 2.1>

Steps:
1. Read shared rules: `.claude/skills/gen-context-templates/instructions/rules.md`
2. Read template: `.claude/skills/gen-context-templates/templates/architecture.md`
3. Read `package.json` for workspaces, scripts, and project structure
4. Read existing project documentation: `README.md` and any docs directories or files in the project root (if they exist) — use as source of truth
5. Explore project structure: list top-level dirs (`apps/`, `shared/`, `packages/`, `aws/`, `presets/`, `config/`, `docs/`)
6. For Forge apps: read `apps/forge/manifest.yml` to discover modules, storage entities, permissions
7. Analyze key entry points to understand system boundaries and data flow
8. Fill all template placeholders (templates contain HTML comments with filling guidance)
9. Create `<docs-folder>/` directory if needed, then write `<docs-folder>/architecture.md`
10. Return ONLY this JSON:

{"file": "<docs-folder>/architecture.md", "status": "created | updated"}

Follow file exclusion rules from `.claude/skills/gen-context-templates/instructions/rules.md`.
```

**Agent B — conventions.md** (`subagent_type: "general-purpose"`, `max_turns: 12`):

```
Generate `<docs-folder>/conventions.md` for the project at `<project-root>`.

Context: <paste compact summary from 2.1>

Steps:
1. Read shared rules: `.claude/skills/gen-context-templates/instructions/rules.md`
2. Read template: `.claude/skills/gen-context-templates/templates/conventions.md`
3. Read `package.json` for dependencies and scripts
4. Read existing project documentation: `README.md` and any docs directories or files in the project root (if they exist) — use as source of truth
5. Detect linting setup: check for `**/eslint*` configs, shared presets in `presets/eslint/`
6. Analyze naming conventions from source files (component names, hook names, file structure)
7. Check TypeScript config: `tsconfig*.json` for strict mode, path aliases
8. Check testing setup: Vitest config, Jest config, test file patterns
9. Fill all template placeholders (templates contain HTML comments with filling guidance)
10. Create `<docs-folder>/` directory if needed, then write `<docs-folder>/conventions.md`
11. Return ONLY this JSON:

{"file": "<docs-folder>/conventions.md", "status": "created | updated"}

Follow file exclusion rules from `.claude/skills/gen-context-templates/instructions/rules.md`.
```

### 3.3 Pair 3: development-guide.md + project-context.md

Launch 2 Task agents in parallel:

**Agent A — development-guide.md** (`subagent_type: "general-purpose"`, `max_turns: 12`):

```
Generate `<docs-folder>/development-guide.md` for the project at `<project-root>`.

Context: <paste compact summary from 2.1>

Steps:
1. Read shared rules: `.claude/skills/gen-context-templates/instructions/rules.md`
2. Read conditional rules table: `.claude/skills/gen-context-templates/instructions/development-guide.md`
3. Read template: `.claude/skills/gen-context-templates/templates/development-guide.md`
4. Read `package.json` for scripts, engines, packageManager
5. Read existing docs: `README.md` (if exists) — use as source of truth for setup/workflow
6. Evaluate each conditional rule from the rules table against the codebase (check dependencies, grep for patterns)
7. Include only rules whose conditions are TRUE
8. Fill all template placeholders (templates contain HTML comments with filling guidance)
9. Create `<docs-folder>/` directory if needed, then write `<docs-folder>/development-guide.md`
10. Return ONLY this JSON:

{"file": "<docs-folder>/development-guide.md", "status": "created | updated", "rulesCount": <number>}

Follow file exclusion rules from `.claude/skills/gen-context-templates/instructions/rules.md`.
```

**Agent B — project-context.md** (`subagent_type: "general-purpose"`, `max_turns: 12`):

```
Generate `<docs-folder>/project-context.md` for the project at `<project-root>`.

Context: <paste compact summary from 2.1>

Steps:
1. Read shared rules: `.claude/skills/gen-context-templates/instructions/rules.md`
2. Read template: `.claude/skills/gen-context-templates/templates/project-context.md`
3. Read `package.json` for project name, description, dependencies
4. Read existing docs: `README.md` (if exists) — use as source of truth for features and description
5. Identify key features, domain concepts, and external integrations from the codebase
6. Determine tech stack tables (modern/legacy/shared if migration detected)
7. Fill all template placeholders (templates contain HTML comments with filling guidance)
8. Create `<docs-folder>/` directory if needed, then write `<docs-folder>/project-context.md`
9. Return ONLY this JSON:

{"file": "<docs-folder>/project-context.md", "status": "created | updated"}

Follow file exclusion rules from `.claude/skills/gen-context-templates/instructions/rules.md`.
```

### 3.4 Update Context File

After ALL 3 pairs complete, append to `.claude/memory/docs-generation-context.md` under `## Generated Documents`:

```markdown
## Generated Documents

- .mcp.json
- MCP.md
- <docs-folder>/architecture.md
- <docs-folder>/conventions.md
- <docs-folder>/development-guide.md
- <docs-folder>/project-context.md
```

Wait for all 3 parallel pairs to complete, then print: "Phase 3 done: 6 files generated (3 parallel pairs)". Proceed to Phase 4 only after all Phase 3 agents have finished.

---

## Phase 4: Rovo Dev Review Agent Instructions

Generate `.rovodev/.review-agent.md` — custom code review instructions for Rovo Dev AI code review agent.

> **CRITICAL — Context Isolation**: Launch a single Task agent.

### 4.0 Task Agent Delegation

Launch a single Task agent (`subagent_type: "general-purpose"`, **`max_turns: 15`**) with this prompt:

```
Generate `.rovodev/.review-agent.md` for the project at `<project-root>`.

Context: <paste compact summary from 2.1>

Steps:
1. Read shared rules: `.claude/skills/gen-context-templates/instructions/rules.md`
2. Read `<docs-folder>/development-guide.md` (if it exists) to extract development rules. If missing, derive rules directly from codebase analysis (read source files, configs, package.json)
3. Read `<docs-folder>/conventions.md` (if it exists) to extract code conventions. If missing, derive conventions directly from codebase analysis (lint configs, tsconfig, source patterns)
4. Read `<docs-folder>/architecture.md` (if it exists) to extract architecture patterns for {{ARCHITECTURE_RULES}}. If missing, derive from codebase analysis
5. Read `.claude/skills/gen-context-templates/instructions/development-guide.md` — the conditional rules table contains the `Rovo Dev Instruction Pattern` column (single source of truth for project-specific review rules)
6. Read `.claude/skills/gen-context-templates/templates/review-agent-placeholders.md` for placeholder instructions
7. Read template: `.claude/skills/gen-context-templates/templates/review-agent.md`
8. Create `.rovodev/` directory if needed
9. Fill all placeholders using Rovo Dev format: "When you spot [problem], suggest [solution] instead of [bad pattern]". For {{PROJECT_SPECIFIC_RULES}}, use the `Rovo Dev Instruction Pattern` column from the rules table (step 5)
10. Write `.rovodev/.review-agent.md`
11. Return ONLY this JSON:

{"file": ".rovodev/.review-agent.md", "status": "created | updated", "sections": [...], "summary": "one-line"}

Do NOT read individual workspace AGENTS.md files — use development-guide.md, conventions.md, and architecture.md.
Follow file exclusion rules from `.claude/skills/gen-context-templates/instructions/rules.md`.
```

### 4.1 Collect Summary

After the Task agent completes:

1. Collect the JSON summary
2. Append to `.claude/memory/docs-generation-context.md` under `## Rovo Dev`:

```markdown
## Rovo Dev
- **Status**: created | updated
- **Sections**: Section1, Section2, ...
- **Summary**: One-line description
```

3. Print summary (e.g., "Phase 4 done: .rovodev/.review-agent.md generated")
4. Proceed to Phase 5

---

## Phase 5: Generate Workspace AGENTS.md Files

Generate `AGENTS.md` files for monorepo workspaces.

### 5.0 Prepare Context File

Read `.claude/memory/docs-generation-context.md` and append `## Workspace Summaries` header. If the file does not exist yet, create it first.

### 5.1 Discover Workspaces

Read root `package.json` → `workspaces` field. For each workspace directory, confirm `package.json` exists and read package name/description.

### 5.2 Context Management: Batched Parallel Processing

> **CRITICAL — BATCH SIZE = 4 WORKSPACES MAX IN PARALLEL**
>
> Process workspaces in **batches of 4**. Each batch launches up to 4 Task agents
> simultaneously in a **single message**. Wait for the entire batch to complete before
> starting the next one.
>
> The main conversation acts **strictly as an orchestrator** — it MUST NOT read workspace
> source code, grep for usage, or store code snippets.

#### Processing Algorithm

```
batches = split workspaces into groups of 4
for each batch in batches:
    1. Launch up to 4 Task agents IN PARALLEL (one per workspace, single message)
    2. Wait for ALL agents in the batch to complete
    3. Collect JSON summaries from each agent
    4. Append all summaries to .claude/memory/docs-generation-context.md
    5. Print short batch summary (e.g., "Batch 2/10 done: shared/common, shared/configs, ...")
    6. Proceed to next batch
```

### 5.3 Task Agent Contract (Workspace AGENTS.md)

For each workspace, launch a Task agent (`subagent_type: "general-purpose"`, **`max_turns: 15`**) with this prompt:

```
Analyze `<workspace-path>` and generate its AGENTS.md file.

Context: <paste compact summary from 2.1>

Steps:
1. Read shared rules: `.claude/skills/gen-context-templates/instructions/rules.md`
2. Read instructions: `.claude/skills/gen-context-templates/instructions/workspace-agents.md`
3. Read `<workspace-path>/package.json`
4. Analyze source following the instructions (max 5 key files)
5. For shared/packages: find up to 3 real usage examples in apps/
6. Read template: `.claude/skills/gen-context-templates/templates/agents.md`
7. Write `<workspace-path>/AGENTS.md`
8. Return ONLY this JSON:

{"workspace": "<path>", "package": "<name>", "status": "created | updated | skipped", "sections": [...], "keyExports": [...]}

Follow file exclusion rules from `.claude/skills/gen-context-templates/instructions/rules.md`.
Do NOT return code snippets or analysis — ONLY the JSON above.
```

### 5.4 Progressive Analysis Rule

If a workspace is large: analyze modules incrementally, summarize intermediate findings, continue using summaries instead of raw file contents.

### 5.5 Main Context Memory Discipline

#### What the Main Context May Store

Only structured JSON summaries per workspace.

#### What the Main Context MUST NEVER Store

Source code, usage examples, directory structures, detailed analysis, or large text blocks.

#### Save Summaries to Memory (after EACH batch)

After each batch completes, append all summaries to `.claude/memory/docs-generation-context.md` under `## Workspace Summaries`:

```markdown
### <workspace-path>
- **Package**: <name>
- **Status**: created | updated | skipped
- **Sections**: Architecture, Public API, ...
- **Key Exports**: ExportA, ExportB, ExportC
```

Discard transient reasoning. Only then proceed to next batch.

After ALL batches done, proceed to Phase 6.

---

## Phase 6: Root AGENTS.md Generation

Generate `AGENTS.md` in the project root. `CLAUDE.md` is created as a symlink pointing to `AGENTS.md`.

> **CRITICAL — Context Isolation**: Launch a single Task agent that performs all reading, analysis, and generation.

> **Important**: Root `AGENTS.md` = navigation hub with rules and doc links. Workspace `AGENTS.md` = package-specific details.

### 6.0 Task Agent Delegation

Launch a single Task agent (`subagent_type: "general-purpose"`, **`max_turns: 15`**) with this prompt:

```
Generate root `AGENTS.md` and create `CLAUDE.md` symlink for the project at `<project-root>`.

Context: <paste compact summary from 2.1>

Steps:
1. Read shared rules: `.claude/skills/gen-context-templates/instructions/rules.md`
2. Read `.claude/memory/docs-generation-context.md` for workspace summaries
3. Use the `Docs folder` value from the compact summary for all `{{DOCS_FOLDER}}` placeholders in the template
4. Read `<docs-folder>/development-guide.md` (if it exists) to extract all Development Rules for {{TOP_RULES_SUMMARY}}. If the file is missing, derive rules directly from codebase analysis
5. Read template: `.claude/skills/gen-context-templates/templates/root-agents.md` (contains HTML comments with filling guidance)
6. Fill all placeholders (including `{{DOCS_FOLDER}}`) and write `AGENTS.md`
7. Create symlink: `cd <project-root> && ln -sf AGENTS.md CLAUDE.md`
8. Return ONLY this JSON:

{"file": "AGENTS.md", "symlink": "CLAUDE.md → AGENTS.md", "status": "created | updated", "rulesCount": <number>, "summary": "one-line"}

Do NOT read individual workspace AGENTS.md files — the context file has all needed summaries. Derive AGENTS.md paths from workspace paths in the context file by appending `/AGENTS.md` to each workspace with status "created" or "updated". To discover any pre-existing AGENTS.md files not tracked in the context, use `Glob` for `*/AGENTS.md`.
Follow file exclusion rules from `.claude/skills/gen-context-templates/instructions/rules.md`.
```

### 6.1 Collect Summary

After the Task agent completes:

1. Collect the JSON summary
2. Append to `.claude/memory/docs-generation-context.md` under `## Root AGENTS.md`:

```markdown
## Root AGENTS.md
- **Status**: created | updated
- **Rules Count**: <number>
- **Summary**: One-line description
```

3. Print summary (e.g., "Phase 6 done: root AGENTS.md generated with N rules")
4. Proceed to Cleanup

---

## Cleanup

After all documentation is generated, delete `.claude/memory/docs-generation-context.md` — it is a temporary working file.

---

## Output Summary

After generation, report:

```
Generated documentation

Existing docs discovered:
- <list of existing documentation files found>

Files created:
- .mcp.json (MCP servers configuration)
- MCP.md (in project root)
- <docs-folder>/architecture.md
- <docs-folder>/conventions.md
- <docs-folder>/development-guide.md
- <docs-folder>/project-context.md
- AGENTS.md (in project root — navigation hub)
- CLAUDE.md → AGENTS.md (symlink)
- .rovodev/.review-agent.md (Rovo Dev code review instructions)

Workspace AGENTS.md files created/updated:
- shared/<module-name>/AGENTS.md
- apps/<app-name>/AGENTS.md
- ...
Total: N workspace AGENTS.md files
```

> **Note**: `MCP.md` and `AGENTS.md` are generated in the project root (not in `<docs-folder>/`).
> **Note**: `CLAUDE.md` is a symlink to `AGENTS.md` — both files always have the same content.
> **Note**: All files are created or updated to reflect the current state of the codebase.
