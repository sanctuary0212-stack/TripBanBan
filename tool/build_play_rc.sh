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
flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
flutter analyze --no-fatal-warnings --no-fatal-infos
flutter test

# RC only: Flutter's generated Android template may use the debug signing key
# for release builds. The final Play upload workflow must use a persistent
# upload key stored in GitHub Actions secrets.
flutter build appbundle --release

echo "RC AAB: $ROOT/build/app/outputs/bundle/release/app-release.aab"
