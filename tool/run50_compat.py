from pathlib import Path

p = Path('tool/run50_locale_drive.py')
s = p.read_text()
old = '''old_t = """  String t(String key) {
    final localized = _values[languageCode]?[key];
    return localized ?? _en[key] ?? key;
  }
"""
new_t = """  String t(String key) {
    final localized = _run50[languageCode]?[key] ?? _values[languageCode]?[key];
    return localized ?? _run50['en']?[key] ?? _en[key] ?? key;
  }
"""'''
new = '''old_t = """  String t(String key) {
    final extra = _extraValues[languageCode]?[key];
    if (extra != null) return extra;
    final localized = _values[languageCode]?[key];
    return localized ?? _en[key] ?? key;
  }
"""
new_t = """  String t(String key) {
    final run50 = _run50[languageCode]?[key];
    if (run50 != null) return run50;
    final extra = _extraValues[languageCode]?[key];
    if (extra != null) return extra;
    final localized = _values[languageCode]?[key];
    return localized ?? _run50['en']?[key] ?? _en[key] ?? key;
  }
"""'''
if old not in s:
    raise SystemExit('Run50 compatibility target not found')
p.write_text(s.replace(old, new, 1))
print('Run50 made compatible with Run42 AppStrings layer')
