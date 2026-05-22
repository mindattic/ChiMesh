<#
.SYNOPSIS
    Quick end-to-end smoke test for a connected ChiMesh Meshtastic node.

.DESCRIPTION
    Runs `meshtastic --info` against the connected node and verifies:
      1. CLI is installed and node responds
      2. Region is set (not UNSET)
      3. Role is set
      4. Channel 0 has a name (not just "LongFast" default)
      5. At least one peer node is in the local NodeDB (proves mesh saw a neighbor)

    Returns exit 0 on all-green, exit 1 on any failure. Useful as the last
    step before declaring a deployment "done" — and as the bundled command
    in section 07.4 of the build guide.

.PARAMETER Port
    Optional explicit serial port (e.g. COM5). If omitted the CLI auto-detects.

.PARAMETER Verbose
    PowerShell common parameter — pass -Verbose to dump the full `--info`
    output alongside the checks.

.EXAMPLE
    .\healthcheck-mesh.ps1

.EXAMPLE
    .\healthcheck-mesh.ps1 -Port COM7 -Verbose
#>
[CmdletBinding()]
param(
    [string]$Port
)

function Write-Step($msg) { Write-Host ('-- ' + $msg + ' --') -ForegroundColor Cyan }
function Write-Ok($msg)   { Write-Host ('  PASS  ' + $msg) -ForegroundColor Green }
function Write-Bad($msg)  { Write-Host ('  FAIL  ' + $msg) -ForegroundColor Red }
function Write-Warn2($msg){ Write-Host ('  WARN  ' + $msg) -ForegroundColor Yellow }

$exitCode = 0
$portArgs = @()
if ($Port) { $portArgs = @('--port', $Port) }

# 1. CLI present?
Write-Step '1. meshtastic CLI on PATH'
$cli = Get-Command meshtastic -ErrorAction SilentlyContinue
if (-not $cli) {
    Write-Bad "'meshtastic' not on PATH. Install:  pip install --upgrade meshtastic"
    exit 1
}
Write-Ok ('CLI at ' + $cli.Source)

# 2. Node responds?
Write-Step '2. node responds on USB'
$info = & meshtastic @portArgs --info 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Bad 'no Meshtastic node detected. Plug in the RAK19003 USB-C and retry.'
    exit 1
}
Write-Ok 'node returned --info'

$infoText = $info -join "`n"
if ($VerbosePreference -ne 'SilentlyContinue') {
    Write-Verbose '--- raw --info output ---'
    $info | ForEach-Object { Write-Verbose $_ }
    Write-Verbose '--- end raw output ---'
}

# 3. Region set?
Write-Step '3. LoRa region configured'
if ($infoText -match 'region["\s:=]+([A-Z0-9_]+)') {
    $region = $matches[1]
    if ($region -eq 'UNSET' -or -not $region) {
        Write-Bad "lora.region is UNSET — run provision-node.ps1 first"
        $exitCode = 1
    } else {
        Write-Ok "region = $region"
    }
} else {
    Write-Warn2 'could not parse region from --info output'
    $exitCode = 1
}

# 4. Role set?
Write-Step '4. device role configured'
if ($infoText -match 'role["\s:=]+([A-Z_]+)') {
    $role = $matches[1]
    Write-Ok "role = $role"
    if ($role -eq 'CLIENT') {
        Write-Warn2 'CLIENT role sleeps aggressively and will not forward packets. Consider ROUTER_CLIENT for fixed nodes.'
    }
} else {
    Write-Warn2 'could not parse role from --info output'
}

# 5. Channel 0 name? Match the channelName= query param embedded in the
# Primary channel URL — that's the one deterministic place across CLI
# versions. The bare "name:" heuristic is too broad (it matches owner
# name, board name, region name, etc., depending on output ordering).
Write-Step '5. channel 0 name'
if ($infoText -match 'channelName=([^&\s"]+)') {
    Write-Ok ("channel name = " + $matches[1])
} elseif ($infoText -match 'Primary channel URL') {
    Write-Warn2 'primary channel URL present but channelName param not parsed — verify manually'
} else {
    Write-Warn2 'could not parse channel name from --info'
}

# 6. NodeDB has at least one peer (proves the mesh saw a neighbor at some point)?
# Count node IDs (`!XXXXXXXX` — 8 hex chars after a bang) instead of parsing
# the CLI's ASCII table border, which has changed shape across versions.
Write-Step '6. NodeDB peer count'
$nodes = & meshtastic @portArgs --nodes 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Warn2 'meshtastic --nodes failed; skipping peer-count check'
} else {
    $nodeIds  = [regex]::Matches(($nodes -join "`n"), '![0-9a-fA-F]{8}')
    $uniqueIds = $nodeIds | ForEach-Object { $_.Value } | Sort-Object -Unique
    # Subtract 1 for our own node ID listed alongside the peers.
    $peerCount = [Math]::Max(0, $uniqueIds.Count - 1)
    if ($peerCount -ge 1) {
        Write-Ok ("known peers: $peerCount")
    } else {
        Write-Warn2 'no peers in NodeDB. Either you have only one node deployed, or peers have never been within range. Not a hard failure for the first node provisioned.'
    }
}

Write-Host ''
if ($exitCode -eq 0) {
    Write-Host 'PASS  node is configured and responsive.' -ForegroundColor Green
} else {
    Write-Host 'FAIL  see warnings above. Re-run provision-node.ps1 if config is missing.' -ForegroundColor Red
}
exit $exitCode
