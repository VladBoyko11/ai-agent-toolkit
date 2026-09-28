<#
.SYNOPSIS
  Authenticated Bitbucket Cloud REST API call using BITBUCKET_EMAIL + BITBUCKET_API_TOKEN.

.EXAMPLE
  bb.ps1 repositories/saasjet/react-ui/pipelines/1255
  bb.ps1 "repositories/saasjet/react-ui/pipelines/1255/steps/{uuid}/log" -OutFile "$env:TEMP\step.log"
  bb.ps1 repositories/saasjet/react-ui/pullrequests/42/comments -Method POST -Data '{"content":{"raw":"hi"}}'
#>
param(
  [Parameter(Mandatory, Position = 0)][string]$Path,
  [string]$OutFile,
  [ValidateSet('GET', 'POST', 'PUT', 'DELETE')][string]$Method = 'GET',
  [string]$Data
)

$ErrorActionPreference = 'Stop'

# Process env first, then the persisted User scope (so a session started before the vars were set still works).
function Get-Var([string]$Name) {
  $v = [Environment]::GetEnvironmentVariable($Name, 'Process')
  if (-not $v) { $v = [Environment]::GetEnvironmentVariable($Name, 'User') }
  $v
}

$email = Get-Var 'BITBUCKET_EMAIL'
$token = Get-Var 'BITBUCKET_API_TOKEN'
if (-not $email -or -not $token) {
  Write-Error 'BITBUCKET_EMAIL and/or BITBUCKET_API_TOKEN are not set (User env vars).'
  exit 2
}

$url = if ($Path -match '^https?://') { $Path } else { 'https://api.bitbucket.org/2.0/' + $Path.TrimStart('/') }

# -g: step/pipeline UUIDs contain {} which curl would otherwise treat as globs.
# -L: log endpoints redirect to storage; curl drops credentials on cross-host redirects.
$curlArgs = @('-sS', '-g', '-L', '--fail-with-body', '-X', $Method, '-u', "${email}:${token}")
if ($Data) { $curlArgs += @('-H', 'Content-Type: application/json', '--data-raw', $Data) }
if ($OutFile) { $curlArgs += @('-o', $OutFile) }
$curlArgs += $url

& curl.exe @curlArgs
$code = $LASTEXITCODE
if ($OutFile -and $code -eq 0) { Write-Output "Saved to $OutFile ($((Get-Item $OutFile).Length) bytes)" }
exit $code
