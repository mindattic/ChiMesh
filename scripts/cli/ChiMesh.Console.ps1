<#
.SYNOPSIS
    ChiMesh console — local builder tasks for the guide + USB-connected
    Meshtastic node management.

.DESCRIPTION
    Single entry point for:
      - Local dev: install Node deps, render ChiMesh.htm from ChiMesh.md,
        bump version stamp, FTP-deploy to mindattic.com/chimesh/, browse
        parts catalog and apply chosen URLs into the guide.
      - Node management: provision a freshly-flashed RAK4631 (set region,
        role, channel, owner) and run a quick healthcheck against the
        connected node.

    Meshtastic nodes are microcontrollers — there is no SSH, no system
    services, no shell on the device. Everything node-side goes through
    the `meshtastic` Python CLI over USB. Install once:
        pip install --upgrade meshtastic

    Run without arguments for an interactive menu. Run with a command name
    to dispatch directly. Commands are dispatch-table-driven so adding a
    new one is one entry away.

.PARAMETER Command
    The command to run. See 'help' for the current list.

.PARAMETER Rest
    Positional arguments for the command.

.EXAMPLE
    .\scripts\cli\ChiMesh.Console.ps1                              # interactive menu
    .\scripts\cli\ChiMesh.Console.ps1 build-html
    .\scripts\cli\ChiMesh.Console.ps1 provision chimesh-001
    .\scripts\cli\ChiMesh.Console.ps1 healthcheck
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Command,

    [Parameter(Position = 1, ValueFromRemainingArguments = $true)]
    [string[]]$Rest
)

$ErrorActionPreference = 'Stop'
# $PSScriptRoot is scripts/cli; the repo root is two levels up.
$repoRoot   = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$configDir  = Join-Path $repoRoot 'config'

# Windows PowerShell 5.1's "-Encoding UTF8" writes UTF-8 *with* BOM, which
# breaks JSON parsers (npm, node, jq). Use this helper for every JSON / file
# write so output is portable.
function Write-Utf8NoBom([string]$Path, [string]$Content) {
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
}

function Write-Info($msg) { Write-Host ('-> ' + $msg) -ForegroundColor Cyan }
function Write-Ok($msg)   { Write-Host ('OK  ' + $msg) -ForegroundColor Green }
function Write-Warn2($msg){ Write-Host ('!!  ' + $msg) -ForegroundColor Yellow }
function Write-Err2($msg) { Write-Host ('XX  ' + $msg) -ForegroundColor Red }

# --- Local builder commands ----------------------------------------------
function Cmd-Update($a) {
    $clean = $a -contains '--clean'

    if (-not (Get-Command node -ErrorAction SilentlyContinue) -or
        -not (Get-Command npm  -ErrorAction SilentlyContinue)) {
        throw "Node.js / npm not found on PATH. Install from https://nodejs.org."
    }
    Write-Info ("node {0}   npm {1}" -f (& node --version), (& npm --version))

    $pkgPath = Join-Path $repoRoot 'package.json'
    if (-not (Test-Path $pkgPath)) {
        throw "package.json missing at $pkgPath."
    }

    Push-Location $repoRoot
    try {
        if ($clean) {
            $nm   = Join-Path $repoRoot 'node_modules'
            $lock = Join-Path $repoRoot 'package-lock.json'
            if (Test-Path $nm)   { Write-Info 'removing node_modules';      Remove-Item $nm -Recurse -Force }
            if (Test-Path $lock) { Write-Info 'removing package-lock.json'; Remove-Item $lock -Force }
        }
        Write-Info 'npm install'
        & npm install --no-audit --no-fund
        if ($LASTEXITCODE -ne 0) { throw "npm install failed (exit $LASTEXITCODE)" }
    } finally { Pop-Location }
    Write-Ok 'deps ready'
}

function Cmd-BuildHtml($a) {
    $script = Join-Path $PSScriptRoot 'build-html.ps1'
    if ($a -and $a.Count -gt 0) { & $script -Source $a[0] } else { & $script }
}

function Cmd-Deploy($a) {
    $script = Join-Path $PSScriptRoot 'deploy.ps1'
    if (-not (Test-Path $script)) { throw "Missing deploy.ps1 at $script" }
    if ($a -contains '--no-build') { & $script -NoBuild } else { & $script }
    if ($LASTEXITCODE -ne 0) { throw "deploy failed (exit $LASTEXITCODE)" }
    Write-Ok 'deploy complete.'
}

function Cmd-Bump($a) {
    $script = Join-Path $PSScriptRoot 'bump-version.ps1'
    if ($a -and $a.Count -gt 0) { & $script -To $a[0] } else { & $script }
}

# --- Node-side commands (Meshtastic over USB) ----------------------------
function Cmd-Provision($a) {
    if (-not $a -or $a.Count -lt 1) {
        throw "Usage: provision <node-name> [-Region US] [-Role ROUTER_CLIENT] [-Channel ChiMesh-Test] [-Port COMx]"
    }
    $script = Join-Path $PSScriptRoot 'provision-node.ps1'
    # Pass first positional as -NodeName; let the rest fall through as named params.
    & $script -NodeName $a[0] @($a | Select-Object -Skip 1)
}

function Cmd-Healthcheck($a) {
    $script = Join-Path $PSScriptRoot 'healthcheck-mesh.ps1'
    & $script @a
}

# --- Parts catalog walker ------------------------------------------------
function Read-PartsCatalog {
    $path = Join-Path $configDir 'parts.json'
    if (-not (Test-Path $path)) { throw "config/parts.json not found." }
    return Get-Content $path -Raw | ConvertFrom-Json
}

function Write-PartsCatalog($catalog) {
    $path = Join-Path $configDir 'parts.json'
    Write-Utf8NoBom -Path $path -Content ($catalog | ConvertTo-Json -Depth 10)
}

function Open-Url($url) {
    if (-not $url) { return }
    Start-Process $url | Out-Null
    Start-Sleep -Milliseconds 350
}

function Cmd-FindDeals($a) {
    $catalog = Read-PartsCatalog
    $filterCategory = $null
    if ($a -and $a.Count -ge 1 -and $a[0] -ne '--all') { $filterCategory = $a[0] }

    $parts = $catalog.parts
    if ($filterCategory) {
        $parts = $parts | Where-Object { $_.category -eq $filterCategory }
        if (-not $parts) { Write-Warn2 "no parts in category '$filterCategory'"; return }
    }

    Write-Info ("walking " + $parts.Count + " parts. Priority: Search -> Official -> Amazon -> Reputable.")
    Write-Warn2 "browser tabs will open per part. Pick the best deal, then paste the URL back here."
    Write-Host ""

    if (-not $catalog.chosen) {
        $catalog | Add-Member -NotePropertyName chosen -NotePropertyValue ([pscustomobject]@{}) -Force
    }

    foreach ($p in $parts) {
        Write-Host ""
        Write-Host ("=== " + $p.name + "  [" + $p.category + "]") -ForegroundColor Cyan
        if ($p.note) { Write-Host ("    note: " + $p.note) -ForegroundColor DarkGray }

        if ($p.searchFor) {
            Write-Host "    Search for ... (opening)"
            Open-Url $p.searchFor
        }

        $byTier = $p.tiers | Group-Object tier | ForEach-Object { @{ Key = $_.Name; Items = $_.Group } }
        foreach ($tierName in @('official', 'amazon', 'reputable')) {
            $bucket = $byTier | Where-Object { $_.Key -eq $tierName }
            if (-not $bucket) { continue }
            foreach ($t in $bucket.Items) {
                Write-Host ("    " + $tierName.PadRight(10) + " " + $t.url)
                Open-Url $t.url
            }
        }

        $pick = Read-Host "    pick (paste URL, ENTER to skip, 's' to stop)"
        if ($pick -eq 's' -or $pick -eq 'stop') { break }
        if ($pick) {
            $catalog.chosen | Add-Member -NotePropertyName $p.id -NotePropertyValue $pick -Force
            Write-Ok ("saved " + $p.id + " -> " + $pick)
        }
    }

    Write-PartsCatalog $catalog
    Write-Host ""
    Write-Ok "choices saved to config/parts.json."
}

function Cmd-ListParts {
    $catalog = Read-PartsCatalog
    foreach ($cat in $catalog.categories.PSObject.Properties.Name) {
        $catParts = $catalog.parts | Where-Object { $_.category -eq $cat }
        if (-not $catParts) { continue }
        Write-Host ""
        Write-Host ("[$cat] " + $catalog.categories.$cat) -ForegroundColor Cyan
        foreach ($p in $catParts) {
            $chosen = if ($catalog.chosen) { $catalog.chosen.($p.id) } else { $null }
            $status = if ($chosen) { 'chosen: ' + $chosen } else { '(no URL chosen yet)' }
            Write-Host ("  - " + $p.name + "  ~`$" + $p.price)
            Write-Host ("      " + $status) -ForegroundColor DarkGray
        }
    }
    Write-Host ""
}

function Cmd-PullLatest($a) {
    $force = $a -contains '--force'

    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        throw "git not found on PATH."
    }

    Push-Location $repoRoot
    try {
        Write-Info 'git fetch'
        & git fetch --all --prune
        if ($LASTEXITCODE -ne 0) { throw "git fetch failed (exit $LASTEXITCODE)" }

        $branch = (& git rev-parse --abbrev-ref HEAD).Trim()
        $upstream = & git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>$null
        if (-not $upstream) {
            Write-Warn2 "no upstream set for branch '$branch'"
            return
        }
        Write-Info "branch: $branch   upstream: $upstream"

        $ahead  = [int]((& git rev-list --count "$upstream..HEAD")  -join '')
        $behind = [int]((& git rev-list --count "HEAD..$upstream")  -join '')
        Write-Info ("ahead $ahead   behind $behind")

        if ($behind -eq 0) { Write-Ok 'already up to date.'; return }

        $dirty = (& git status --porcelain) -join "`n"
        if ($dirty -and -not $force) {
            Write-Warn2 'working tree is dirty:'
            Write-Host $dirty
            Write-Warn2 're-run as `pull-latest --force` to overwrite, or commit/stash first.'
            return
        }
    } finally { Pop-Location }

    # Stage the new tree in TEMP, then hand off to a detached helper so the
    # live .ps1 file isn't held open while files get copied over.
    $stamp   = (Get-Date).ToString('yyyyMMdd_HHmmss')
    $stage   = Join-Path ([System.IO.Path]::GetTempPath()) ("chimesh-update-" + $stamp)
    $helper  = Join-Path ([System.IO.Path]::GetTempPath()) ("chimesh-update-" + $stamp + ".ps1")
    $logPath = Join-Path $repoRoot '.claude\pull-latest.log'
    if (-not (Test-Path (Split-Path $logPath))) { New-Item -ItemType Directory -Path (Split-Path $logPath) | Out-Null }

    Write-Info ("staging into " + $stage)
    & git clone --quiet --branch (& git -C $repoRoot rev-parse --abbrev-ref HEAD).Trim() "$repoRoot" "$stage"
    if ($LASTEXITCODE -ne 0) { throw "stage clone failed" }

    Push-Location $stage
    try {
        & git fetch origin --quiet
        & git reset --hard ("origin/" + (& git rev-parse --abbrev-ref HEAD).Trim()) | Out-Null
    } finally { Pop-Location }

    $myPid = $PID
    $finisherSrc = Join-Path $PSScriptRoot 'pull-latest-finisher.ps1'
    if (-not (Test-Path $finisherSrc)) { throw "missing helper: $finisherSrc" }
    Copy-Item -Path $finisherSrc -Destination $helper -Force

    Write-Ok 'staged. spawning detached helper to finish the copy after this process exits.'
    Start-Process -FilePath 'powershell.exe' -ArgumentList @(
        '-NoProfile', '-ExecutionPolicy', 'Bypass', '-WindowStyle', 'Hidden',
        '-File', $helper,
        '-WaitPid', $myPid,
        '-Stage',   $stage,
        '-Repo',    $repoRoot,
        '-Log',     $logPath
    ) -WindowStyle Hidden | Out-Null

    Write-Warn2 'EXIT this Console now so locked files release. Then relaunch:  ChiMesh.Console.bat'
    Write-Warn2 "(Watch progress in $logPath)"
}

# --- Dispatch table ------------------------------------------------------
$commands = [ordered]@{
    'help'        = @{ Help = 'List available commands.';                                                           Action = { Show-Help } }
    'update'      = @{ Help = 'Install/refresh local Node deps. Add --clean to wipe node_modules.';                Action = { param($a) Cmd-Update $a } }
    'build-html'  = @{ Help = 'Render ChiMesh.md to ChiMesh.htm (self-contained).';                                Action = { param($a) Cmd-BuildHtml $a } }
    'deploy'      = @{ Help = 'Build + FTP-upload to mindattic.com/chimesh/. Add --no-build to skip the rebuild.'; Action = { param($a) Cmd-Deploy $a } }
    'bump'        = @{ Help = 'Stamp ChiMesh.md with today''s revision date (or -To <YYYY.MM.DD>) and rebuild.';   Action = { param($a) Cmd-Bump $a } }
    'provision'   = @{ Help = 'Provision a USB-connected RAK4631 node. Usage: provision <node-name> [-Region US] [-Role ROUTER_CLIENT] [-Channel ChiMesh-Test] [-Port COMx]'; Action = { param($a) Cmd-Provision $a } }
    'healthcheck' = @{ Help = 'Run end-to-end healthcheck against the USB-connected node.';                        Action = { param($a) Cmd-Healthcheck $a } }
    'list-parts'  = @{ Help = 'List parts catalog + which have a chosen URL.';                                     Action = { Cmd-ListParts } }
    'find-deals'  = @{ Help = 'Open Official/Amazon/Reputable tabs per part; save your picks. [core|consumable|--all]'; Action = { param($a) Cmd-FindDeals $a } }
    'pull-latest' = @{ Help = 'git fetch + overlay latest source. Add --force if working tree is dirty.';          Action = { param($a) Cmd-PullLatest $a } }
}

function Show-Help {
    Write-Host ""
    Write-Host "  ChiMesh Console" -ForegroundColor Cyan
    Write-Host "  ---------------"
    Write-Host ""
    Write-Host "  Commands:" -ForegroundColor Yellow
    foreach ($k in $commands.Keys) {
        Write-Host ("    {0,-13} {1}" -f $k, $commands[$k].Help)
    }
    Write-Host ""
    Write-Host "  Examples:" -ForegroundColor Yellow
    Write-Host "    ChiMesh.Console build-html"
    Write-Host "    ChiMesh.Console provision chimesh-001"
    Write-Host "    ChiMesh.Console healthcheck"
    Write-Host "    ChiMesh.Console find-deals core"
    Write-Host ""
}

function Invoke-ChiMeshCommand([string]$Name, [string[]]$Args2) {
    if (-not $commands.Contains($Name)) {
        Write-Err2 "unknown command: $Name"
        Show-Help
        exit 2
    }
    & $commands[$Name].Action $Args2
}

function Show-Menu {
    while ($true) {
        Show-Help
        $pick = Read-Host "Command (or 'quit')"
        if (-not $pick -or $pick -eq 'quit' -or $pick -eq 'exit' -or $pick -eq 'q') { return }
        $parts = $pick.Trim() -split '\s+', 2
        $cmd   = $parts[0]
        $rest2 = if ($parts.Count -gt 1) { $parts[1] -split '\s+' } else { @() }
        try {
            Invoke-ChiMeshCommand -Name $cmd -Args2 $rest2
        } catch {
            Write-Err2 $_.Exception.Message
        }
        Write-Host ""
        Read-Host "press ENTER to continue" | Out-Null
    }
}

if (-not $Command) { Show-Menu; exit 0 }
Invoke-ChiMeshCommand -Name $Command -Args2 $Rest
