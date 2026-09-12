from pathlib import Path

# Settings screen
p = Path('lib/screens/settings_screen.dart')
s = p.read_text()
if "AppStrings get _strings" not in s:
    s = s.replace("  bool autoBackup = false;\n", "  bool autoBackup = false;\n\n  AppStrings get _strings => AppStrings(widget.controller.languageCode);\n", 1)
s = s.replace("_section('一般', [", "_section(strings.t('general'), [")
s = s.replace("_section('本機匯入 / 匯出', [", "_section(strings.t('localImportExport'), [")
s = s.replace("_section('關於', const [", "_section(strings.t('about'), [")
s = s.replace("subtitle: const Text('包含帳本 JSON 快照與本機照片附件'),", "subtitle: Text(strings.t('localBackupDesc')),")
s = s.replace("subtitle: const Text('先顯示備份摘要，確認後才覆蓋本機資料'),", "subtitle: Text(strings.t('localRestoreDesc')),")
notes = [
'更新 App Logo 與 Android launcher icon',
'旅程卡片加入依目的地顯示的地標剪影圖樣',
'多國語言擴充至 10 種常用語言',
'旅程頁修正：已有專案後仍可建立新旅程',
'結算頁可切換旅程，並優化每人支出欄位與最終轉帳建議',
'持續支援公基金退款與 Plus / Google Drive 功能']
for i, text in enumerate(notes, 1):
    s = s.replace(f"const _ReleaseNote(text: '{text}')", f"_ReleaseNote(text: strings.t('release{i}'))")
s = s.replace("premium.isPremium ? 'TripBanBan Plus 已啟用' : '${PremiumService.productLabel} · ${PremiumService.priceLabel}'", "premium.isPremium ? _strings.t('plusEnabled') : '${PremiumService.productLabel} · ${PremiumService.priceLabel}'")
s = s.replace("const Text('一次買斷 · 解鎖更多旅伴與雲端功能')", "Text(_strings.t('oneTimePurchase'))")
s = s.replace("const _FeatureLine(icon: Icons.group_add_outlined, text: '旅伴可超過 3 人')", "_FeatureLine(icon: Icons.group_add_outlined, text: _strings.t('moreThan3Travelers'))")
s = s.replace("const _FeatureLine(icon: Icons.cloud_outlined, text: 'Google Drive 備份與還原')", "_FeatureLine(icon: Icons.cloud_outlined, text: _strings.t('driveBackupRestore'))")
s = s.replace("const _FeatureLine(icon: Icons.import_export_rounded, text: 'Google Drive 匯入 / 匯出流程')", "_FeatureLine(icon: Icons.import_export_rounded, text: _strings.t('driveImportExport'))")
s = s.replace("title: const Text('測試付費版功能'),", "title: Text(_strings.t('debugPremium')),")
s = s.replace("subtitle: const Text('僅 Debug APK 顯示，方便目前測試；正式版不會有此開關。'),", "subtitle: Text(_strings.t('debugPremiumDesc')),")
s = s.replace("child: FilledButton(onPressed: null, child: Text('Google Play 商品建立後開放購買'))", "child: FilledButton(onPressed: null, child: Text(_strings.t('purchaseSoon')))")
s = s.replace("List<Widget> _lockedDriveChildren() => const [", "List<Widget> _lockedDriveChildren() => [")
s = s.replace("leading: Icon(Icons.lock_outline),\n          title: Text('Google Drive 為 Plus 功能'),\n          subtitle: Text('升級 US\\$1.99 Plus 後，可將備份存放在自己的 Google Drive，並從雲端還原。'),", "leading: const Icon(Icons.lock_outline),\n          title: Text(_strings.t('drivePlusOnly')),\n          subtitle: Text(_strings.t('drivePlusDesc')),")
s = s.replace("? '${driveState!.email}\\n最後備份：${_dateTime(driveState!.lastBackupAt)}'\n                : '尚未連結 · 備份存放在使用者自己的 Drive AppData'", "? '${driveState!.email}\\n${_strings.t('lastBackup')}：${_dateTime(driveState!.lastBackupAt)}'\n                : _strings.t('notConnected')")
s = s.replace("title: const Text('每日自動備份'),", "title: Text(_strings.t('autoBackup')),")
s = s.replace("subtitle: const Text('最佳努力排程；離線時仍以本機資料為準。'),", "subtitle: Text(_strings.t('autoBackupDesc')),")
s = s.replace("child: Text('選擇語言', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),", "child: Text(_strings.t('selectLanguage'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),")
s = s.replace("title: const Text('操作失敗'),", "title: Text(_strings.t('operationFailed')),")
s = s.replace("child: const Text('知道了')", "child: Text(_strings.t('ok'))")
p.write_text(s)

# Trip detail and Summary card
p = Path('lib/screens/trip_detail_screen.dart')
s = p.read_text()
if "../localization/app_strings.dart" not in s:
    s = s.replace("import '../domain/money_text.dart';\n", "import '../domain/money_text.dart';\nimport '../localization/app_strings.dart';\n", 1)
if "AppStrings get _strings" not in s:
    s = s.replace("  int refresh = 0;\n", "  int refresh = 0;\n\n  AppStrings get _strings => AppStrings(widget.controller.languageCode);\n", 1)
s = s.replace("_TravelHeroCard(trip: trip, ledger: ledger)", "_TravelHeroCard(controller: widget.controller, trip: trip, ledger: ledger)")
s = s.replace("const Text('旅伴', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17))", "Text(_strings.t('travelers'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17))")
s = s.replace("label: const Text('管理旅伴'),", "label: Text(_strings.t('manageMembers')),")
s = s.replace("label: const Padding(padding: EdgeInsets.symmetric(vertical: 13), child: Text('新增支出')),", "label: Padding(padding: const EdgeInsets.symmetric(vertical: 13), child: Text(_strings.t('addExpense'))),")
s = s.replace("Text('旅程專案管理', style:", "Text(_strings.t('tripManagement'), style:")
s = s.replace("label: const Text('刪除旅程'),", "label: Text(_strings.t('deleteTrip')),")
s = s.replace("title: Text(refund ? '公基金退款' : '繳入公基金'),", "title: Text(refund ? _strings.t('fundRefund') : _strings.t('contributeFund')),")
s = s.replace("decoration: const InputDecoration(labelText: '旅伴'),", "decoration: InputDecoration(labelText: _strings.t('travelers')),")
s = s.replace("const SnackBar(content: Text('請輸入有效金額'))", "SnackBar(content: Text(_strings.t('validAmount')))")
# Fund card
s = s.replace("  Widget build(BuildContext context) {\n    return StreamBuilder<List<MemberRow>>(\n", "  Widget build(BuildContext context) {\n    final strings = AppStrings(controller.languageCode);\n    return StreamBuilder<List<MemberRow>>(\n", 1)
s = s.replace("const Text('公基金', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17))", "Text(strings.t('publicFund'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17))")
s = s.replace("const Text('每人匯入（繳入－退款）', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black54))", "Text(strings.t('perPersonFundNet'), style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black54))")
s = s.replace("label: const Text('繳入 / 補充'),", "label: Text(strings.t('contribute')),")
# Summary card
marker = s.find("class _TripExpenseSummary")
if marker >= 0:
    sub = s[marker:]
    sub = sub.replace("  Widget build(BuildContext context) {\n    return StreamBuilder<List<ExpenseRow>>(", "  Widget build(BuildContext context) {\n    final strings = AppStrings(controller.languageCode);\n    return StreamBuilder<List<ExpenseRow>>(", 1)
    s = s[:marker] + sub
s = s.replace("const Text('本專案支出 Summary', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17))", "Text(strings.t('projectExpenseSummary'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17))")
s = s.replace("_summaryMetric('總支出',", "_summaryMetric(strings.t('totalExpense'),")
s = s.replace("_summaryMetric('支出筆數', '${expenses.length} 筆')", "_summaryMetric(strings.t('expenseCountLabel'), '${expenses.length}')")
s = s.replace("_summaryMetric('平均每人',", "_summaryMetric(strings.t('averagePerPerson'),")
s = s.replace("_summaryMetric('最高類別', topCategory)", "_summaryMetric(strings.t('topCategory'), topCategory)")
s = s.replace("'最近：${latest.title.trim().isEmpty ? categoryLabel(latest.categoryKey) : latest.title}'", "'${strings.t('recent')}：${latest.title.trim().isEmpty ? categoryLabel(latest.categoryKey) : latest.title}'")
# Hero card
s = s.replace("const _TravelHeroCard({required this.trip, required this.ledger});\n  final TripRow trip;", "const _TravelHeroCard({required this.controller, required this.trip, required this.ledger});\n  final AppController controller;\n  final TripRow trip;")
marker = s.find("class _TravelHeroCard")
if marker >= 0:
    sub = s[marker:]
    sub = sub.replace("  Widget build(BuildContext context) {\n    return Card(", "  Widget build(BuildContext context) {\n    final strings = AppStrings(controller.languageCode);\n    return Card(", 1)
    s = s[:marker] + sub
s = s.replace("_metric('總支出',", "_metric(strings.t('totalExpense'),")
s = s.replace("_metric('公基金餘額',", "_metric(strings.t('fundBalance'),")
p.write_text(s)

# Records: remove remaining hard-coded Chinese from summary/stat tabs.
p = Path('lib/screens/records_screen.dart')
s = p.read_text()
s = s.replace("_summaryMetric('支出筆數', '${expenses.length} 筆')", "_summaryMetric(strings.t('expenseCountLabel'), '${expenses.length}')")
s = s.replace("_summaryMetric('總支出',", "_summaryMetric(strings.t('totalExpense'),")
s = s.replace("child: Text('新增支出'),", "child: Text(strings.t('addExpense')),")
p.write_text(s)

print('Run42 screen localization patch applied')
