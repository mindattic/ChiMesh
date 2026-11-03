# pull-latest-finisher.ps1
# Spawned (detached + hidden) by ChiMesh.Console pull-latest.
# Waits for the Console PowerShell process to exit so it can release file
# handles on ChiMesh.Console.ps1, then fast-forwards the repo to the fetched
# upstream commit. Fast-forward only: if the tree became dirty or HEAD moved
# meanwhile, git refuses and nothing local is overwritten.

param(
    [Parameter(Mandatory)] [int]    $WaitPid,
    [Parameter(Mandatory)] [string] $Repo,
    [Parameter(Mandatory)] [string] $Sha,
    [Parameter(Mandatory)] [string] $Log
)

$ErrorActionPreference = 'Continue'

function Write-Log([string]$msg) {
    ('[' + (Get-Date -Format s) + '] ' + $msg) | Add-Content -Path $Log
}

Write-Log "helper start. waiting on PID $WaitPid"

# Wait for the launching PowerShell to release file handles.
$tries = 0
while ($tries -lt 240) {   # ~2 minutes max
    if (-not (Get-Process -Id $WaitPid -ErrorAction SilentlyContinue)) { break }
    Start-Sleep -Milliseconds 500
    $tries++
}
Write-Log ("parent gone after " + $tries + " waits. fast-forwarding " + $Repo + " to " + $Sha)

# Re-check: something may have changed the tree while the console was open.
$dirty = (& git -C $Repo status --porcelain 2>&1) -join "`n"
if ($dirty) {
    Write-Log ("REFUSED: working tree has uncommitted changes, nothing was touched:`n" + $dirty)
    exit 1
}

$out = (& git -C $Repo merge --ff-only $Sha 2>&1) -join "`n"
$code = $LASTEXITCODE
Write-Log $out
if ($code -ne 0) {
    Write-Log ("REFUSED: git merge --ff-only exited " + $code + "; local history was left as it was.")
    exit $code
}
Write-Log 'done.'
