---
name: analyze-jira-task
description: Fetch a Jira issue (by key or URL) plus its comments, linked issues, sub-tasks, and any Confluence pages referenced in the description/comments, then produce a structured analysis with summary, acceptance criteria, discussion insights, related-issue context, and Confluence context. Use when the user asks to "analyze Jira task", "pull context for ticket X", "what does TL-XXXX need", "розібрати задачу", "проаналізуй задачу", or pastes a Jira issue key/URL and wants context. Read-only — never writes back to Jira/Confluence.
---

# Analyze Jira Task

Extracts a Jira issue and all linked context (comments, sub-tasks, linked issues, referenced Confluence pages) and produces a structured analysis to give a complete picture of what must be done or what was done. This skill never writes to Jira or Confluence — it is purely for gathering context.

## Inputs

The user provides one of:
- A Jira issue key (e.g. `TL-3895`)
- A browse URL (e.g. `https://saasjet.atlassian.net/browse/TL-3895`)

If no argument is given, ask the user for one.

## Credentials

Credentials live in the `time-in-status` project `.env`:

- File: `C:\Users\User\Documents\vladsaasjet\time-in-status\.env`
- Variables: `JIRA_BASE_URL`, `JIRA_EMAIL`, `JIRA_API_TOKEN`

Load them once and store in shell variables for the session. Do NOT echo `JIRA_API_TOKEN` to the user or to any non-API surface (logs, summaries, output text). Treat the token as a secret.

PowerShell example:
```powershell
$envFile = "C:\Users\User\Documents\vladsaasjet\time-in-status\.env"
Get-Content $envFile | ForEach-Object {
  if ($_ -match '^\s*([^#=]+?)\s*=\s*(.+?)\s*$') {
    Set-Variable -Name $matches[1] -Value $matches[2] -Scope Script
  }
}
$pair = "${JIRA_EMAIL}:${JIRA_API_TOKEN}"
$auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($pair))
$headers = @{ Authorization = "Basic $auth"; Accept = "application/json" }
```

Bash example (Git Bash on Windows):
```bash
set -a; source "/c/Users/User/Documents/vladsaasjet/time-in-status/.env"; set +a
AUTH=$(printf '%s:%s' "$JIRA_EMAIL" "$JIRA_API_TOKEN" | base64 -w0)
```

## Step 1 — Resolve issue key

Parse the input:
- If it matches `^[A-Z][A-Z0-9]+-\d+$` → use as-is.
- If it is a URL like `…/browse/<KEY>` → extract `<KEY>`.
- Otherwise ask the user to clarify.

## Step 2 — Fetch the issue

Endpoint:
```
GET ${JIRA_BASE_URL}/rest/api/3/issue/${KEY}?expand=renderedFields,names,changelog&fields=*all
```

PowerShell:
```powershell
$issue = Invoke-RestMethod -Uri "$JIRA_BASE_URL/rest/api/3/issue/$KEY?expand=renderedFields,names&fields=*all" -Headers $headers
```

Capture from the response:
- `fields.summary`
- `fields.status.name`, `fields.priority.name`, `fields.issuetype.name`
- `fields.assignee.displayName`, `fields.reporter.displayName`
- `fields.description` (ADF JSON) and `renderedFields.description` (HTML — easier to read)
- `fields.subtasks[]` (key, summary, status)
- `fields.issuelinks[]` (type.name, inwardIssue/outwardIssue.key + summary + status)
- `fields.parent` (if present)
- `fields.labels`, `fields.components`, `fields.fixVersions`
- Any custom field that looks like AC / Acceptance Criteria (check `names` map for `customfield_*` → "Acceptance Criteria")

## Step 3 — Fetch comments

```
GET ${JIRA_BASE_URL}/rest/api/3/issue/${KEY}/comment?expand=renderedBody&orderBy=+created
```

Capture each comment's author, created date, and `renderedBody` (HTML). If there are many comments (>20), keep all but summarize older ones more aggressively in the final output.

## Step 4 — Pull linked issues (one level)

For each entry in `fields.subtasks` and `fields.issuelinks`, fetch a lightweight view:
```
GET ${JIRA_BASE_URL}/rest/api/3/issue/${LINKED_KEY}?fields=summary,status,issuetype,resolution
```
Do NOT recurse further. Skip if the linked key is the same as the main issue.

## Step 5 — Find Confluence links

Search the rendered description + all rendered comment bodies for Confluence URLs. Patterns to match (case-insensitive):

- `https://<host>/wiki/spaces/<SPACE>/pages/<PAGE_ID>(/<title-slug>)?`
- `https://<host>/wiki/x/<SHORT_ID>` (short link — needs resolution via HTTP redirect)
- `https://<host>/wiki/display/<SPACE>/<title>` (legacy)

Where `<host>` is the host part of `JIRA_BASE_URL` (e.g. `saasjet.atlassian.net`). Deduplicate the set of URLs.

Also check Jira "remote links":
```
GET ${JIRA_BASE_URL}/rest/api/3/issue/${KEY}/remotelink
```
Include any whose `object.url` is a Confluence URL.

## Step 6 — Fetch each Confluence page

For each unique Confluence URL:

1. **Resolve the page id.**
   - If the URL contains `/pages/<PAGE_ID>` → use that id directly.
   - If it is a short link `/wiki/x/<SHORT_ID>` → follow redirects (PowerShell `Invoke-WebRequest -MaximumRedirection 5`) and parse `pageId` from the final URL.
   - If it is a legacy `/wiki/display/<SPACE>/<title>` link → use `GET /wiki/rest/api/content?spaceKey=<SPACE>&title=<title>` to look up the id.

2. **Fetch page content via Confluence Cloud REST API:**
   ```
   GET ${JIRA_BASE_URL}/wiki/api/v2/pages/${PAGE_ID}?body-format=storage
   ```
   Same Basic auth. The response includes `title`, `body.storage.value` (XHTML). Strip tags for readability when summarizing.

3. If the v2 endpoint returns 404, fall back to v1:
   ```
   GET ${JIRA_BASE_URL}/wiki/rest/api/content/${PAGE_ID}?expand=body.view,version,space
   ```

4. If a page returns 403, note "No access to <URL>" in the output and continue — do not abort the whole analysis.

## Step 7 — Produce the analysis

Output to the user in this structure (use Markdown headings). Keep it scannable, do not dump raw HTML.

```
## <KEY> — <Summary>
Status · Type · Priority · Assignee · Reporter · Sprint (if any)

### Description summary
<3–6 sentence plain-language summary of what the ticket is asking for or reports>

### Acceptance criteria
- <bulletized AC, either from a dedicated AC field or inferred from the description>
- ...
(If none stated, say "Not explicitly defined" and list what an implementer would reasonably need to verify.)

### Discussion (comments)
- <author, date>: <one-line takeaway>
- ...
Decisions reached: <…>
Open questions: <…>

### Related issues
- Parent: <KEY — summary — status> (if any)
- Sub-tasks: <KEY — summary — status>
- Linked: <link-type> <KEY — summary — status>

### Confluence context
For each page:
#### <Page title> (<short URL>)
<4–8 sentence summary of the page, focused on what is relevant to this ticket — specs, decisions, diagrams referenced, constraints>
Key points:
- ...

### Full context — what needs to be done / what was done
<Synthesis paragraph that combines ticket + comments + Confluence into a single picture: the goal, the constraints, the current state, anything ambiguous or missing.>
```

## Error handling

- 401 → token is wrong/expired. Tell the user to refresh `JIRA_API_TOKEN` in the `.env`.
- 404 on the main issue → wrong key or no permission. Show the key and stop.
- Confluence link returns 403 → list the URL with "no access" and continue.
- `.env` missing → tell the user the expected path and stop.

## What NOT to do

- Do not write, comment, transition, or label anything in Jira or Confluence. This skill is read-only.
- Do not paste `JIRA_API_TOKEN` into any output.
- Do not recurse linked issues more than one level deep — it explodes quickly.
- Do not fetch attachments unless the user asks; just list their filenames.
