# AGENTS.md

<!-- Bold project name + one-line description. Example: **My Project** is a web app for... -->
{{PROJECT_DESCRIPTION}}

## Rules

Before writing or modifying code, review the [full development rules]({{DOCS_FOLDER}}/development-guide.md#development-rules):

<!-- {{DOCS_FOLDER}} placeholder: Task agent MUST replace with the actual docs folder from the compact summary. -->
<!-- Numbered list. Each item: **[Rule Name]({{DOCS_FOLDER}}/development-guide.md#rule-name-slug)** — one-line description. Include ALL rules from development-guide.md. The #rule-name-slug MUST be the GitHub-style anchor of that rule's heading in development-guide.md (lowercase, spaces replaced with hyphens, special characters removed). Example: "No Explanatory Comments" → #no-explanatory-comments. NEVER use a generic anchor like #development-rules for all items. -->
{{TOP_RULES_SUMMARY}}

## Documentation

| Document | Purpose |
|----------|---------|
{{DOCS_TABLE}}
<!-- Include the MCP.md row below ONLY if MCP.md exists in the project root. Omit if it was not generated. -->
{{MCP_DOC_ROW}}

Check `AGENTS.md` in module directories for module-specific patterns:
<!-- Grouped: shared/*/AGENTS.md, packages/*/AGENTS.md, apps/*/AGENTS.md, etc. -->
{{AGENTS_MD_LOCATIONS}}

## Additional Resources

{{ADDITIONAL_DOCS}}
