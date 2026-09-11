#!/usr/bin/env bash
set -euo pipefail

if ! command -v flutter >/dev/null 2>&1; then
  echo "ERROR: Flutter SDK not found in PATH." >&2
  exit 2
fi

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [ ! -d android ]; then
  flutter create --platforms=android --org com.tripbanban --project-name tripbanban_app .
fi

python3 tool/patch_android.py
flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter build apk --debug

echo "APK: $ROOT/build/app/outputs/flutter-apk/app-debug.apk"
