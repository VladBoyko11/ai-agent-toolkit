---
name: saasjet-coding-standards
description: SaaSJet code conventions and the 15 mandatory development rules for TypeScript + JavaScript + React + Atlassian Forge / Atlassian Design System projects (the time-in-status monorepo is the reference). Covers linting, naming, backend module structure, TypeScript, React, styling with Atlaskit primitives/cssMap/tokens, testing, exports/imports, comments, Atlassian API/JQL abstractions, custom-hook extraction, i18n, validation, and documentation maintenance. Consult when writing or reviewing code in any SaaSJet project, or when you need the authoritative "how we write code here" reference.
---

# SaaSJet Coding Standards

Authoritative, portable reference for how code is written across SaaSJet TS/React/Forge projects. Consolidated from the `time-in-status` monorepo docs (`doc/conventions.md`, `doc/development-guide.md`), which remain the live source in that repo. When a specific project has its own `doc/conventions.md` / `doc/development-guide.md`, the project-local file wins on conflicts; this skill is the cross-project baseline.

When applying a rule to library/framework specifics (React, Redux Toolkit, Atlaskit, Vitest, Zod, etc.), verify current best practice against the **context7 MCP server** (`mcp__context7__*`) rather than relying on memory.

---

## The 15 Development Rules (mandatory)

1. **Atlaskit primitives & cssMap.** Always use `@atlaskit/primitives` (`Box`, `Stack`, `Inline`, `Grid`, `Text`, `Pressable`, `Anchor`, …) with `cssMap` for styling. Never use raw `div`/`span` when a primitive exists. If `cssMap` is unavailable, use `var(--ds-*)` design tokens — never hardcode colors, spacing, or typography.
2. **Page Layout in Forge Custom UI.** All Forge Custom UI apps MUST use `@saasjetlib/page-layout` for top-level page structure (header, sidebar, content). Do not hand-roll layout wrappers.
3. **Forge manifest maintenance.** Keep `apps/forge/manifest.yml` in sync with backend resolver/module changes in the SAME PR — new/renamed resolver function, custom UI module, scope, permission, or external fetch endpoint. Out-of-sync manifests cause silent failures in deployed environments.
4. **Atlassian API abstraction.** All Atlassian REST calls MUST go through `@saasjetlib/atlassian-apis` (and `@saasjetlib/atlassian-request-tools` where applicable). Never call directly with raw `fetch`, `requestJira` from `@forge/bridge`, or `api.asUser()/asApp()` from `@forge/api`. The abstraction handles auth, rate limiting, pagination, and bridge wiring.
5. **JQL via `@saasjetlib/jql-builder`.** All JQL construction MUST use `@saasjetlib/jql-builder`. Never manually concatenate or template-literal JQL strings.
6. **Package priority.** Pull functionality in this order: `@shared/*` → `@saasjetlib/*` → `@atlaskit/*` → external npm. Always check workspace shared modules before adding a new dependency.
7. **Prioritize `@saasjetlib/react-hooks`.** Before writing a custom hook for common functionality (debounce, throttle, async state, storage, intersection, resize, …), check `@saasjetlib/react-hooks` and reuse it.
8. **Extract logic to custom hooks.** Component files contain only rendering logic. Business logic, data fetching, derived state, and effect orchestration live in `use*.ts` hooks (or `use*.tsx` if returning JSX). A component should read like a structured template.
9. **Extract conditional rendering.** Complex conditionals in JSX (nested ternaries, multi-clause `&&` chains, branches longer than a few lines) must be extracted into sub-components or named render functions (`<FeatureBlock />` / `renderFeature()`).
10. **Extract styles outside components.** Style definitions (`cssMap`, `css`, styled-components, plain style objects) MUST be defined at module top level, not inside the component body (avoids re-allocation per render and defeated memoization).
11. **Type placement & naming.** Define shared types in domain-named files (`gadget.ts`, `api.ts`, `models.ts`, `report.ts`) — NOT generic `types.ts`, NOT `*.types.ts`. A `Props` interface MAY live in the component file when private to it. Cross-module types go to `shared/types` or a domain file in the owning workspace.
12. **Internationalization required.** All user-facing strings MUST flow through i18n (`i18next` + `react-i18next`). Never hardcode UI text. Add keys to locale files and reference via `t('namespace.key')`. Plural forms branch by `count` in JS — do NOT rely on `defaultValue_one`/`defaultValue_other`.
13. **No explanatory comments.** Only three comment kinds are allowed: **Why** (non-obvious business/domain reason), **Workaround** (link the upstream issue/PR), **TODO** (tracked work, ideally `TL-XXXX`). Self-documenting code replaces what-comments. No section banners, no commit-history notes, no restating the code.
14. **Code validation after changes.** After any non-trivial change run, in order (stop at first failure, fix, continue):
    ```bash
    npx tsc --noEmit         # type-check
    yarn lint                # ESLint across workspaces (turbo, cached)
    yarn test                # Vitest + Jest (turbo, cached)
    yarn build:packages      # only if packages/* or shared/* sources changed
    ```
    Root `package.json` scripts are the source of truth for what to run.
15. **Documentation maintenance.** When you create a new module/package/app, or significantly change responsibilities of an existing one, update its `README.md` and `AGENTS.md` in the same PR. See the Documentation Maintenance matrix below.

---

## Linting

- ESLint is centralised in `@presets/eslint` (`presets/eslint/`) with three entry points: `@presets/eslint/base` (Node/plain JS), `@presets/eslint/typescript` (adds `@typescript-eslint/*`, `max-len: 120`), `@presets/eslint/react` (default for React apps; wires Jest rules for `**/*.spec.{ts,tsx}`).
- Each app keeps a thin local config that re-exports a preset (e.g. `apps/global-page/.eslintrc.cjs`). Do not duplicate individual rules in app configs — extend the preset, override only when justified.
- `yarn lint` runs ESLint across workspaces via `turbo lint`; `yarn lint:staged` runs `lint-staged` on changed files (Husky pre-commit).
- Stylelint is per-app for SCSS (e.g. `stylelint-config-standard-scss` + `@atlaskit/stylelint-design-system`).

## Naming

| Kind | Convention | Examples |
|---|---|---|
| React components (files + exports) | `PascalCase.tsx`, default export | `AppHeader.tsx`, `ChartLegend.tsx` |
| Custom hooks | `useXxx.ts`, camelCase | `useReportData.ts` |
| Plain modules / utilities | `camelCase.ts` | `helpers.ts`, `dateRangeFormatConverter.ts` |
| Redux building blocks | `slice.ts`, `thunks.ts`, `selectors.ts`, `middleware.ts`, `store.ts` | `redux/reportConfig/slice.ts` |
| Backend module files | `index.ts`, `service.ts`, `service.spec.ts`, `controller.ts`, `validation.ts`, `middleware.ts`, `types.ts`, `model.ts` | see Backend Module Structure |
| Barrel files | `index.ts` (`index.tsx` for component re-exports) | `hooks/index.ts` |
| Tests | co-located `*.test.ts(x)` (Vitest) or `*.spec.ts(x)` (Jest) | `utils.test.ts`, `service.spec.ts` |
| SCSS modules | `*.module.scss`, kebab-case classes | `Grid.module.scss` |
| Workspace packages | `@tis/*` (apps), `@shared/*` (shared), `@presets/*`, `@saasjetlib/*` (published) | `@tis/global-page` |
| Types / interfaces | `PascalCase`, no `I`-prefix | `TopBarProps`, `ReportConfig` |
| Constants | `SCREAMING_SNAKE_CASE` for true constants, `camelCase` for config objects | `DATE_RANGES`, `defaultConfig` |
| Branch names | `[prefix/]TICKET-ID-kebab-description` | `feature/TL-4266-tis-permissions` |

Folders follow the casing of their contents — `PascalCase` for component folders (`Chart/`), `kebab-case` for feature modules (`report-configuration/`), lowercase for infra folders (`hooks/`, `redux/`, `api/`).

## Backend Module Structure

Per-feature folder layout (include only what the module needs):

```
<module>/
├── index.ts         # entry point: assembles + exports the public surface
├── service.ts       # business logic; CRUD, calculations, integrations
├── service.spec.ts  # unit tests (Jest)
├── controller.ts    # request handler — invokes service, shapes response
├── validation.ts    # request validation (Joi / Zod)
├── middleware.ts    # module-local middleware (auth gate, logging)
├── types.ts         # module-private interfaces; cross-module → shared/types
└── model.ts         # data shapes / storage entity definitions
```

Forge resolvers (`apps/forge/src/modules/*`) often need only `index.ts` + `service.ts` (+ optional `domain/`), since routing is by resolver key. AWS Lambda handlers (`aws/*`) follow the same shape, entry exported from `index.ts`.

- **Modularization** — features self-contained; cross-module helpers go to `shared/*` or `packages/*`.
- **Testing** — every `service.ts` has a colocated `service.spec.ts` (Jest).
- **Validation** — validate payloads at the boundary via Joi (legacy/AWS) or Zod (newer code); one library per surface area, do not mix.
- **Middleware** — cross-cutting concerns (auth, permission gates via `createRequirePermission`, logging) live in `middleware.ts`, not inlined.
- **Error handling** — throw typed exceptions from `shared/exceptions`; resolver middleware (`errorsToRejected`, `flagMiddleware`) normalises them.

## TypeScript

- Strict mode on (`presets/ts/base.json`: `strict`, `forceConsistentCasingInFileNames`, `esModuleInterop`, `skipLibCheck`). React preset (`presets/ts/react-app.json`): `target ES2020`, `lib ES2022 + DOM`, `module ESNext`, `moduleResolution bundler`, `jsx react-jsx`, `noImplicitAny`, `isolatedModules`, `noFallthroughCasesInSwitch`.
- Apps extend a preset and only add path aliases. Use aliases (`@src/*`, `@api/*`, …) instead of `../../../` chains.
- Prefer `interface` for public/component prop shapes; `type` for unions, mapped types, utility compositions. Export prop/return-type shapes alongside the symbol (`UseDateRangeLegendParams`, `UseDateRangeLegendReturn`).
- Avoid `any`. When interop with an untyped lib is unavoidable, narrow at the boundary (`as unknown as X`) and document why.
- Runtime/validation types via `joi` (server, forms) and `zod` (newer code); one per surface area.
- Typecheck with `npx tsc --noEmit` (`yarn typecheck` per app); `vite-plugin-checker` runs it during dev.

## React

- React 18, functional components only. Declare with `function ComponentName(props: Props) { ... }`, default-export; arrow components are tolerated but `react/function-component-definition` warns on inconsistency.
- Each app has its own Redux Toolkit store (`createReduxStore` from `@shared/redux`) + typed `useAppDispatch`/`useAppSelector`. Don't reach into another app's store.
- Async work via `createTypedAsyncThunk`; read `extra.platformApi` / `extra.platformBridge`, never singletons inside thunks.
- Custom hooks in a `hooks/` dir, re-exported from `hooks/index.ts`. Side effects belong in hooks, never in render bodies.
- Providers composed in a single `AppProvider.tsx` (Atlaskit `AppProvider` → `I18nextProvider` → `PlatformProvider` → `ConfirmProvider` → Redux `Provider`).
- Routing via `react-router@7`; per-app `routes.tsx`; prefer nested routes over imperative navigation.
- Forms via `@atlaskit/form` with Joi schemas.

## Styling

- Atlaskit Design System tokens. Reach for `@atlaskit/primitives` before writing layout CSS. Read tokens via `token()` from `@atlaskit/tokens`.
- CSS-in-JS via `cssMap` from `@atlaskit/css`; group rules in a top-level `styles` object, pass via `xcss`/`css`.
- SCSS modules (`*.module.scss`) only when `cssMap` can't express it (e.g. third-party global selectors like ag-grid `:global(.ag-status-bar)`).
- Never hardcode colors/spacing — reference tokens (`var(--ds-space-050)`, `token('color.background.neutral')`). Stylelint enforces token usage on SCSS.

## Testing

- Modern apps: **Vitest** + jsdom (`yarn test`, setup in `setupDomTests.ts`). Node code: **Jest** (`*.spec.ts`).
- Tests co-located. Vitest `*.test.ts(x)`, Jest `*.spec.ts(x)`. Use `__tests__/` only when grouping fixtures.
- React: `@testing-library/react`; query by accessible role/text, not class names or test ids unless unavoidable.
- Cover business logic (calculations, services, validation). No UI snapshot testing. Tests must pass before opening a PR.

## Exports & Imports

- Components: `export default function ComponentName(...)`; co-located `index.ts` re-exports default + types.
- Hooks/utils/types: named exports, re-exported via folder `index.ts`. Don't mix default+named for one symbol except via a barrel.
- Workspace packages expose their public API through `main`/`exports`, not deep `src/` paths.
- Import ordering (eslint-plugin-import), blank-line-separated groups: (1) built-ins + external packages, (2) workspace packages (`@shared/*`, `@presets/*`, `@tis/*`), (3) path-aliased app modules (`@src/*`, `@api/*`, …), (4) relative (`../`, `./`). Sort by path within a group. Type-only imports use `import type`.
- Barrels (`hooks/index.ts`, `components/index.ts`, redux roots) are the norm; don't barrel across external workspaces just to shorten imports (defeats tree-shaking).

## Comments

Comment only when code can't tell the story. Three warranted cases: **Why** (business/domain reason), **Workaround** (link upstream issue/ticket, e.g. `// Workaround for ag-grid#1234 — remove once fixed`), **TODO** with a ticket (`// TODO(TL-4585): handle empty schedule`). No code-restating comments, no section banners. JSDoc reserved for public APIs of workspace packages, not internal helpers.

## Development Workflow (summary)

Pick a Jira ticket → create branch from Jira (target `master`, format `[prefix/]TICKET-ID-kebab-desc`) → `yarn install --immutable` → `yarn build:packages` → develop following the 15 rules → validate (`tsc --noEmit`, `yarn lint`, `yarn test`) → commit via Conventional Commits (`type(TL-XXXX): subject`, `yarn cz`) → PR to `dev/*` (Draft first for AI review, then Ready) → keep `dev/*` current with `master` → release via TLead (`create-delivery` → `delivery/*` → `production` semantic-release → merged back to `master`). Hotfixes branch from `hotfix`.

Prerequisites: Node ≥ 18.20, Yarn v4 (Berry) via Corepack, `NPM_TOKEN` for `@saasjetlib/*`, Forge CLI, admin test Jira Cloud site.

## Documentation Maintenance matrix

> Mandatory: when you change code/config/workflow the docs describe, update the corresponding doc in the same PR. Stale docs are worse than missing docs.

| Area | File | Update when… |
|---|---|---|
| Project overview, tech stack | `doc/project-context.md` | Adding/removing apps, major deps, product capabilities |
| Architecture, data flow, platform integration | `doc/architecture.md` | Changing module boundaries, new patterns, Forge backend↔frontend integration |
| Code style, naming, patterns | `doc/conventions.md` | Adopting/dropping a convention, changing folder rules |
| Dev workflow, setup, dev rules | `doc/development-guide.md` | Changing scripts, prerequisites, branch/PR flow, or any of the 15 rules |
| Repo entry point | `README.md` | Setup, install, scripts table, top-level structure |
| Git/PR/commit conventions | `CONTRIBUTING.md` | Branch model, commit types, PR process |
| Code review process & SLA | `CODE_REVIEW.md` | Review SLA, responsibilities, AI-review workflow |
| Infrastructure | `doc/INFRASTRUCTURE.md` | Auto-generated by `terraform-docs` — edit `infrastructure/*.tf`, not the doc |
| Module-specific behavior | `AGENTS.md` (per workspace) | Creating/renaming a module or changing its public contract |
