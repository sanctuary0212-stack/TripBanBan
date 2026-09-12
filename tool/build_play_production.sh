#!/usr/bin/env bash
set -euo pipefail

if ! command -v flutter >/dev/null 2>&1; then
  echo "ERROR: Flutter SDK not found in PATH." >&2
  exit 2
fi

for name in ANDROID_KEYSTORE_PATH ANDROID_KEYSTORE_PASSWORD ANDROID_KEY_ALIAS ANDROID_KEY_PASSWORD; do
  if [ -z "${!name:-}" ]; then
    echo "ERROR: $name is required for production signing." >&2
    exit 3
  fi
done

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [ ! -d android ]; then
  flutter create --platforms=android --org com.tripbanban --project-name tripbanban_app .
fi
rm -f test/widget_test.dart

python3 - <<'PY'
from pathlib import Path
path = Path('lib/domain/currency_catalog.dart')
text = path.read_text(encoding='utf-8')
for symbol in ('A$', 'R$', 'CA$', 'HK$', 'MX$', 'NZ$', 'NT$', '$', 'EC$'):
    text = text.replace(f"symbol: '{symbol}'", f"symbol: r'{symbol}'")
path.write_text(text, encoding='utf-8')
PY

python3 tool/patch_android.py
python3 tool/configure_release_signing.py
flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
flutter analyze --no-fatal-warnings --no-fatal-infos
flutter test
flutter build appbundle --release

echo "Production AAB: $ROOT/build/app/outputs/bundle/release/app-release.aab"
