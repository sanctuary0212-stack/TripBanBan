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

# Flutter create may generate a default test that references MyApp, which this
# project does not define. Keep the project's real tests and remove only that
# generated placeholder.
rm -f test/widget_test.dart

# Dart treats $ inside normal strings as interpolation. The currency catalog
# intentionally stores literal dollar symbols, so make those literals raw.
python3 - <<'PY'
from pathlib import Path

path = Path('lib/domain/currency_catalog.dart')
text = path.read_text(encoding='utf-8')
for symbol in ('A$', 'R$', 'CA$', 'HK$', 'MX$', 'NZ$', 'NT$', '$', 'EC$'):
    text = text.replace(f"symbol: '{symbol}'", f"symbol: r'{symbol}'")
path.write_text(text, encoding='utf-8')
PY

python3 tool/patch_android.py
flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
flutter analyze --no-fatal-warnings --no-fatal-infos
flutter test
flutter build apk --debug

echo "APK: $ROOT/build/app/outputs/flutter-apk/app-debug.apk"
