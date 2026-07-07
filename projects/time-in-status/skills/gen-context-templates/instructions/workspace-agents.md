# Workspace AGENTS.md — Analysis & Generation Instructions

## Analysis Scope (per workspace)

### 1. Package Configuration

Read `package.json`: name, description, dependencies, devDependencies, scripts, main/module/exports.

### 2. Source Analysis (max 5 key files)

1. List `src/` structure (2 levels deep)
2. Read barrel export (`src/index.ts`) for public API surface
3. Read up to **5 key source files** — pick files that best represent the workspace's architecture:
   - Entry points, main modules, core types
   - For **libraries** (`shared/*`, `packages/*`): focus on exported classes/functions, parameters, return types
   - For **apps** (`apps/*`): focus on entry points, routing, state management, key features
   - For **Lambda** (`aws/*`): focus on handlers, Step Functions, trigger config
4. Read type definitions (`src/types/` or `types.ts`) if they exist

### 3. Real Usage (shared/* and packages/* only)

1. Grep in `apps/` for `from '<package-name>'`
2. Read surrounding code (start with 5–15 lines; expand as needed to capture full imports and sufficient context for a runnable example) for up to **3 usage examples**
3. Prioritize modern-stack apps over legacy if migration detected
4. Skip this step for `apps/*` and `aws/*`

### 4. Generate AGENTS.md

Use template at `.claude/skills/gen-context-templates/templates/agents.md`.

**Content rules:**
- Derive all information from actual code analysis — do NOT invent patterns
- Include real code examples from the codebase
- Omit empty sections entirely (do not write "N/A")
- Usage examples must be complete and runnable (full imports + usage)

**Platform detection** — auto-detect from deps, build tools, entry points:

| Detection | Platform String |
|-----------|----------------|
| React + Vite | `React + TypeScript + Vite` |
| Vue + Webpack | `Vue + Webpack` |
| Express/Node server | `Node.js + Express` |
| Forge resolvers (`manifest.yml`) | `TypeScript (Forge Backend)` |
| Forge Custom UI (React + `@forge/bridge`) | `React + TypeScript + Vite (Forge Custom UI)` |
| Lambda handlers + `serverless.yml` | `AWS Lambda (Serverless Framework)` |
| Library with dual CJS + ESM output | `Node.js / Browser (dual CJS + ESM)` |
| Pure types (no runtime code) | `TypeScript only (no runtime code)` |

Append `**(Legacy)**` to legacy-stack platform strings if migration detected.
