from pathlib import Path
import json, re, sys

root = Path(__file__).resolve().parents[1]
errors=[]
warnings=[]

pub=(root/'pubspec.yaml').read_text()
if 'version: 0.8.2+82' not in pub: errors.append('pubspec version is not 0.8.2+82')
if 'drift:' not in pub or 'drift_flutter:' not in pub: errors.append('Drift dependencies missing')

# DB tables expected by Local-First accounting.
db=(root/'lib/data/local/app_database.dart').read_text()
for name in ['Trips','Members','Expenses','ExpenseShares','FundTransactions','SettlementPayments','Attachments','FxRates','AppSettings']:
    if f'class {name} extends Table' not in db: errors.append(f'missing DB table: {name}')

# Core locales.
app_strings=(root/'lib/localization/app_strings.dart').read_text()
for locale in ['zh_Hant','zh_Hans','en','ja','ko']:
    if f"'{locale}':" not in app_strings: errors.append(f'missing runtime locale: {locale}')

# app.dart should expose the same locales.
app=(root/'lib/app.dart').read_text()
for token in ["scriptCode: 'Hant'", "scriptCode: 'Hans'", "Locale('en')", "Locale('ja')", "Locale('ko')"]:
    if token not in app: errors.append(f'missing supported locale in MaterialApp: {token}')

# Source hygiene for the Android-focused branch.
readme=(root/'README.md').read_text()
if 'Android Local-First' not in readme: errors.append('README is not Android v0.8.2')
for stale in ['Supabase schema', 'flutter create --platforms=android,ios']:
    if stale in readme: errors.append(f'stale README text: {stale}')

# Ensure no old alpha package ids are present in new core source.
core='\n'.join(p.read_text(errors='ignore') for p in (root/'lib').rglob('*.dart'))
if re.search(r'com\.tripbanban\.safe\d+', core): errors.append('old safeXXX package id leaked into core source')

# ARB JSON parse.
for required in ['app_en.arb','app_zh_Hant.arb','app_zh_Hans.arb','app_ja.arb','app_ko.arb']:
    if not (root/'lib/l10n'/required).exists(): errors.append(f'missing ARB locale file: {required}')

for p in (root/'lib/l10n').glob('*.arb'):
    try: json.loads(p.read_text())
    except Exception as e: errors.append(f'invalid ARB {p.name}: {e}')

print('TripBanBan v0.8.2 Android preflight')
for w in warnings: print('WARN:',w)
for e in errors: print('ERROR:',e)
if errors:
    sys.exit(1)
print('PASS')
