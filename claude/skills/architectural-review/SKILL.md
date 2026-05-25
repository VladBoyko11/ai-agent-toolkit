---
name: architectural-review
description: Deep, context-aware code review of a local branch. Takes a local project path and a branch name, pulls full Jira+Confluence context for the ticket (via analyze-jira-task), diffs the branch against main/master, and evaluates the changes on four axes — architecture/design patterns, general best practices, TypeScript typing, and Forge correctness (using forge MCP docs). Cross-references sibling projects on disk when imports/patterns point at them. Use when the user says "review branch", "code review", "архітектурне рев'ю", "перевір гілку", "review this branch", or provides a project path + branch name.
---

# Architectural Review

Performs a deep, ticket-aware code review of a feature branch in a local project. Goes beyond "find bugs" — evaluates whether the chosen approach is structurally right, fits Forge constraints, and follows the broader codebase conventions.

## Inputs

The user provides:
- **Project path** — absolute or relative path to a local project (e.g. `C:\Users\User\Documents\vladsaasjet\time-in-status`).
- **Branch name** — the branch to review (e.g. `TL-3895-fix-sprint-report-bugs`).
- (Optional) **Jira key** — if the branch name doesn't contain one, ask.

If anything is missing, ask the user for the missing piece using AskUserQuestion.

## Step 1 — Pull Jira/Confluence context

Extract a Jira key from the branch name with `[A-Z]+-\d+`. If found, invoke the `analyze-jira-task` skill with that key **before reading any code**. Treat the output as the source of truth for "what was supposed to be done". Keep it in mind as the acceptance bar for the review.

If no key in the branch name, ask the user for one. If they don't have one, proceed without ticket context but note this gap in the final report.

## Step 2 — Prepare the local repo

In the given project directory:

```powershell
cd <project-path>
git fetch --all --quiet
git rev-parse --abbrev-ref HEAD                 # remember current branch
git show-ref --verify --quiet refs/heads/<branch> ; if (-not $?) { git checkout --track origin/<branch> } else { git checkout <branch> }
git pull --ff-only --quiet
```

Determine the **base branch**:
- Try `git symbolic-ref refs/remotes/origin/HEAD` (returns `refs/remotes/origin/<default>`).
- Fallback order: `master`, `main`, `develop`.

Compute the merge base and diff:
```powershell
$base = git merge-base HEAD origin/<default-branch>
git diff --stat $base..HEAD                     # overview
git diff --name-status $base..HEAD              # list of changed files
```

Restore the user's original branch at the very end (or after the review, whichever fits the user's flow — ask if unsure).

## Step 3 — Map the change

Read each changed file (only the affected hunks for large files via `git diff $base..HEAD -- <file>`). For every file, mentally tag:
- **Layer** — UI component, hook, store, service, util, type, config, test, infra, Forge manifest, etc.
- **New vs modified** — additions get more scrutiny on architecture; modifications get scrutiny on whether the change respects existing structure.
- **Cross-project references** — if an import resolves to a sibling directory (e.g. `../../other-project/...` or a workspace package), open that location locally and skim the referenced symbol before judging fit. Do NOT fetch anything remote for this.

## Step 4 — Review on four axes

For every meaningful change, evaluate:

### A. Architecture & design patterns
Reference patterns from refactoring.guru when relevant (Strategy, Factory, Observer, Adapter, Facade, Decorator, Command, State, Template Method, Composite, Chain of Responsibility, etc.). Ask:
- Does this code introduce a pattern that fits the problem, or invent an ad-hoc solution where a named pattern would be cleaner?
- Are responsibilities split correctly (SRP)? Is there a god-object/god-component forming?
- Is coupling tight where it could be loose (DI, interfaces, events)?
- Is the data flow direction consistent with the rest of the project (top-down props, store subscriptions, event bus, etc.)?
- Are abstractions at the right level — neither premature (single-use generics, useless wrapper hooks) nor missing (copy-pasted logic across files)?
- For state management: are reducers/stores doing one thing? Are side effects isolated?

When suggesting a pattern, name it explicitly and explain in one sentence why it fits *this* code — don't drop pattern names as decoration.

### B. Best practices
- **Naming** — intent-revealing, no abbreviations that obscure, consistent with neighbors.
- **Function size & cyclomatic complexity** — flag functions doing more than one thing or with deep nesting.
- **Duplication** — same logic in 2+ places that could be a helper.
- **Error handling** — every async/IO path either handles failure or has a clear reason not to. No silent catches.
- **Comments** — flag comments that explain WHAT (redundant with code) vs WHY (load-bearing). Recommend removing the former.
- **Performance smells** — N+1 fetches, unbounded loops over server data, missing memoization where re-renders are obvious, sync work in hot paths.
- **Security** — input validation at boundaries, no secrets in code, no SQL/command injection, safe deserialization.
- **Tests** — does the change include tests if the file pattern suggests it should? Are existing tests still valid?
- **Dead code** — unused exports, leftover console.logs, commented-out blocks.

### C. TypeScript typing
- **`any` / `unknown`** — flag every `any`; suggest the narrowest type. `unknown` is fine if narrowed at boundary.
- **Type assertions (`as`)** — flag and ask if they hide a real type mismatch.
- **Non-null assertions (`!`)** — flag; prefer guards.
- **Function signatures** — return types explicit on exported functions; no inferred `Promise<any>`.
- **Generics** — used where they add reuse, not where they obscure.
- **Discriminated unions** — preferred over boolean flags or optional fields for state.
- **Exhaustiveness** — `switch` on union types should have an exhaustive default (`never` check).
- **Public API types** — interfaces/types in `index.ts` or `types.ts` exported intentionally, not as a byproduct.
- **Strict mode** — code should not rely on implicit `any`; if `tsconfig` is loose, flag and recommend.

Run `npx tsc --noEmit` in the project (per global rules — this is the ONLY validation command allowed). If it produces errors related to the diff, include them in the report.

### D. Forge correctness
Only relevant if the project is a Forge app (look for `manifest.yml`, `@forge/*` imports, or files under `src/resolvers/`, `src/frontend/`).

For each Forge-relevant change, consult the **forge MCP server** tools — they are the authoritative source:
- `mcp__forge__forge-development-guide` — general Forge dev guidance.
- `mcp__forge__forge-app-manifest-guide` — manifest schema, permissions, scopes, modules.
- `mcp__forge__forge-backend-developer-guide` — resolver patterns, async events, storage API.
- `mcp__forge__forge-ui-kit-developer-guide` — UI Kit components, layout, hooks.
- `mcp__forge__confluence-macro-developer-guide` — Confluence macro specifics.
- `mcp__forge__jira-service-management-assets-guide` — JSM Assets specifics.
- `mcp__forge__list-forge-modules` — to confirm a module name and its constraints.
- `mcp__forge__search-forge-docs` — keyword search when you don't know which guide.
- `mcp__forge__atlassian-design-tokens` — for UI Kit styling questions.

Check at minimum:
- **Manifest changes** — every new permission/scope is the narrowest possible; modules referenced exist; entry points match files on disk.
- **Resolver hygiene** — invocation context handled, no unbounded loops, storage keys namespaced, async events used for long work.
- **UI Kit** — only supported components/props used, layout uses design tokens not raw values, `useProductContext`/`invoke` used correctly.
- **Storage API** — quotas and TTL respected, indexed where queried.
- **Webtrigger / scheduled trigger** — idempotency, error visibility.

If you cite a guide, name it (e.g. "per `forge-backend-developer-guide`, async events must …").

## Step 5 — Cross-project references

If the diff imports from another local project (relative path leaving the project root, or workspace package), find that location on disk under the same parent folder (`C:\Users\User\Documents\vladsaasjet\` is the common parent for this user) and read the referenced symbol's definition. Use that to judge whether the consumer side respects the contract. Do not fetch remote.

## Step 6 — Produce the review report

Output to the user as Markdown:

```
# Architectural review — <project-name> / <branch>

**Ticket:** <KEY — summary>   **Base:** origin/<default>   **Files changed:** N (+X / −Y)

## Ticket alignment
<1–3 sentences: does the diff actually implement the AC from the ticket? Anything in AC NOT covered? Anything in the diff that's OUT of scope?>

## Architecture & patterns
- 🔴/🟡/🟢 <observation> — `file.ts:line`
  Suggested pattern: <name> — <why it fits>. Refactor sketch: <2-line idea>.
- ...

## Best practices
- ...

## TypeScript
- ...
(Include `tsc --noEmit` output here if non-empty.)

## Forge
- ...
(Cite specific forge guides where relevant.)

## Cross-project
- ...

## Verdict
🟢 Ship as-is / 🟡 Ship with follow-ups / 🔴 Needs changes before merge
**Top 3 things to fix before merge:**
1. ...
2. ...
3. ...
**Nice-to-have follow-ups (separate ticket):**
- ...
```

Use traffic-light prefixes (🔴 must fix, 🟡 should fix, 🟢 nit/praise) so the user can scan quickly. Reference `file:line` for every finding.

## Conventions

- **Be concrete.** "Could be cleaner" is not a finding. Quote the line, name the smell, suggest the rewrite (in 1–2 lines, not full implementation).
- **Praise what's right.** If the diff demonstrates good pattern use, say so — it calibrates the rest of the review and reinforces good habits.
- **Don't gold-plate.** If the diff is a 5-line bugfix, the report should be a 5-line review. Match depth to scope.
- **Don't invent files.** Only reference files actually in the diff or actually on disk.
- **Don't post anywhere.** This skill outputs to the chat only — never `git push`, `gh pr comment`, or any write-back.

## Error handling

- Project path doesn't exist → tell the user the path you tried, stop.
- Branch doesn't exist locally or on origin → say so, list nearby branches (`git branch -a | findstr <key>`).
- `git diff` is empty (branch == base) → tell the user, stop.
- `analyze-jira-task` fails → continue without ticket context, flag the gap in the final report.
- Forge MCP server unavailable → note that Forge analysis was skipped because the MCP server didn't respond.
