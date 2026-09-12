from pathlib import Path

p = Path('lib/screens/settings_screen.dart')
s = p.read_text()

# Keep the entire About block in English regardless of selected UI language.
s = s.replace("_section(strings.t('about'), [", "_section('About', [")

replacements = {
    "_ReleaseNote(text: '更新 App Logo 與 Android launcher icon')": "const _ReleaseNote(text: 'Updated App logo and Android launcher icon')",
    "_ReleaseNote(text: '旅程卡片加入依目的地顯示的地標剪影圖樣')": "const _ReleaseNote(text: 'Added destination landmark silhouettes to trip cards')",
    "_ReleaseNote(text: '多國語言擴充至 10 種常用語言')": "const _ReleaseNote(text: 'Expanded language selection to 10 commonly used languages')",
    "_ReleaseNote(text: '旅程頁修正：已有專案後仍可建立新旅程')": "const _ReleaseNote(text: 'Trip page: new trips can still be created after projects exist')",
    "_ReleaseNote(text: '結算頁可切換旅程，並優化每人支出欄位與最終轉帳建議')": "const _ReleaseNote(text: 'Settlement: trip switching, aligned per-person totals, and transfer suggestions')",
    "_ReleaseNote(text: '持續支援公基金退款與 Plus / Google Drive 功能')": "const _ReleaseNote(text: 'Shared-fund refunds and Plus / Google Drive support')",
}

for old, new in replacements.items():
    if old not in s:
        raise SystemExit(f'About source target not found: {old}')
    s = s.replace(old, new, 1)

p.write_text(s)
print('About section forced to English')
