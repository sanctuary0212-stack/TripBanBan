from pathlib import Path

# Escape price dollar signs inside generated Dart string literals.
p = Path('lib/localization/app_strings.dart')
s = p.read_text().replace('US$1.99', r'US\$1.99')
p.write_text(s)

# Remove const wrappers around widgets that now call localized methods.
p = Path('lib/screens/records_screen.dart')
s = p.read_text()
s = s.replace("label: const Padding(\n                      padding: EdgeInsets.symmetric(vertical: 12),\n                      child: Text(strings.t('addExpense')),", "label: Padding(\n                      padding: const EdgeInsets.symmetric(vertical: 12),\n                      child: Text(strings.t('addExpense')),")
p.write_text(s)

p = Path('lib/screens/settings_screen.dart')
s = p.read_text()
s = s.replace("const SizedBox(\n                  width: double.infinity,\n                  child: FilledButton(onPressed: null, child: Text(_strings.t('purchaseSoon'))),", "SizedBox(\n                  width: double.infinity,\n                  child: FilledButton(onPressed: null, child: Text(_strings.t('purchaseSoon'))),")
s = s.replace("const Padding(\n                padding: EdgeInsets.fromLTRB(20, 18, 20, 8),\n                child: Text(_strings.t('selectLanguage'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),", "Padding(\n                padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),\n                child: Text(_strings.t('selectLanguage'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),")
p.write_text(s)

print('Run42 compile fixes applied')
