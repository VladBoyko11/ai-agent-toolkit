---
name: bitbucket-api
description: Read Bitbucket Cloud data (pipelines, pipeline step logs, pull requests, PR diffs/comments, commits, build statuses, branches, source files) through the Bitbucket REST API using the user's saved API token — never through a browser. Use whenever the user shares a bitbucket.org link or asks to look at / check / debug a Bitbucket pipeline, build, failed step, deploy, PR, or commit ("подивись пайплайн", "чому впав білд", "глянь пр у бітбакеті", "check the pipeline", "why did the build fail").
---

# Bitbucket via REST API

Always use the API, not the browser: bitbucket.org pages are auth-gated and the browsers are not logged in.

## Credentials

User env vars `BITBUCKET_EMAIL` (Atlassian account email) and `BITBUCKET_API_TOKEN` (Atlassian API token, Basic auth `email:token`).
The helper reads them from the process env or, if missing, from the persisted User scope — no app restart needed.

- Never print, echo, log, or write the token to a file. Check presence only (`[bool]`/length).
- If the helper exits with code 2 (vars missing) or HTTP 401/403, stop and tell the user: the token is missing, expired, or lacks scopes (`read:repository:bitbucket`, `read:pipeline:bitbucket`, `read:pullrequest:bitbucket`; writes need the matching `write:*`).

## Helper

`~/.claude/skills/bitbucket-api/scripts/bb.ps1 <api-path | full api url> [-OutFile <file>] [-Method GET|POST|PUT|DELETE] [-Data <json>]`

Run it from the PowerShell tool:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME\.claude\skills\bitbucket-api\scripts\bb.ps1" repositories/saasjet/react-ui/pipelines/1255
```

- The path is relative to `https://api.bitbucket.org/2.0/`. JSON goes to stdout, so pipe it to `ConvertFrom-Json` and print only the fields you need.
- UUIDs with `{}` can be passed raw; the helper disables curl globbing.
- Save logs and diffs with `-OutFile` (use the scratchpad dir), then read them with `Get-Content -Encoding UTF8 -Tail N` or the Read tool. Without `-Encoding UTF8`, Windows PowerShell mangles emoji and Cyrillic.
- Non-GET methods change shared state. Show the user exactly what you will send and get an explicit yes first.

## Web URL → API path

`{ws}/{repo}` = the first two path segments of the bitbucket.org URL.

| Web URL | API path |
|---|---|
| `/pipelines/results/{n}` | `repositories/{ws}/{repo}/pipelines/{n}` |
| `/pipelines/results/{n}/steps/{uuid}` | `.../pipelines/{n}/steps/{uuid}` and `.../steps/{uuid}/log` (plain text) |
| (steps list) | `.../pipelines/{n}/steps?pagelen=100` |
| (recent pipelines) | `.../pipelines?sort=-created_on&pagelen=10`, optionally `&target.branch={branch}` |
| `/pull-requests/{id}` | `repositories/{ws}/{repo}/pullrequests/{id}`, plus `/diff`, `/diffstat`, `/comments`, `/commits`, `/statuses`, `/activity` |
| (open PRs) | `.../pullrequests?state=OPEN` |
| `/commits/{hash}` | `.../commit/{hash}`, `.../commit/{hash}/statuses` |
| `/src/{ref}/{path}` | `.../src/{ref}/{path}` (raw file) |
| `/branch/{name}` | `.../refs/branches/{name}` |

Collections are paginated: follow the `next` URL when you need more than one page (`pagelen` max is 100, or 50 for PRs).

## Debugging a failed pipeline

1. Fetch the pipeline: report `state.name`, `state.result.name`, `target.ref_name`, `target.selector.pattern` (the custom pipeline name, if any), and `trigger`.
2. List the steps and find the ones with `state.result.name` `FAILED` or `ERROR`. The rest are usually `NOT_RUN` because they depend on the failed step.
3. Download the failed step's `/log` with `-OutFile` and read the tail (about 150 lines). Then search for the first real error (`error`, `ERR!`, `failed`, `exit code`), since the tail is often just teardown noise.
4. The effective config may not be the repo's `bitbucket-pipelines.yml`. The step JSON shows the real `image` and `script_commands`. The pipeline's `configuration_sources` lists `STATIC_LOCAL` (the repo yml) plus any `DYNAMIC_REPOSITORY` or `DYNAMIC_WORKSPACE` entries, which are workspace dynamic-pipeline providers that inject or override pipelines. Their `uri` is a presigned S3 URL valid for about 15 minutes, so fetch it with plain `curl.exe` and no auth. A step-level `image` overrides the global one.
5. Map the error to the repo: check `bitbucket-pipelines.yml` (it may reference shared pipes or scripts), `package.json` engines and scripts, and the lockfile. If a local clone exists (for example `~/Documents/vladsaasjet/{repo}`), read it there rather than through the API.
6. Report: the failing step, the exact error line(s) quoted from the log, the root cause, and the concrete fix (file and change).
