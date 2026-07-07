# Placeholder Instructions: development-guide.md

## `{{DEVELOPMENT_WORKFLOW}}`

Numbered step-by-step list of the typical development workflow (clone, install, branch, develop, test, PR).

## `{{SETUP_INSTRUCTIONS}}`

Prerequisites, install commands, environment setup, and how to run the project locally.

## `{{DOCUMENTATION_MAINTENANCE}}`

Generate the full section using the `Docs folder` value from the compact summary for all file paths. Include:
1. Mandatory notice about updating docs after code changes
2. "When to Update Documentation" — list of documented areas with file paths
3. "Documentation Update Rules" — numbered list of when to update which doc

## `{{DEVELOPMENT_RULES}}`

Generate numbered rules based on detected patterns. Each rule has a descriptive heading and explanation. Order: architecture/platform rules first, then code style, then conventions.

**Conditional rules — only include if detection condition is met:**

The table below is the **single source of truth** for both development rules (used by `development-guide.md` generation) and Rovo Dev review instructions (used by `review-agent.md` generation). The `Rovo Dev Instruction Pattern` column is used exclusively by the review agent — ignore it when generating `development-guide.md`.

| Detection Condition | Rule | Rovo Dev Instruction Pattern |
|---------------------|------|------------------------------|
| `@atlaskit/primitives` in deps AND `cssMap` usage in source | **Atlaskit Primitives & cssMap** — Always use `@atlaskit/primitives` components (`Box`, `Stack`, `Inline`, `Grid`, `Text`, `Pressable`, `Anchor`, etc.) with `cssMap` for styling. Never use raw HTML elements when a primitive exists. If `cssMap` unavailable, use `var(--ds-*)` design tokens — never hardcode colors, spacing, or typography. | When you spot raw HTML elements (`div`, `span`) → suggest `@atlaskit/primitives`; When you spot hardcoded colors/spacing → suggest `var(--ds-*)` tokens |
| `@atlaskit/primitives` in deps BUT no `cssMap` usage | **Atlassian Design Tokens** — Always use `var(--ds-*)` design system tokens. Never hardcode visual values. Use `@atlaskit/primitives` where available. | When you spot hardcoded colors, spacing, or typography values → suggest using `var(--ds-*)` design system tokens instead |
| `@saasjetlib/atlassian-apis` or `@saasjetlib/atlassian-request-tools` in deps | **Atlassian API Abstraction** — All Atlassian REST API calls MUST go through `@saasjetlib/atlassian-apis` and `@saasjetlib/atlassian-request-tools`. Never call APIs directly with `fetch`, `requestJira`, or `@forge/api`. | When you spot direct `fetch`/`requestJira`/`@forge/api` calls → suggest `@saasjetlib/atlassian-apis` |
| `shared/` directory exists with modules | **Package Priority** — Priority: `@shared/*` → `@saasjetlib/*` → `@atlaskit/*` → external npm. Always check shared modules first. | When you spot external npm package being added → suggest checking `@shared/*` / `@saasjetlib/*` first |
| i18n package found (`i18next`, `react-i18next`, `@shared/i18n`, `vue-i18n`, etc.) | **Internationalization Required** — All user-facing strings MUST use the i18n system. Never hardcode UI text. | When you spot hardcoded user-facing strings → suggest i18n translation keys |
| React components found in `apps/` or `shared/` | **Extract Logic to Custom Hooks** — Component files contain only rendering logic. Extract business logic, data fetching, state management into `use*.ts` hooks. | When you spot business logic in React component body → suggest extracting to `use*.ts` hook |
| React frontend detected | **Extract Conditional Rendering** — Complex conditionals in JSX must be extracted into sub-components or render functions. | When you spot nested ternaries/complex conditionals in JSX → suggest sub-components |
| React frontend detected | **Extract Styles Outside Components** — Style definitions (`cssMap`, `css`, styled-components) MUST be defined outside the component function body. | When you spot style definitions inside component function → suggest moving outside |
| `@saasjetlib/page-layout` in any `apps/*/package.json` | **Use Page Layout** — All Forge Custom UI apps MUST use `@saasjetlib/page-layout` for page structure. | When you spot custom layout wrappers in Forge apps → suggest `@saasjetlib/page-layout` |
| `manifest.yml` or `manifest.yaml` exists (Forge project) | **Forge Manifest Maintenance** — Keep manifest in sync with backend resolver changes. | When you spot new resolver/module without manifest update → suggest updating `manifest.yml` |
| Always (unconditional) | **No Explanatory Comments** — No comments explaining what code does. Only: (1) why — business reasons, (2) workarounds — links to issues, (3) TODO — tracked work. | When you spot comments explaining what code does → suggest removing (keep only why/workaround/TODO) |
| TypeScript detected (`tsconfig.json` exists) | **Type Placement & Naming Rules** — Define shared types in dedicated files named after their domain (e.g., `gadget.ts`, `api.ts`, `models.ts`), not generic names like `types.ts`. Use `*.ts`, NOT `*.types.ts`. For UI components, a props interface MAY live within the component file. | When you spot types in generic `types.ts` files → suggest domain-named files (e.g., `gadget.ts`, `api.ts`); When you spot `*.types.ts` files → suggest renaming to `*.ts` |
| `@saasjetlib/react-hooks` in any workspace deps | **Prioritize @saasjetlib/react-hooks** — Check shared hooks library before implementing custom hooks for common functionality. | When you spot custom hook for common functionality → suggest checking `@saasjetlib/react-hooks` |
| Always (unconditional) | **Code Validation After Changes** — Always run build, lint, and test commands after changes. | When you spot code changes without running build/lint/test → suggest running validation commands before committing |
| Always (unconditional) | **Documentation Maintenance** — Update README.md and AGENTS.md when creating/modifying modules. | When you spot new module without AGENTS.md/README.md → suggest adding documentation |
| `@saasjetlib/jql-builder` in any workspace deps | **Use @saasjetlib/jql-builder for JQL** — All JQL construction MUST use `@saasjetlib/jql-builder`. Never manually construct JQL strings. | When you spot JQL string concatenation/template literals → suggest `@saasjetlib/jql-builder` |
