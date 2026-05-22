<#
.SYNOPSIS
    PostToolUse hook: regenerate ChiMesh.htm whenever ChiMesh.md is edited.

.DESCRIPTION
    Reads the hook's JSON payload from stdin, checks whether the touched path is
    ChiMesh.md in this repo, and if so re-runs build-html.ps1 on it.

    Silent and non-blocking on the no-op path so it doesn't spam the session.
#>
$ErrorActionPreference = 'SilentlyContinue'

try {
    $payload = [Console]::In.ReadToEnd()
    if (-not $payload) { exit 0 }
    $json = $payload | ConvertFrom-Json -ErrorAction Stop
} catch {
    exit 0
}

$path = $json.tool_input.file_path
if (-not $path) { exit 0 }

# Only react to ChiMesh.md edits inside this repo.
$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$leaf = Split-Path -Leaf $path
if ($leaf -ne 'ChiMesh.md') { exit 0 }

try {
    $full = (Resolve-Path -LiteralPath $path -ErrorAction Stop).Path
} catch { exit 0 }

if (-not $full.StartsWith($repoRoot, [System.StringComparison]::OrdinalIgnoreCase)) { exit 0 }

# Re-render the HTML page. Log to a file so the session stays clean.
$log = Join-Path $repoRoot '.claude\html-rebuild.log'
$stamp = (Get-Date).ToString('s')
Add-Content -Path $log -Value "[$stamp] rebuilding $leaf"

& (Join-Path $PSScriptRoot 'build-html.ps1') -Source $full *>> $log
$buildExit = $LASTEXITCODE
Add-Content -Path $log -Value "[$stamp] build exit $buildExit"

# Mirror ChiMesh.htm -> index.htm so the local working tree matches what
# deploy.ps1 will publish (and so mindattic.com/chimesh/index.htm always has
# the latest content rather than an out-of-date redirect stub).
if ($buildExit -eq 0) {
    $chimeshHtm = Join-Path $repoRoot 'ChiMesh.htm'
    $indexFile  = Join-Path $repoRoot 'index.htm'
    if (Test-Path $chimeshHtm) {
        Copy-Item -Path $chimeshHtm -Destination $indexFile -Force
        Add-Content -Path $log -Value "[$stamp] mirrored ChiMesh.htm -> index.htm"
    }
}
exit 0
