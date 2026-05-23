<#
.SYNOPSIS
    Walk one USB-connected RAK4631 Meshtastic node through the standard ChiMesh provisioning steps.

.DESCRIPTION
    Uses the `meshtastic` Python CLI to set region, role, channel-zero name,
    and owner name on whichever Meshtastic device is on the first serial port
    the CLI finds. The channel PSK is left at the Meshtastic default — generate
    one separately when you're ready for the deployment phase. Idempotent —
    re-running on an already-provisioned node is safe and just confirms the
    existing values.

    Prereq:  pip install --upgrade meshtastic

.PARAMETER NodeName
    Short owner / display name for the node, e.g. chimesh-001. Required.

.PARAMETER Region
    LoRa region code. Default: US. Other accepted values: EU_868, AU_915, AS_923.

.PARAMETER Role
    Device role. Default: ROUTER_CLIENT. Other accepted values: CLIENT, ROUTER,
    CLIENT_MUTE. For fixed proof-of-mesh nodes use ROUTER_CLIENT.

.PARAMETER Channel
    Channel-zero name. Default: ChiMesh-Test. The PSK is left at Meshtastic's
    default until you generate one for the deployment phase.

.PARAMETER Port
    Optional explicit serial port (e.g. COM5). If omitted the CLI auto-detects.

.EXAMPLE
    .\provision-node.ps1 -NodeName chimesh-001

.EXAMPLE
    .\provision-node.ps1 -NodeName chimesh-002 -Role ROUTER -Port COM7
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$NodeName,

    [ValidateSet('US', 'EU_868', 'AU_915', 'AS_923')]
    [string]$Region = 'US',

    [ValidateSet('ROUTER_CLIENT', 'CLIENT', 'ROUTER', 'CLIENT_MUTE')]
    [string]$Role = 'ROUTER_CLIENT',

    [string]$Channel = 'ChiMesh-Test',

    [string]$Port
)

$ErrorActionPreference = 'Stop'

function Write-Info($msg) { Write-Host ('-> ' + $msg) -ForegroundColor Cyan }
function Write-Ok($msg)   { Write-Host ('OK  ' + $msg) -ForegroundColor Green }
function Write-Warn2($msg){ Write-Host ('!!  ' + $msg) -ForegroundColor Yellow }
function Write-Err2($msg) { Write-Host ('XX  ' + $msg) -ForegroundColor Red }

# 1. Ensure the CLI is available.
$cli = Get-Command meshtastic -ErrorAction SilentlyContinue
if (-not $cli) {
    Write-Err2 "'meshtastic' CLI not on PATH. Install with:  pip install --upgrade meshtastic"
    exit 1
}
Write-Info ('using ' + $cli.Source)

# 2. Build the port-selector argument once and reuse it.
$portArgs = @()
if ($Port) { $portArgs = @('--port', $Port) }

# 3. Confirm a node is actually connected before we try to write anything.
Write-Info 'checking for a connected Meshtastic node ...'
$info = & meshtastic @portArgs --info 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Err2 'no Meshtastic node detected on USB. Plug in the RAK19003 USB-C and retry.'
    Write-Host $info
    exit 2
}
Write-Ok 'node responding'

# 4. Push config in one pass — the CLI batches --set / --ch-set arguments.
Write-Info ("setting region={0}, role={1}, owner={2}, channel0={3}" -f $Region, $Role, $NodeName, $Channel)
$setArgs = @(
    '--set', "lora.region=$Region",
    '--set', "device.role=$Role",
    '--ch-set', "name=$Channel", '--ch-index', '0',
    '--set-owner', $NodeName
) + $portArgs

& meshtastic @setArgs
if ($LASTEXITCODE -ne 0) {
    Write-Err2 'config write failed. The node may need a power-cycle; re-run after it reboots.'
    exit 3
}

# The CLI reboots the node after writes. Poll `--info` rather than guess at
# a fixed sleep: nRF52840 reboots in ~2 s typically, but USB-CDC re-enumeration
# can take up to ~8 s on some Windows hosts. Retry up to 5×2s before giving up.
Write-Info 'waiting for node to come back from reboot ...'
$confirm = $null
for ($i = 0; $i -lt 5; $i++) {
    Start-Sleep -Seconds 2
    $confirm = & meshtastic @portArgs --info 2>&1
    if ($LASTEXITCODE -eq 0) { break }
}
if ($LASTEXITCODE -ne 0) {
    Write-Warn2 'read-back failed after 10s (node may still be rebooting). Try `meshtastic --info` again in 10s.'
    exit 0
}

# 5. Read back and confirm. Word-boundary anchor on Region and Role so short
# tokens like 'US' don't false-match against substrings ('USB', 'USE', etc.)
# in the verbose `--info` output. Channel name is user-chosen and can contain
# arbitrary punctuation, so it stays a plain escaped substring match.
$confirmText = $confirm -join "`n"
$regionOk  = $confirmText -match ('\b' + [regex]::Escape($Region) + '\b')
$roleOk    = $confirmText -match ('\b' + [regex]::Escape($Role)   + '\b')
$channelOk = $confirmText -match [regex]::Escape($Channel)

Write-Info 'reading back config ...'

if ($regionOk -and $roleOk -and $channelOk) {
    Write-Ok ("provisioned: $NodeName  ($Region / $Role / channel `"$Channel`")")
    Write-Info 'next: repeat for each remaining node, then move on to section 06 (Deploy) in ChiMesh.md'
    exit 0
} else {
    Write-Warn2 'partial success — re-read with `meshtastic --info` and verify manually:'
    if (-not $regionOk)  { Write-Warn2 "  region not confirmed (wanted $Region)" }
    if (-not $roleOk)    { Write-Warn2 "  role not confirmed (wanted $Role)" }
    if (-not $channelOk) { Write-Warn2 "  channel name not confirmed (wanted $Channel)" }
    exit 4
}
