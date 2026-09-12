from pathlib import Path

p = Path('lib/screens/settings_screen.dart')
s = p.read_text(encoding='utf-8')
old = "subtitle: Text('${strings.t('localImportExport')} · ${premium.displayPrice}'),"
new = "subtitle: Text('${strings.t('localImportExport')} · ${PremiumService.priceLabel}'),"
if old not in s:
    raise SystemExit('Run60 settings compile-fix target not found')
s = s.replace(old, new, 1)
p.write_text(s, encoding='utf-8')
print('Run60 compile fix applied')
