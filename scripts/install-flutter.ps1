# Download + extract Flutter stable SDK to D:\dev\flutter (no Android Studio).
# China mirror first, official googleapis fallback. Logs to .flutter-install.log.
$ErrorActionPreference = 'Stop'
$log = 'D:\claude-code-warp\Design\.flutter-install.log'
function L($m) { Add-Content -Path $log -Value "[$([DateTime]::Now.ToString('HH:mm:ss'))] $m" }
Set-Content -Path $log -Value "[$([DateTime]::Now.ToString('HH:mm:ss'))] start"
$ProgressPreference = 'SilentlyContinue'

$dest = 'D:\dev'
$zip = "$dest\flutter_windows.zip"
$flutterDir = "$dest\flutter"
New-Item -ItemType Directory -Force -Path $dest | Out-Null

# Free space gate (>6GB)
$free = (Get-PSDrive D).Free
L "free space on D: $([math]::Round($free/1GB,2)) GB"
if ($free -lt 6GB) { L "INSUFFICIENT_SPACE"; exit 2 }

$urls = @(
  'https://storage.flutter-io.cn/flutter_infra_release/releases/stable/windows/flutter_windows_3.44.2-stable.zip',
  'https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.44.2-stable.zip'
)
$downloaded = $false
foreach ($u in $urls) {
  L "downloading $u"
  try {
    Invoke-WebRequest -Uri $u -OutFile $zip -UseBasicParsing -TimeoutSec 1800
    $sz = [math]::Round((Get-Item $zip).Length / 1MB, 1)
    L "downloaded $sz MB"
    $downloaded = $true
    break
  } catch {
    L "download failed: $($_.Exception.Message)"
  }
}
if (-not $downloaded) { L 'ALL_DOWNLOADS_FAILED'; exit 1 }

L "extracting to $dest"
if (Test-Path $flutterDir) { Remove-Item -Recurse -Force $flutterDir }
Expand-Archive -Path $zip -DestinationPath $dest -Force
$ok = Test-Path "$flutterDir\bin\flutter.bat"
L "extracted; flutter.bat exists: $ok"
if (-not $ok) { L 'EXTRACT_INCOMPLETE'; exit 3 }
Remove-Item $zip -Force
L 'DONE'
