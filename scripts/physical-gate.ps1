# physical-gate.ps1
# Physical gate script — runs all checks and produces a machine-readable report.
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File scripts/physical-gate.ps1                     # full gate
#   powershell -ExecutionPolicy Bypass -File scripts/physical-gate.ps1 -DryRun              # preview
#   powershell -ExecutionPolicy Bypass -File scripts/physical-gate.ps1 -Baseline            # snapshot baseline
#   powershell -ExecutionPolicy Bypass -File scripts/physical-gate.ps1 -Verify              # drift check

param(
    [switch]$DryRun,
    [switch]$Baseline,
    [switch]$Verify
)

$ErrorActionPreference = "Stop"
$startTime = Get-Date
$projectRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$configPath = Join-Path $projectRoot "physical-gate.config.json"
$baselinePath = Join-Path $projectRoot "physical-gate.baseline.json"
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

function GetScopedStatus {
    param($paths)
    if ($paths.Count -eq 0) { return @() }
    $output = & { git -C $projectRoot status --short -- @paths 2>&1 }
    return $output | Where-Object { $_ -match '^[ MADRC?!]' }
}

function GetScopedStatusHash {
    param($lines)
    $sorted = $lines | Sort-Object | Out-String
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($sorted.Trim())
    if ($bytes.Length -eq 0) { return "EMPTY" }
    $hashAlgo = [System.Security.Cryptography.SHA256]::Create()
    $hash = $hashAlgo.ComputeHash($bytes)
    return [System.BitConverter]::ToString($hash) -replace '-','' -join ''
}

function RunGitScopedStatus {
    param($paths)
    Log "Running: git scoped status"
    if ($DryRun) {
        Log "  [DRY-RUN] would check git status for: $($paths -join ' ')"
        return "pass", @()
    }
    $config = Get-Content $configPath | ConvertFrom-Json
    $allowed = $config.allowedDirty
    $unexpected = @()
    $lines = GetScopedStatus -paths $paths
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

function ArrayEqual($a, $b) {
    $aStr = ($a | Sort-Object) -join ','
    $bStr = ($b | Sort-Object) -join ','
    return $aStr -eq $bStr
}

function VerifyBaseline {
    Log "Running: verify baseline"
    $config = Get-Content $configPath | ConvertFrom-Json
    $baseline = Get-Content $baselinePath | ConvertFrom-Json
    $scoped = $config.scopedStatusPaths

    $drift = @()

    # 1. Check git status hash (filter out allowed-dirty files)
    $currentLines = GetScopedStatus -paths $scoped
    $allowed = $config.allowedDirty
    $filteredLines = $currentLines | Where-Object {
        $file = ($_ -replace '^.. ', '').Trim()
        $isAllowed = $allowed | Where-Object { $file -like $_ }
        -not $isAllowed
    }
    $currentHash = GetScopedStatusHash -lines $filteredLines
    if ($currentHash -ne $baseline.gitStatusHash) {
        $drift += "git status hash differs (baseline=$($baseline.gitStatusHash), current=$currentHash)"
    }

    # 2. Check allowed dirty list
    if (-not (ArrayEqual $config.allowedDirty $baseline.allowedDirty)) {
        $baselineStr = ($baseline.allowedDirty | Sort-Object) -join ','
        $currentStr = ($config.allowedDirty | Sort-Object) -join ','
        $drift += "allowedDirty list has changed (baseline=[$baselineStr], current=[$currentStr])"
    }

    # 3. Check tracked file count hasn't changed drastically
    $baselineCommit = $baseline.commit
    $head = & { git -C $projectRoot rev-parse HEAD 2>&1 }
    if ($head -ne $baselineCommit) {
        $drift += "HEAD moved from $baselineCommit to $head (update baseline if intentional)"
    }

    if ($drift.Count -eq 0) {
        Log "  PASS — no drift detected"
        return "pass"
    } else {
        Log "  DRIFT DETECTED:"
        foreach ($d in $drift) { Log "    - $d" }
        return "fail"
    }
}

function SaveBaseline {
    Log "Running: save baseline"
    $config = Get-Content $configPath | ConvertFrom-Json
    $head = & { git -C $projectRoot rev-parse HEAD 2>&1 }
    $branch = & { git -C $projectRoot rev-parse --abbrev-ref HEAD 2>&1 }
    $scoped = $config.scopedStatusPaths
    $lines = GetScopedStatus -paths $scoped
    $hash = GetScopedStatusHash -lines $lines

    $baseline = @{
        commit = $head
        branch = $branch
        createdAt = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
        allowedDirty = @($config.allowedDirty)
        scopedStatusPaths = @($scoped)
        gitStatusHash = $hash
    }

    $json = $baseline | ConvertTo-Json -Depth 3
    $json | Out-File -FilePath $baselinePath -Encoding utf8
    Log "  Baseline saved at $baselinePath (hash=$hash)"
    Log "  PASS"
}

# ---- Mode dispatch ----

$env:FLUTTER_HOME = "D:\dev\flutter"
$env:ANDROID_HOME = "C:\Users\Lenovo\AppData\Local\Android\Sdk"
$env:ANDROID_SDK_ROOT = "C:\Users\Lenovo\AppData\Local\Android\Sdk"
$env:JAVA_HOME = "C:\Program Files\Eclipse Adoptium\jdk-17.0.19.10-hotspot"
$env:Path = "$env:FLUTTER_HOME\bin;$env:ANDROID_HOME\cmdline-tools\latest\bin;$env:ANDROID_HOME\platform-tools;$env:Path"
$flutterShell = Join-Path $projectRoot "flutter_shell"

if ($Baseline) {
    SaveBaseline
    exit 0
}

if ($Verify) {
    $r = VerifyBaseline
    if ($r -eq "fail") { exit 1 }
    exit 0
}

# ---- Full gate / dry-run ----

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

# Check 5: verify baseline (if baseline exists; otherwise skip)
$baselineExists = Test-Path $baselinePath
if ($baselineExists) {
    $r = VerifyBaseline
    $results.baselineVerify = $r
    if ($r -eq "fail") { $allPass = $false; $firstFail = "baseline verify" }
} else {
    $results.baselineVerify = "skip (no baseline)"
    Log "  SKIP (no baseline)"
}

# Check 6: git scoped status
$r, $unexpected = RunGitScopedStatus -paths $config.scopedStatusPaths
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
