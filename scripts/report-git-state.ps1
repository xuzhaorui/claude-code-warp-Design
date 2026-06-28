# report-git-state.ps1
# Git state report — outputs current branch, recent commits, scoped status.
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File scripts/report-git-state.ps1
#   powershell -ExecutionPolicy Bypass -File scripts/report-git-state.ps1 -Json

param([switch]$Json)

$projectRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$configPath = Join-Path $projectRoot "physical-gate.config.json"

# ---- Gather ----

$branch = & { git -C $projectRoot rev-parse --abbrev-ref HEAD 2>&1 }
$head   = & { git -C $projectRoot rev-parse HEAD 2>&1 }
$headShort = $head.Substring(0, 7)
$log    = & { git -C $projectRoot log --oneline -5 2>&1 }

$config = Get-Content $configPath | ConvertFrom-Json
$scoped = $config.scopedStatusPaths -join " "
$statusOutput = & { git -C $projectRoot status --short -- $scoped 2>&1 }
$dirtyFiles = @()
$allowedDirty = @()
$unexpectedDirty = @()

$statusLines = $statusOutput | Where-Object { $_ -match '^[ MADRC?!]' }
foreach ($line in $statusLines) {
    $file = ($line -replace '^.. ', '').Trim()
    $dirtyFiles += $file
    $isAllowed = $false
    foreach ($pattern in $config.allowedDirty) {
        if ($file -like $pattern) { $isAllowed = $true; break }
    }
    if ($isAllowed) {
        $allowedDirty += $file
    } else {
        $unexpectedDirty += $file
    }
}

$diffStat = & { git -C $projectRoot diff --stat -- $scoped 2>&1 }

# ---- Output ----

if ($Json) {
    $report = @{
        branch = $branch
        head = $head
        recentCommits = @($log)
        dirtyFiles = $dirtyFiles
        allowedDirty = $allowedDirty
        unexpectedDirty = $unexpectedDirty
        clean = ($unexpectedDirty.Count -eq 0)
    }
    $report | ConvertTo-Json -Depth 2
} else {
    Write-Host "=== Git State Report ==="
    Write-Host "Branch : $branch"
    Write-Host "HEAD   : $headShort ($head)"
    Write-Host ""
    Write-Host "--- Recent Commits ---"
    $log | ForEach-Object { Write-Host "  $_" }
    Write-Host ""
    Write-Host "--- Scoped Status ---"
    if ($statusLines.Count -eq 0) {
        Write-Host "  (clean)"
    } else {
        $statusLines | ForEach-Object { Write-Host "  $_" }
    }
    Write-Host ""
    Write-Host "--- Diff Stat ---"
    if ($diffStat) { Write-Host $diffStat } else { Write-Host "  (no diff)" }
    Write-Host ""
    if ($unexpectedDirty.Count -gt 0) {
        Write-Host "⚠ UNEXPECTED DIRTY:"
        $unexpectedDirty | ForEach-Object { Write-Host "  - $_" }
    } else {
        Write-Host "✓ All dirty files are allowed (or clean)"
    }
}
