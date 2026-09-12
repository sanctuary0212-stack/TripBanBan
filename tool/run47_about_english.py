from pathlib import Path

p = Path('lib/screens/settings_screen.dart')
s = p.read_text()

s = s.replace("_section(strings.t('about'), [", "_section('About', [")

replacements = {
    "_ReleaseNote(text: strings.t('release1'))": "const _ReleaseNote(text: 'Updated App logo and Android launcher icon')",
    "_ReleaseNote(text: strings.t('release2'))": "const _ReleaseNote(text: 'Added destination landmark silhouettes to trip cards')",
    "_ReleaseNote(text: strings.t('release3'))": "const _ReleaseNote(text: 'Expanded language selection to 10 commonly used languages')",
    "_ReleaseNote(text: strings.t('release4'))": "const _ReleaseNote(text: 'Trip page: new trips can still be created after projects exist')",
    "_ReleaseNote(text: strings.t('release5'))": "const _ReleaseNote(text: 'Settlement: trip switching, aligned per-person totals, and transfer suggestions')",
    "_ReleaseNote(text: strings.t('release6'))": "const _ReleaseNote(text: 'Shared-fund refunds and Plus / Google Drive support')",
}

for old, new in replacements.items():
    if old not in s:
        raise SystemExit(f'About localization target not found: {old}')
    s = s.replace(old, new, 1)

p.write_text(s)
print('About section forced to English')
