# Shared Rules for All Document Generators

## File Exclusion Rules

Never read, analyze, or reference files matching these patterns:

- `.gitignore` patterns (read `.gitignore` first)
- `node_modules/`, `dist/`, `.turbo/`, `.esbuild/`, `.serverless/`
- `*.env*`, `.idea/`, `.vscode/`
- `yarn.lock`, `package-lock.json`
- `*.pem`, `*.key`, `*.crt`, `*.zip`, `*.csv`, `*.tsv`, `*.tfstate*`, `*.tfvars`
- Patterns from `.cursorignore`, `.claudeignore`, `.claude/settings.json` → `ignorePaths` (if they exist)

**Exception:** `.claude/skills/`, `.claude/commands/`, `.claude/memory/`, and `.claude/settings.json` are ALWAYS readable regardless of the rules above (including `.gitignore`). These paths contain agent templates, instructions, working files, and configuration required for document generation.

## Stack Priority

If the project has multiple technology generations (modern + legacy):

- Lead with the **modern** stack in all sections; document legacy in a shorter "(Legacy)" subsection
- Use code examples from modern-stack apps, not legacy ones
- Describe modern development flow as primary, legacy as secondary

If no migration detected — document the single stack without distinction.

## Existing Documentation Integration

- **Fully covered** by existing docs → summarize key points + reference link
- **Partially covered** → merge existing knowledge with code analysis, cite source
- **Not covered** → generate entirely from code analysis
- **Never contradict** existing documentation; note discrepancies if found
- When existing docs were used as source, reference them in an appropriate section of the generated document
