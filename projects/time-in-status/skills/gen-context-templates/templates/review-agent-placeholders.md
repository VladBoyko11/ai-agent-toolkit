# Review Agent Template — Placeholder Instructions

This file contains instructions for filling each `{{PLACEHOLDER}}` in `review-agent.md`. The Task agent reads this file to understand what content to generate for each section.

---

## `{{PROJECT_CONTEXT}}`

Generate a `## Project Context` section describing the project's tech stack as a bullet list. Derive from `project-context.md` or codebase analysis. Include:
- Language and version
- Runtime
- Framework(s) — both modern and legacy if applicable
- Database
- Build tools
- Testing framework
- Infrastructure / deployment platform
- CI/CD

Example:
```markdown
## Project Context

- **Language:** TypeScript 5.x
- **Runtime:** Node.js 20 LTS
- **Frontend (Modern):** React 18 + Vite (Forge Custom UI)
- **Frontend (Legacy):** Vue 2 + Quasar + Webpack (Connect)
- **Backend (Modern):** Atlassian Forge resolvers
- **Backend (Legacy):** Express.js (Connect server)
- **State Management:** Redux Toolkit
- **Testing:** Jest
- **Build:** Turborepo + Vite + Webpack
- **Platform:** Atlassian Forge + Atlassian Connect
- **Infrastructure:** AWS Lambda (Serverless Framework)
```

---

## `{{NAMING_RULES}}`

Convert naming conventions from `conventions.md` into Rovo Dev format. Standard rules to include:

- Unclear/abbreviated variable names → descriptive names
- Boolean variables without `is/has/can/should/will` prefix → add prefix
- Inconsistent naming patterns → align with project convention

Add project-specific naming rules derived from conventions (e.g., file naming patterns, component naming).

---

## `{{CODE_ORGANIZATION_RULES}}`

Standard code organization rules:

- Functions >40 lines → extract helpers
- Nesting >3 levels → early returns / guard clauses
- Files >300 lines → split into modules
- Code duplication in 2+ places → extract shared utility

---

## `{{ERROR_HANDLING_RULES}}`

Standard error handling rules:

- Empty catch blocks → proper error handling
- Generic `Error` → specific error classes
- Missing async error handling → add try/catch
- Error messages exposing internals → user-friendly messages

---

## `{{TYPE_SAFETY_RULES}}`

Only include if TypeScript is detected. Rules:

- `any` type → proper types or `unknown` with type guards
- Type assertions without validation → type guards

---

## `{{ARCHITECTURE_RULES}}`

Convert architecture patterns from `architecture.md` into Rovo Dev format:

- Business logic in components/controllers → move to service layer / custom hooks
- Direct database/API queries outside abstraction layer → use the abstraction
- Classes with multiple responsibilities → SRP
- Tight coupling → dependency injection / interfaces

---

## `{{API_RULES}}`

Convert API conventions from `conventions.md` or the project's API convention document (if one exists) into Rovo Dev format:

- Inconsistent API response structures → standardized format
- Missing input validation → validation schema
- Wrong HTTP status codes → semantically correct codes
- Breaking API changes without versioning → version or maintain compatibility

If the project has an API convention doc, read it and convert rules.

---

## `{{PROJECT_SPECIFIC_RULES}}`

**This is the key section.** Convert the applicable development rules into Rovo Dev format. For each rule, generate a corresponding "When you spot..." instruction. Exclude rules already covered in other sections above — only include project-specific rules here. Also include any project-specific patterns related to architecture, error handling, security, performance, or dependencies that are unique to this project.

The conditional rules table in `.claude/skills/gen-context-templates/instructions/development-guide.md` is the **single source of truth** specifically for project-specific development rules and their Rovo Dev Instruction Patterns (this section only — other sections like `{{ARCHITECTURE_RULES}}` and `{{API_RULES}}` derive from their own source documents). Use the `Rovo Dev Instruction Pattern` column from that table to generate this section:

1. If reading from the generated `<docs-folder>/development-guide.md`, find each rule there and look up its Rovo Dev pattern from the instructions table
2. If deriving from codebase analysis (fallback), evaluate the detection conditions from the instructions table and use the `Rovo Dev Instruction Pattern` column directly

For each applicable rule, generate a "When you spot [problem], suggest [solution]" instruction following the pattern from the table.

---

## `{{SECURITY_RULES}}`

Standard security rules:

- Hardcoded secrets → environment variables / secrets manager
- User input in SQL/shell/HTML → parameterized queries / escaping
- Missing auth checks → add auth middleware
- Sensitive data in logs → mask/exclude
- Overly permissive CORS/permissions → least privilege
- Missing rate limiting → add rate limiting

---

## `{{PERFORMANCE_RULES}}`

Standard performance rules:

- N+1 queries → batch queries / eager loading
- Expensive computations in loops → memoization / pre-computation
- Missing pagination → implement pagination
- Missing cleanup (listeners, subscriptions) → add disposal
- Synchronous blocking in async → use async alternatives

---

## `{{READABILITY_RULES}}`

Standard readability rules:

- Magic numbers/strings → named constants
- Complex boolean expressions → named variables/functions
- TODO/FIXME without tickets → create Jira ticket
- Overly clever code → straightforward alternatives
- Missing JSDoc on public APIs → add documentation

---

## `{{TESTING_RULES}}`

Testing rules based on detected test framework:

- New logic without tests → add unit tests
- Tests without meaningful assertions → add real assertions
- Vague test names → descriptive "should..." names
- Hardcoded external dependencies → mocks/stubs
- Missing edge cases → add boundary/error path tests
- Duplicated test setup → extract fixtures

Include the project's test framework (Jest/Vitest/etc.) and conventions.

---

## `{{GIT_RULES}}`

Standard git/PR rules:

- Mixed concerns in PR → split into focused PRs
- Uninformative commit messages → descriptive conventional commits

Include the project's commit convention if detected (e.g., Conventional Commits with `commitizen`).

---

## `{{DEPENDENCIES_RULES}}`

Standard dependency rules:

- New dependencies → verify maintenance status and necessity
- Environment-specific config in source → use environment variables

---

## `{{REVIEW_EXCLUSIONS}}`

Generate exclusions based on project tooling:

- **Formatting** — if ESLint/Prettier configured, exclude formatting nitpicks
- **Auto-generated code** — exclude generated files (GraphQL types, Prisma, etc.)
- **Lock files** — exclude `yarn.lock`, `package-lock.json`
- **Documentation-only changes** — skip code quality suggestions on `.md` files
- **Legacy code** — if modern/legacy migration detected, note that legacy-stack apps (identified during analysis) have different standards

Format each exclusion as:
> **When you find [type of change]**, you should **avoid leaving suggestions** because [reason].
