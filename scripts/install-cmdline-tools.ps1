# Install Android cmdline-tools (sdkmanager) into the existing SDK without Android Studio.
# Needed to accept SDK licenses via `flutter doctor --android-licenses` (doc 02 §4).
$ErrorActionPreference = 'Stop'
$sdk = 'C:\Users\Lenovo\AppData\Local\Android\Sdk'
$url = 'https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip'
$tmpZip = "$env:TEMP\cmdline-tools.zip"
$tmpExtract = "$env:TEMP\cmdline-tools-extract"

$ProgressPreference = 'SilentlyContinue'
Write-Host "downloading cmdline-tools..."
Invoke-WebRequest -Uri $url -OutFile $tmpZip -UseBasicParsing -TimeoutSec 600
Write-Host "downloaded $([math]::Round((Get-Item $tmpZip).Length/1MB,1)) MB"

if (Test-Path $tmpExtract) { Remove-Item -Recurse -Force $tmpExtract }
Expand-Archive -Path $tmpZip -DestinationPath $tmpExtract -Force

# zip top dir is cmdline-tools/ -> place as cmdline-tools/latest
$target = "$sdk\cmdline-tools\latest"
if (Test-Path "$sdk\cmdline-tools") { Remove-Item -Recurse -Force "$sdk\cmdline-tools" }
New-Item -ItemType Directory -Force -Path "$sdk\cmdline-tools" | Out-Null
Move-Item "$tmpExtract\cmdline-tools" $target
Remove-Item $tmpZip -Force
Remove-Item -Recurse -Force $tmpExtract

$ok = Test-Path "$target\bin\sdkmanager.bat"
Write-Host "sdkmanager present: $ok"
