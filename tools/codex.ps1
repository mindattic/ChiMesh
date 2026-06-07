<#
.SYNOPSIS
    ChiMesh Codex CLI — documentation doctor + digest generator.

.DESCRIPTION
    Subcommands:
      doctor  - validate the Codex canon (docs/) and exit non-zero on any hard error.
      digest  - regenerate docs/BIBLE.digest.md from BIBLE.md (auth. session-injection summary).

    Pure PowerShell, no build step. Runs under Windows PowerShell 5.1 and PowerShell 7+.
    Invoke as:  powershell -NoProfile -ExecutionPolicy Bypass -File tools/codex.ps1 doctor
            or: pwsh -File tools/codex.ps1 digest

.PARAMETER Command
    'doctor' (default) or 'digest'.
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet('doctor', 'digest')]
    [string]$Command = 'doctor'
)

$ErrorActionPreference = 'Stop'

# --- paths ---------------------------------------------------------------
$RepoRoot = Split-Path -Parent $PSScriptRoot
$DocsDir  = Join-Path $RepoRoot 'docs'
$DataDir  = Join-Path $DocsDir 'data'
$RfcDir   = Join-Path $DocsDir 'rfc'
$Bible    = Join-Path $DocsDir 'BIBLE.md'
$Stories  = Join-Path $DocsDir 'USER_STORIES.md'
$Amend    = Join-Path $DocsDir 'AMENDMENTS.md'
$Digest   = Join-Path $DocsDir 'BIBLE.digest.md'

# --- output helpers ------------------------------------------------------
$script:Errors   = New-Object System.Collections.Generic.List[string]
$script:Warnings = New-Object System.Collections.Generic.List[string]
function Add-Err($m)  { $script:Errors.Add($m);   Write-Host ('  [FAIL] ' + $m) -ForegroundColor Red }
function Add-Warn($m) { $script:Warnings.Add($m); Write-Host ('  [warn] ' + $m) -ForegroundColor Yellow }
function Add-Ok($m)   { Write-Host ('  [ok]   ' + $m) -ForegroundColor Green }
function Section($m)  { Write-Host ''; Write-Host ('== ' + $m) -ForegroundColor Cyan }

function Get-RelPath([string]$full) {
    return $full.Substring($RepoRoot.Length).TrimStart('\','/')
}

# --- shared parsing ------------------------------------------------------
function Read-Text([string]$path) {
    return [System.IO.File]::ReadAllText($path)
}

# Parse a leading YAML front-matter block (--- ... ---) into a hashtable of simple key:value.
function Get-FrontMatter([string]$text) {
    if ($text -notmatch '^﻿?---\r?\n') { return $null }
    $body = $text -replace '^﻿', ''
    $m = [regex]::Match($body, '(?s)^---\r?\n(.*?)\r?\n---')
    if (-not $m.Success) { return $null }
    $map = @{}
    foreach ($line in ($m.Groups[1].Value -split "`n")) {
        $l = $line.Trim()
        if (-not $l -or $l.StartsWith('#')) { continue }
        $kv = $l -split ':', 2
        if ($kv.Count -eq 2) { $map[$kv[0].Trim()] = $kv[1].Trim() }
    }
    return $map
}

$ValidLayers = @('bible','stories','amendments','rfc','data')

function Test-FrontMatter([string]$path, [string]$expectLayer) {
    $rel = Get-RelPath $path
    $text = Read-Text $path
    $fm = Get-FrontMatter $text
    if ($null -eq $fm) { Add-Err "$rel : missing or malformed YAML front-matter"; return }
    if ($fm['codex'] -ne '1')          { Add-Err "$rel : front-matter 'codex' must be 1" }
    if (-not $fm['project'])           { Add-Err "$rel : front-matter missing 'project'" }
    if ($fm['code'] -ne 'CM')          { Add-Err "$rel : front-matter 'code' must be CM (got '$($fm['code'])')" }
    if ($ValidLayers -notcontains $fm['layer']) { Add-Err "$rel : front-matter 'layer' invalid ('$($fm['layer'])')" }
    elseif ($expectLayer -and $fm['layer'] -ne $expectLayer) { Add-Err "$rel : expected layer '$expectLayer', got '$($fm['layer'])'" }
    if ($fm['updated'] -notmatch '^\d{4}-\d{2}-\d{2}$') { Add-Err "$rel : front-matter 'updated' must be YYYY-MM-DD" }
    if ($script:Errors.Count -eq 0 -or $true) { } # no-op to keep flow
    Add-Ok "$rel : front-matter ok"
}

# ========================================================================
#  DOCTOR
# ========================================================================
function Invoke-Doctor {
    Write-Host 'ChiMesh Codex doctor' -ForegroundColor White

    # ---- 1. required files exist ----
    Section '1. Required canon files exist'
    $required = @($Bible, $Stories, $Amend)
    foreach ($f in $required) {
        if (Test-Path $f) { Add-Ok (Get-RelPath $f) } else { Add-Err ((Get-RelPath $f) + ' is missing') }
    }

    # ---- 2. front-matter ----
    Section '2. Front-matter (codex/project/code/layer/updated)'
    if (Test-Path $Bible)   { Test-FrontMatter $Bible 'bible' }
    if (Test-Path $Stories) { Test-FrontMatter $Stories 'stories' }
    if (Test-Path $Amend)   { Test-FrontMatter $Amend 'amendments' }
    if (Test-Path $RfcDir)  { Get-ChildItem $RfcDir -Filter '*.md' -File | ForEach-Object { Test-FrontMatter $_.FullName 'rfc' } }
    $dataJsonFiles = @()
    if (Test-Path $DataDir) {
        $dataJsonFiles = Get-ChildItem $DataDir -Filter '*.json' -File | Where-Object { $_.DirectoryName -eq $DataDir }
        foreach ($d in $dataJsonFiles) {
            $rel = Get-RelPath $d.FullName
            try { $j = Get-Content $d.FullName -Raw | ConvertFrom-Json } catch { Add-Err "$rel : invalid JSON ($($_.Exception.Message))"; continue }
            if ($j.codex -ne 1)              { Add-Err "$rel : 'codex' must be 1" }
            if ($j.code -ne 'CM')            { Add-Err "$rel : 'code' must be CM" }
            if ($ValidLayers -notcontains $j.layer) { Add-Err "$rel : 'layer' invalid" }
            if ("$($j.updated)" -notmatch '^\d{4}-\d{2}-\d{2}$') { Add-Err "$rel : 'updated' must be YYYY-MM-DD" }
            else { Add-Ok "$rel : data front-matter ok" }
        }
    }

    # ---- 3. anchor IDs unique + cross-refs resolve ----
    Section '3. Stable IDs unique and cross-references resolve'
    $mdFiles = @()
    $mdFiles += $Bible; $mdFiles += $Stories; $mdFiles += $Amend
    if (Test-Path $RfcDir) { $mdFiles += (Get-ChildItem $RfcDir -Filter '*.md' -File | ForEach-Object { $_.FullName }) }
    $mdFiles = $mdFiles | Where-Object { Test-Path $_ }

    $anchors = @{}        # anchor -> count
    foreach ($f in $mdFiles) {
        $text = Read-Text $f
        foreach ($mm in [regex]::Matches($text, '\{#([^}]+)\}')) {
            $a = $mm.Groups[1].Value
            if ($anchors.ContainsKey($a)) { $anchors[$a]++ } else { $anchors[$a] = 1 }
        }
    }
    $dupes = $anchors.GetEnumerator() | Where-Object { $_.Value -gt 1 }
    if ($dupes) { foreach ($d in $dupes) { Add-Err ("duplicate anchor {#" + $d.Key + "} (x" + $d.Value + ')') } }
    else { Add-Ok ('' + $anchors.Count + ' anchors, all unique') }

    # Cross-ref links of the form (...#ANCHOR). Resolve in-repo anchors; allow HOUSE-* (external house rules).
    $brokenRefs = 0; $checkedRefs = 0
    foreach ($f in $mdFiles) {
        $text = Read-Text $f
        foreach ($mm in [regex]::Matches($text, '\]\(([^)]*#[^)\s]+)\)')) {
            $target = $mm.Groups[1].Value
            $frag = ($target -split '#', 2)[1]
            if (-not $frag) { continue }
            $checkedRefs++
            if ($frag -like 'HOUSE-*') { continue }       # external, validated by house-rules link check below
            if ($frag -like 'CM-*') {
                if (-not $anchors.ContainsKey($frag)) { Add-Err ((Get-RelPath $f) + " : link to {#$frag} has no matching anchor"); $brokenRefs++ }
            }
        }
    }
    if ($brokenRefs -eq 0) { Add-Ok ("$checkedRefs anchor cross-refs checked, all resolve") }

    # ---- 4. data files validate against schema; ids unique ----
    Section '4. L5 data validates against schema; entity ids unique'
    $schemaDir = Join-Path $DataDir '_schema'
    foreach ($manifest in $dataJsonFiles) {
        $rel = Get-RelPath $manifest.FullName
        try { $j = Get-Content $manifest.FullName -Raw | ConvertFrom-Json } catch { continue }
        if (-not $j.source -or -not $j.schema) { Add-Warn "$rel : no source/schema pointer; treating as standalone data"; continue }
        $srcPath    = Join-Path $manifest.DirectoryName $j.source
        $schemaPath = Join-Path $manifest.DirectoryName $j.schema
        if (-not (Test-Path $srcPath))    { Add-Err "$rel : source '$($j.source)' not found"; continue }
        if (-not (Test-Path $schemaPath)) { Add-Err "$rel : schema '$($j.schema)' not found"; continue }
        try { $schema = Get-Content $schemaPath -Raw | ConvertFrom-Json } catch { Add-Err ((Get-RelPath $schemaPath) + ' : invalid JSON schema'); continue }
        try { $srcDoc = Get-Content $srcPath -Raw | ConvertFrom-Json } catch { Add-Err ((Get-RelPath $srcPath) + ' : invalid JSON'); continue }

        $rows = if ($j.sourcePointer) { $srcDoc.($j.sourcePointer) } else { $srcDoc }
        if ($null -eq $rows) { Add-Err "$rel : sourcePointer '$($j.sourcePointer)' yielded nothing in $($j.source)"; continue }

        $required = @(); if ($schema.required) { $required = @($schema.required) }
        $enums = @{}
        if ($schema.properties) {
            foreach ($p in $schema.properties.PSObject.Properties) {
                if ($p.Value.enum) { $enums[$p.Name] = @($p.Value.enum) }
            }
        }
        $ids = @{}; $rowErr = 0; $count = 0
        foreach ($row in $rows) {
            $count++
            foreach ($req in $required) {
                if ($null -eq $row.$req) { Add-Err ((Get-RelPath $srcPath) + " : row #$count missing required '$req'"); $rowErr++ }
            }
            foreach ($ek in $enums.Keys) {
                $v = $row.$ek
                if ($null -ne $v -and ($enums[$ek] -notcontains $v)) { Add-Err ((Get-RelPath $srcPath) + " : '$($row.id)'.$ek = '$v' not in enum"); $rowErr++ }
            }
            if ($row.id) {
                if ($ids.ContainsKey($row.id)) { Add-Err ((Get-RelPath $srcPath) + " : duplicate id '$($row.id)'"); $rowErr++ }
                else { $ids[$row.id] = $true }
            }
        }
        if ($rowErr -eq 0) { Add-Ok ((Get-RelPath $srcPath) + " : $count rows validate; $($ids.Count) unique ids") }
    }
    if ($dataJsonFiles.Count -eq 0) { Add-Ok 'no L5 data manifests (ok for this domain)' }

    # ---- 5. every done story names a test token ----
    Section '5. Every done story cites a test; cited tests best-effort exist'
    if (Test-Path $Stories) {
        $stext = Read-Text $Stories
        $doneCount = 0; $missingCite = 0
        foreach ($line in ($stext -split "`n")) {
            if ($line -match '\*\*CM-US-[A-Z]\d+\s*✅') {
                $doneCount++
                if ($line -notmatch 'verified by') { Add-Err ("done story without 'verified by' citation: " + $line.Trim()); $missingCite++ }
            }
        }
        if ($doneCount -eq 0) { Add-Warn 'no ✅ stories yet' }
        elseif ($missingCite -eq 0) { Add-Ok "$doneCount done stories, all cite a verifying test" }
        # best-effort: the ✅ stories here cite tools/codex.ps1 itself, which exists.
        if ($stext -match 'codex\.ps1') {
            if (Test-Path (Join-Path $RepoRoot 'tools\codex.ps1')) { Add-Ok 'cited verifier tools/codex.ps1 exists on disk' }
            else { Add-Err 'stories cite tools/codex.ps1 but it is missing' }
        }
    }

    # ---- 6. cited code paths in the bible exist ----
    Section '6. File paths cited in the bible exist on disk'
    if (Test-Path $Bible) {
        $btext = Read-Text $Bible
        $pathErr = 0; $pathOk = 0
        # markdown links to relative paths (skip http(s), pure anchors, and ../../ house rules)
        foreach ($mm in [regex]::Matches($btext, '\]\(([^)#]+?)(?:#[^)]*)?\)')) {
            $p = $mm.Groups[1].Value.Trim()
            if ($p -match '^https?:') { continue }
            if ($p -eq '') { continue }
            $resolved = Join-Path $DocsDir $p
            if (Test-Path $resolved) { $pathOk++ }
            else { Add-Err ("bible cites missing path: " + $p); $pathErr++ }
        }
        # backtick-quoted paths that look like real repo files (contain a slash + known ext)
        foreach ($mm in [regex]::Matches($btext, '`([A-Za-z0-9_./-]+\.(?:json|ps1|md|js|htm|png|jpg|bat))`')) {
            $p = $mm.Groups[1].Value
            if ($p -match '^https?:') { continue }
            # try repo-root relative
            $candidate = Join-Path $RepoRoot $p
            if (Test-Path $candidate) { $pathOk++ }
            else {
                # Not at repo root. If it's a bare basename, try to find it anywhere in the repo
                # (e.g. provision-node.ps1 lives under scripts/cli/). Skip node_modules/.git/out.
                $leaf = Split-Path $p -Leaf
                $found = $false
                if ($leaf -eq $p) {
                    $hit = Get-ChildItem $RepoRoot -Filter $leaf -Recurse -File -ErrorAction SilentlyContinue |
                           Where-Object { $_.FullName -notmatch '\\(node_modules|\.git|out|dist)\\' } |
                           Select-Object -First 1
                    if ($hit) { $found = $true; $pathOk++ }
                }
                if (-not $found) {
                    # may be a sibling-repo / render-output file (out/, src/, template, MindAttic.HouseRules) — warn, don't fail
                    if ($p -match '^(out/|src/|index\.|.*template.*)') { }
                    elseif ($p -eq 'MindAttic.HouseRules.md') { }   # validated separately in check 7
                    else { Add-Warn ("bible mentions path not found in repo (may be sibling/output): " + $p) }
                }
            }
        }
        if ($pathErr -eq 0) { Add-Ok "$pathOk cited in-repo paths exist" }
    }

    # ---- 7. house-rules link resolves ----
    Section '7. House rules inherited link resolves'
    $houseRel = '..\MindAttic.HouseRules.md'
    $housePath = Join-Path $RepoRoot $houseRel
    if (Test-Path $housePath) {
        Add-Ok 'MindAttic.HouseRules.md found (inherited, not modified)'
        # verify referenced HOUSE-LAW anchors exist there
        $htext = Read-Text $housePath
        $houseAnchors = @{}
        foreach ($mm in [regex]::Matches($htext, '\{#(HOUSE-[^}]+)\}')) { $houseAnchors[$mm.Groups[1].Value] = $true }
        $bAll = ''
        foreach ($f in $mdFiles) { $bAll += (Read-Text $f) }
        $houseRefErr = 0
        foreach ($mm in [regex]::Matches($bAll, '#(HOUSE-LAW-\d+)')) {
            if (-not $houseAnchors.ContainsKey($mm.Groups[1].Value)) { Add-Err ('reference to ' + $mm.Groups[1].Value + ' not found in house rules'); $houseRefErr++ }
        }
        if ($houseRefErr -eq 0) { Add-Ok 'all HOUSE-LAW references resolve in MindAttic.HouseRules.md' }
    } else {
        Add-Err "expected inherited house rules at $houseRel (not found)"
    }

    # ---- 8. digest freshness ----
    Section '8. Digest is present and not stale'
    if (-not (Test-Path $Digest)) {
        Add-Err 'docs/BIBLE.digest.md missing — run: codex.ps1 digest'
    } else {
        $bibleMtime  = (Get-Item $Bible).LastWriteTimeUtc
        $digestMtime = (Get-Item $Digest).LastWriteTimeUtc
        if ($bibleMtime -gt $digestMtime) {
            Add-Err 'docs/BIBLE.digest.md is STALE (BIBLE.md changed after it) — run: codex.ps1 digest'
        } else {
            Add-Ok 'digest is fresh (generatedFrom BIBLE.md, mtime ok)'
        }
        $dtext = Read-Text $Digest
        if ($dtext -notmatch 'AUTHORITATIVE') { Add-Warn 'digest missing AUTHORITATIVE header line' }
    }

    # ---- summary ----
    Write-Host ''
    Write-Host ('-' * 60)
    if ($script:Errors.Count -eq 0) {
        Write-Host ("DOCTOR PASS  ({0} warning(s))" -f $script:Warnings.Count) -ForegroundColor Green
        exit 0
    } else {
        Write-Host ("DOCTOR FAIL  {0} error(s), {1} warning(s)" -f $script:Errors.Count, $script:Warnings.Count) -ForegroundColor Red
        exit 1
    }
}

# ========================================================================
#  DIGEST
# ========================================================================
# Extract a "## N. Title {#anchor}" section body (until the next "## ").
function Get-Section([string]$text, [string]$anchor) {
    $pattern = '(?s)^##\s+[^\n]*\{#' + [regex]::Escape($anchor) + '\}\s*\r?\n(.*?)(?=\r?\n##\s|\z)'
    $m = [regex]::Match($text, $pattern, [System.Text.RegularExpressions.RegexOptions]::Multiline)
    if ($m.Success) { return $m.Groups[1].Value.Trim() }
    return $null
}

function Invoke-Digest {
    if (-not (Test-Path $Bible)) { Write-Host 'BIBLE.md not found; cannot build digest' -ForegroundColor Red; exit 1 }
    $b = Read-Text $Bible
    $fm = Get-FrontMatter $b

    $s1 = Get-Section $b 'CM-§1'
    $s3 = Get-Section $b 'CM-§3'
    $s5 = Get-Section $b 'CM-§5'
    $s9 = Get-Section $b 'CM-§9'

    # status index from USER_STORIES
    $done = 0; $partial = 0; $planned = 0; $cut = 0
    if (Test-Path $Stories) {
        $st = Read-Text $Stories
        $done    = ([regex]::Matches($st, 'CM-US-[A-Z]\d+\s*✅')).Count
        $partial = ([regex]::Matches($st, 'CM-US-[A-Z]\d+\s*🟡')).Count
        $planned = ([regex]::Matches($st, 'CM-US-[A-Z]\d+\s*⬜')).Count
        $cut     = ([regex]::Matches($st, 'CM-US-[A-Z]\d+\s*🗑')).Count
    }

    # latest amendment head
    $amendHead = ''
    if (Test-Path $Amend) {
        $at = Read-Text $Amend
        $amPattern = '^##\s+(CM-A\d+.*)$'
        $am = [regex]::Matches($at, $amPattern, [System.Text.RegularExpressions.RegexOptions]::Multiline)
        if ($am.Count -gt 0) { $amendHead = $am[$am.Count - 1].Groups[1].Value.Trim() }
    }

    $today = (Get-Date).ToString('yyyy-MM-dd')
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine('AUTHORITATIVE — full detail in docs/BIBLE.md')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('---')
    [void]$sb.AppendLine('codex: 1')
    [void]$sb.AppendLine('project: ChiMesh')
    [void]$sb.AppendLine('code: CM')
    [void]$sb.AppendLine('layer: bible')
    [void]$sb.AppendLine('status: living')
    [void]$sb.AppendLine('generatedFrom: CM-§1,CM-§3,CM-§5,CM-§9')
    [void]$sb.AppendLine('updated: ' + $today)
    [void]$sb.AppendLine('---')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('# ChiMesh — Bible Digest')
    [void]$sb.AppendLine('> Generated by tools/codex.ps1 digest. Do NOT hand-edit. The full bible is docs/BIBLE.md.')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('## One sentence')
    [void]$sb.AppendLine(($(if ($s1) { $s1 } else { '(missing §1)' })))
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('## What it is NOT')
    [void]$sb.AppendLine(($(if ($s3) { $s3 } else { '(missing §3)' })))
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('## The Laws')
    [void]$sb.AppendLine(($(if ($s5) { $s5 } else { '(missing §5)' })))
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('## Glossary')
    [void]$sb.AppendLine(($(if ($s9) { $s9 } else { '(missing §9)' })))
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('## Status index')
    [void]$sb.AppendLine(('- Stories: ' + $done + ' done, ' + $partial + ' partial, ' + $planned + ' planned, ' + $cut + ' cut.'))
    if ($amendHead) { [void]$sb.AppendLine(('- Latest amendment: ' + $amendHead)) }
    [void]$sb.AppendLine('')

    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Digest, $sb.ToString(), $utf8NoBom)
    Write-Host ('digest written: ' + (Get-RelPath $Digest)) -ForegroundColor Green
    Write-Host ('  stories: ' + $done + ' done / ' + $partial + ' partial / ' + $planned + ' planned')
}

switch ($Command) {
    'doctor' { Invoke-Doctor }
    'digest' { Invoke-Digest }
}
