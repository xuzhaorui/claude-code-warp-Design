# One-shot build: web bundle -> stage into Flutter assets -> debug APK.
# No Android Studio required. Run from anywhere; paths are resolved from script location.
# Requirement source: docs/flutter-scanner-migration/05-ai-prompts.md §6
$ErrorActionPreference = 'Stop'

# China network: Flutter engine artifacts + pub packages time out on Google's
# default hosts. Use the flutter-io.cn mirror. Harmless on any network; remove
# these two lines if you have direct access to storage.googleapis.com.
if (-not $env:FLUTTER_STORAGE_BASE_URL) { $env:FLUTTER_STORAGE_BASE_URL = 'https://storage.flutter-io.cn' }
if (-not $env:PUB_HOSTED_URL) { $env:PUB_HOSTED_URL = 'https://pub.flutter-io.cn' }

$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

Write-Host '[1/5] npm run build'
npm run build
if ($LASTEXITCODE -ne 0) { throw 'npm run build failed' }

$assets = Join-Path $root 'flutter_shell\assets\wms-app'
Write-Host "[2/5] clean $assets"
if (Test-Path $assets) { Remove-Item -Recurse -Force $assets }
New-Item -ItemType Directory -Force $assets | Out-Null

Write-Host '[3/5] copy wms-app -> flutter_shell/assets/wms-app'
Copy-Item -Recurse -Force (Join-Path $root 'wms-app\*') $assets

Write-Host '[4/5] flutter pub get'
Set-Location (Join-Path $root 'flutter_shell')
flutter pub get
if ($LASTEXITCODE -ne 0) { throw 'flutter pub get failed' }

Write-Host '[5/5] flutter build apk --debug'
flutter build apk --debug
if ($LASTEXITCODE -ne 0) { throw 'flutter build apk failed' }

$apk = Join-Path $root 'flutter_shell\build\app\outputs\flutter-apk\app-debug.apk'
Write-Host "DONE: $apk"
