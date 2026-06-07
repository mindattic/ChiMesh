<#
  SessionStart hook — inject the ChiMesh bible digest as authoritative context.
  Reads docs/BIBLE.digest.md and emits Claude Code SessionStart hook JSON.
  If the digest is missing/empty, emits {}.
  Escapes all non-ASCII to \uXXXX so the JSON is safe under Windows PowerShell 5.1 / Win-1252.
#>
$ErrorActionPreference = 'Stop'

# repo root is two levels up from .claude/hooks
$root   = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$digest = Join-Path $root 'docs\BIBLE.digest.md'

if (-not (Test-Path $digest)) { Write-Output '{}'; exit 0 }

$body = [System.IO.File]::ReadAllText($digest)
if (-not $body -or $body.Trim().Length -eq 0) { Write-Output '{}'; exit 0 }

$preamble = @"
[ChiMesh Codex — AUTHORITATIVE SESSION CONTEXT]
The following is the project's canonical bible digest (generated from docs/BIBLE.md).
Treat it as the source of truth for what ChiMesh is, is NOT, and its Laws. When this digest and
any other context disagree, the digest (and the full docs/BIBLE.md it summarizes) wins. Project
code: CM. Full detail: docs/BIBLE.md; change log: docs/AMENDMENTS.md (amendment wins over bible);
stories: docs/USER_STORIES.md; org-wide rules: MindAttic.HouseRules.md.

"@

$context = $preamble + $body

# Build JSON with a manual escaper so we never depend on ConvertTo-Json's unicode handling.
$sb = New-Object System.Text.StringBuilder
foreach ($ch in $context.ToCharArray()) {
    $code = [int]$ch
    switch ($ch) {
        '"'  { [void]$sb.Append('\"') }
        '\'  { [void]$sb.Append('\\') }
        "`b" { [void]$sb.Append('\b') }
        "`f" { [void]$sb.Append('\f') }
        "`n" { [void]$sb.Append('\n') }
        "`r" { [void]$sb.Append('\r') }
        "`t" { [void]$sb.Append('\t') }
        default {
            if ($code -lt 32 -or $code -gt 126) {
                [void]$sb.Append('\u' + $code.ToString('x4'))
            } else {
                [void]$sb.Append($ch)
            }
        }
    }
}
$escaped = $sb.ToString()

$json = '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"' + $escaped + '"}}'
Write-Output $json
exit 0
