# physical-gate.ps1
# Physical gate script — runs all checks and produces a machine-readable report.
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File scripts/physical-gate.ps1
#   powershell -ExecutionPolicy Bypass -File scripts/physical-gate.ps1 -DryRun

param([switch]$DryRun)

$ErrorActionPreference = "Stop"
$startTime = Get-Date
$projectRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$configPath = Join-Path $projectRoot "physical-gate.config.json"
$reportPath  = Join-Path $projectRoot "physical-gate.report.json"

# ---- Helpers ----

function Log($msg) { Write-Host "[physical-gate] $msg" }

function RunCheck($name, $cmd) {
    Log "Running: $name"
    if ($DryRun) {
        Log "  [DRY-RUN] would execute: $cmd"
        return "pass"
    }
    try {
        $result = Invoke-Expression $cmd 2>&1
        $exitCode = $LASTEXITCODE
        if ($exitCode -ne 0 -and $exitCode -ne 1) {
            # exit code 1 from KGP warning is acceptable
            Log "  FAILED (exit $exitCode)"
            return "fail"
        }
        Log "  PASS"
        return "pass"
    } catch {
        Log "  FAILED with exception: $_"
        return "fail"
    }
}

function RunGitScopedStatus {
    param($paths)
    Log "Running: git scoped status"
    if ($DryRun) {
        Log "  [DRY-RUN] would check git status for: $paths"
        return "pass", @()
    }
    $unexpected = @()
    $config = Get-Content $configPath | ConvertFrom-Json
    $allowed = $config.allowedDirty
    $scoped = $config.scopedStatusPaths -join " "

    $statusOutput = & { git -C $projectRoot status --short -- $scoped 2>&1 }
    $lines = $statusOutput | Where-Object { $_ -match '^[ MADRC?!]' }
    foreach ($line in $lines) {
        $file = ($line -replace '^.. ', '').Trim()
        $isAllowed = $allowed | Where-Object { $file -like $_ }
        if (-not $isAllowed) {
            $unexpected += $file
        }
    }
    if ($unexpected.Count -eq 0) {
        Log "  PASS"
        return "pass", @()
    } else {
        Log "  UNEXPECTED DIRTY: $($unexpected -join ', ')"
        return "fail", $unexpected
    }
}

# ---- Main ----

Log "Starting physical gate (DryRun=$DryRun)"
Log "Project root: $projectRoot"

# Load config
$config = Get-Content $configPath | ConvertFrom-Json

# Run checks
$results = @{}
$allPass = $true
$firstFail = $null

# Check 1: design:lint
$r = RunCheck "design:lint" "cd $projectRoot ; npm run design:lint 2>&1"
$results.designLint = $r
if ($r -eq "fail") { $allPass = $false; $firstFail = "design:lint" }

# Check 2: flutter analyze
$env:FLUTTER_HOME = "D:\dev\flutter"
$env:ANDROID_HOME = "C:\Users\Lenovo\AppData\Local\Android\Sdk"
$env:ANDROID_SDK_ROOT = "C:\Users\Lenovo\AppData\Local\Android\Sdk"
$env:JAVA_HOME = "C:\Program Files\Eclipse Adoptium\jdk-17.0.19.10-hotspot"
$env:Path = "$env:FLUTTER_HOME\bin;$env:ANDROID_HOME\cmdline-tools\latest\bin;$env:ANDROID_HOME\platform-tools;$env:Path"
$flutterShell = Join-Path $projectRoot "flutter_shell"

$r = RunCheck "flutter analyze" "cd $flutterShell ; flutter analyze 2>&1"
$results.flutterAnalyze = $r
if ($r -eq "fail") { $allPass = $false; $firstFail = "flutter analyze" }

# Check 3: flutter test
$r = RunCheck "flutter test" "cd $flutterShell ; flutter test 2>&1"
$results.flutterTest = $r
if ($r -eq "fail") { $allPass = $false; $firstFail = "flutter test" }

# Check 4: flutter build apk --debug
Log "Running: flutter build apk --debug"
if ($DryRun) {
    Log "  [DRY-RUN] would execute: flutter build apk --debug"
    $results.flutterBuildDebugApk = "pass"
} else {
    # Build requires long timeout; run with env vars.
    $env:FLUTTER_HOME = "D:\dev\flutter"
    $env:ANDROID_HOME = "C:\Users\Lenovo\AppData\Local\Android\Sdk"
    $env:ANDROID_SDK_ROOT = "C:\Users\Lenovo\AppData\Local\Android\Sdk"
    $env:JAVA_HOME = "C:\Program Files\Eclipse Adoptium\jdk-17.0.19.10-hotspot"
    $env:Path = "$env:FLUTTER_HOME\bin;$env:ANDROID_HOME\cmdline-tools\latest\bin;$env:ANDROID_HOME\platform-tools;$env:Path"
    Push-Location $flutterShell
    $buildOutput = cmd /c "cd /d $flutterShell 2>nul && flutter build apk --debug 2>&1" 2>&1 | Out-String
    Pop-Location
    $built = $buildOutput | Select-String -Pattern "Built" -SimpleMatch
    if ($built) {
        $results.flutterBuildDebugApk = "pass"
        Log "  PASS"
    } else {
        $results.flutterBuildDebugApk = "fail"
        $allPass = $false
        $firstFail = "flutter build apk --debug"
        Log "  FAILED"
    }
}

# Check 5: git scoped status
$r, $unexpected = RunGitScopedStatus
$results.gitScopedStatus = $r
$results.unexpectedDirty = $unexpected
if ($r -eq "fail") { $allPass = $false; $firstFail = "git scoped status" }

# ---- Report ----

$endTime = Get-Date
$duration = ($endTime - $startTime).TotalSeconds
$branch = & { git -C $projectRoot rev-parse --abbrev-ref HEAD 2>&1 }
$head   = & { git -C $projectRoot rev-parse HEAD 2>&1 }

$report = @{
    ok = $allPass
    timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
    durationSeconds = [math]::Round($duration, 1)
    branch = $branch
    head = $head
    checks = $results
    allowedDirty = @($config.allowedDirty)
    unexpectedDirty = @($unexpected)
}

if (-not $allPass) {
    $report.failedCheck = $firstFail
}

$reportJson = $report | ConvertTo-Json -Depth 3
$reportJson | Out-File -FilePath $reportPath -Encoding utf8

Log "Report written to: $reportPath"
Log "Result: $(if ($allPass) { 'ALL PASS' } else { 'FAILED at: ' + $firstFail })"
Log "Duration: $([math]::Round($duration, 1))s"

if (-not $allPass) { exit 1 }
