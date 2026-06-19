#!/usr/bin/env bash
# One-shot build: web bundle -> stage into Flutter assets -> debug APK.
# No Android Studio required. Run from anywhere; paths are resolved from script location.
# Requirement source: docs/flutter-scanner-migration/05-ai-prompts.md §6
set -euo pipefail

# China network: Flutter engine artifacts + pub packages time out on Google's
# default hosts. Use the flutter-io.cn mirror. Harmless on any network; remove
# these lines if you have direct access to storage.googleapis.com.
: "${FLUTTER_STORAGE_BASE_URL:=https://storage.flutter-io.cn}"
: "${PUB_HOSTED_URL:=https://pub.flutter-io.cn}"
export FLUTTER_STORAGE_BASE_URL PUB_HOSTED_URL

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo '[1/5] npm run build'
npm run build

ASSETS="$ROOT/flutter_shell/assets/wms-app"
echo "[2/5] clean $ASSETS"
rm -rf "$ASSETS"
mkdir -p "$ASSETS"

echo '[3/5] copy wms-app -> flutter_shell/assets/wms-app'
cp -r wms-app/* "$ASSETS/"

echo '[4/5] flutter pub get'
cd "$ROOT/flutter_shell"
flutter pub get

echo '[5/5] flutter build apk --debug'
flutter build apk --debug

APK="$ROOT/flutter_shell/build/app/outputs/flutter-apk/app-debug.apk"
echo "DONE: $APK"
