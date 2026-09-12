from pathlib import Path
import json

# Core strings that must never fall back to another language in the main flows.
EXTRA = json.loads(r'''
{
  "en": {"expenseRecords":"Expense records","tripName":"Trip name","tripNameHint":"e.g. Tokyo 5-day trip","destinationOptional":"Destination (optional)","destinationHint":"Tokyo / Okinawa / Seoul…","startDate":"Start date","endDate":"End date","choose":"Select","tripBaseCurrency":"Trip base currency","addTraveler":"Add traveler","traveler":"Traveler","tripValidation":"Enter a trip name and keep at least one traveler.","me":"Me","driveConfigMissing":"Google Drive sign-in is not configured in this build. Add the Web OAuth client ID and rebuild."},
  "zh_Hant": {"expenseRecords":"支出紀錄","tripName":"旅程名稱","tripNameHint":"例如：東京 5 日遊","destinationOptional":"目的地（選填）","destinationHint":"東京 / 沖繩 / 首爾…","startDate":"開始日期","endDate":"結束日期","choose":"選擇","tripBaseCurrency":"旅程基準幣別","addTraveler":"新增旅伴","traveler":"旅伴","tripValidation":"請輸入旅程名稱並至少保留一位旅伴。","me":"我","driveConfigMissing":"此測試版尚未設定 Google Drive 登入憑證。請加入 Web OAuth Client ID 後重新建置。"},
  "zh_Hans": {"expenseRecords":"支出记录","tripName":"旅程名称","tripNameHint":"例如：东京 5 日游","destinationOptional":"目的地（选填）","destinationHint":"东京 / 冲绳 / 首尔…","startDate":"开始日期","endDate":"结束日期","choose":"选择","tripBaseCurrency":"旅程基准币别","addTraveler":"新增旅伴","traveler":"旅伴","tripValidation":"请输入旅程名称并至少保留一位旅伴。","me":"我","driveConfigMissing":"此测试版尚未设置 Google Drive 登录凭证。请加入 Web OAuth Client ID 后重新构建。"},
  "ja": {"expenseRecords":"支出記録","tripName":"旅行名","tripNameHint":"例：東京5日間","destinationOptional":"行き先（任意）","destinationHint":"東京 / 沖縄 / ソウル…","startDate":"開始日","endDate":"終了日","choose":"選択","tripBaseCurrency":"旅行の基準通貨","addTraveler":"メンバーを追加","traveler":"メンバー","tripValidation":"旅行名を入力し、少なくとも1人のメンバーを残してください。","me":"私","driveConfigMissing":"このビルドには Google Drive ログイン設定がありません。Web OAuth Client ID を追加して再ビルドしてください。"},
  "ko": {"expenseRecords":"지출 기록","tripName":"여행 이름","tripNameHint":"예: 도쿄 5일 여행","destinationOptional":"목적지 (선택)","destinationHint":"도쿄 / 오키나와 / 서울…","startDate":"시작일","endDate":"종료일","choose":"선택","tripBaseCurrency":"여행 기준 통화","addTraveler":"여행자 추가","traveler":"여행자","tripValidation":"여행 이름을 입력하고 여행자를 최소 1명 유지하세요.","me":"나","driveConfigMissing":"이 빌드에는 Google Drive 로그인 설정이 없습니다. Web OAuth Client ID를 추가한 뒤 다시 빌드하세요."},
  "fr": {"expenseRecords":"Dépenses","tripName":"Nom du voyage","tripNameHint":"ex. Tokyo 5 jours","destinationOptional":"Destination (facultatif)","destinationHint":"Tokyo / Okinawa / Séoul…","startDate":"Date de début","endDate":"Date de fin","choose":"Choisir","tripBaseCurrency":"Devise de base du voyage","addTraveler":"Ajouter un voyageur","traveler":"Voyageur","tripValidation":"Saisissez un nom de voyage et conservez au moins un voyageur.","me":"Moi","driveConfigMissing":"La connexion Google Drive n’est pas configurée dans cette version. Ajoutez le Web OAuth Client ID puis reconstruisez."},
  "de": {"expenseRecords":"Ausgaben","tripName":"Reisename","tripNameHint":"z. B. Tokio 5 Tage","destinationOptional":"Reiseziel (optional)","destinationHint":"Tokio / Okinawa / Seoul…","startDate":"Startdatum","endDate":"Enddatum","choose":"Auswählen","tripBaseCurrency":"Basiswährung der Reise","addTraveler":"Mitreisenden hinzufügen","traveler":"Mitreisender","tripValidation":"Gib einen Reisenamen ein und behalte mindestens einen Mitreisenden.","me":"Ich","driveConfigMissing":"Google Drive ist in diesem Build nicht konfiguriert. Füge die Web OAuth Client ID hinzu und baue erneut."},
  "es": {"expenseRecords":"Gastos","tripName":"Nombre del viaje","tripNameHint":"p. ej. Tokio 5 días","destinationOptional":"Destino (opcional)","destinationHint":"Tokio / Okinawa / Seúl…","startDate":"Fecha de inicio","endDate":"Fecha de fin","choose":"Seleccionar","tripBaseCurrency":"Moneda base del viaje","addTraveler":"Añadir viajero","traveler":"Viajero","tripValidation":"Introduce un nombre de viaje y conserva al menos un viajero.","me":"Yo","driveConfigMissing":"El inicio de sesión de Google Drive no está configurado en esta compilación. Añade el Web OAuth Client ID y vuelve a compilar."},
  "it": {"expenseRecords":"Spese","tripName":"Nome del viaggio","tripNameHint":"es. Tokyo 5 giorni","destinationOptional":"Destinazione (facoltativa)","destinationHint":"Tokyo / Okinawa / Seoul…","startDate":"Data di inizio","endDate":"Data di fine","choose":"Seleziona","tripBaseCurrency":"Valuta base del viaggio","addTraveler":"Aggiungi viaggiatore","traveler":"Viaggiatore","tripValidation":"Inserisci un nome del viaggio e mantieni almeno un viaggiatore.","me":"Io","driveConfigMissing":"L’accesso a Google Drive non è configurato in questa build. Aggiungi il Web OAuth Client ID e ricompila."},
  "th": {"expenseRecords":"บันทึกค่าใช้จ่าย","tripName":"ชื่อทริป","tripNameHint":"เช่น โตเกียว 5 วัน","destinationOptional":"จุดหมาย (ไม่บังคับ)","destinationHint":"โตเกียว / โอกินาวะ / โซล…","startDate":"วันที่เริ่ม","endDate":"วันที่สิ้นสุด","choose":"เลือก","tripBaseCurrency":"สกุลเงินหลักของทริป","addTraveler":"เพิ่มผู้ร่วมทริป","traveler":"ผู้ร่วมทริป","tripValidation":"กรอกชื่อทริปและคงผู้ร่วมทริปไว้อย่างน้อย 1 คน","me":"ฉัน","driveConfigMissing":"บิลด์นี้ยังไม่ได้ตั้งค่าการเข้าสู่ระบบ Google Drive โปรดเพิ่ม Web OAuth Client ID แล้วสร้างใหม่"}
}
''')

expected = set(EXTRA['en'])
for code, values in EXTRA.items():
    if set(values) != expected:
        raise SystemExit(f'Run50 locale key mismatch: {code}')

# AppStrings: add a strict override layer before the legacy fallback maps.
p = Path('lib/localization/app_strings.dart')
s = p.read_text()
old_t = """  String t(String key) {
    final localized = _values[languageCode]?[key];
    return localized ?? _en[key] ?? key;
  }
"""
new_t = """  String t(String key) {
    final localized = _run50[languageCode]?[key] ?? _values[languageCode]?[key];
    return localized ?? _run50['en']?[key] ?? _en[key] ?? key;
  }
"""
if old_t not in s:
    raise SystemExit('AppStrings.t target not found')
s = s.replace(old_t, new_t, 1)
rows = []
for code, values in EXTRA.items():
    body = ',\n'.join(f"      {json.dumps(k, ensure_ascii=False)}: {json.dumps(v, ensure_ascii=False)}" for k, v in values.items())
    rows.append(f"    {json.dumps(code)}: <String, String>{{\n{body},\n    }}")
block = "  static const Map<String, Map<String, String>> _run50 = <String, Map<String, String>>{\n" + ',\n'.join(rows) + "\n  };\n\n"
marker = "  static const Map<String, Map<String, String>> _values = {\n"
if marker not in s:
    raise SystemExit('AppStrings values marker not found')
s = s.replace(marker, block + marker, 1)
p.write_text(s)

# Create Trip: remove hard-coded Traditional Chinese from the whole screen.
p = Path('lib/screens/create_trip_screen.dart')
s = p.read_text()
if "../localization/app_strings.dart" not in s:
    s = s.replace("import '../features/premium/premium_service.dart';\n", "import '../features/premium/premium_service.dart';\nimport '../localization/app_strings.dart';\n", 1)
s = s.replace("  final members = <_MemberDraft>[_MemberDraft(0, '我')];", "  final members = <_MemberDraft>[];")
s = s.replace("    currency = widget.controller.defaultCurrency;", "    currency = widget.controller.defaultCurrency;\n    members.add(_MemberDraft(0, AppStrings(widget.controller.languageCode).t('me')));", 1)
s = s.replace("    final premium = widget.controller.services.premium.isPremium;", "    final premium = widget.controller.services.premium.isPremium;\n    final strings = AppStrings(widget.controller.languageCode);", 1)
replacements = [
    ("appBar: AppBar(title: const Text('建立新旅程'))", "appBar: AppBar(title: Text(strings.t('newTrip')))"),
    ("TextField(controller: nameController, decoration: const InputDecoration(labelText: '旅程名稱', hintText: '例如：東京 6 日遊'))", "TextField(controller: nameController, decoration: InputDecoration(labelText: strings.t('tripName'), hintText: strings.t('tripNameHint')))"),
    ("TextField(controller: destinationController, decoration: const InputDecoration(labelText: '目的地（選填）', hintText: '東京 / 沖繩 / 首爾…'))", "TextField(controller: destinationController, decoration: InputDecoration(labelText: strings.t('destinationOptional'), hintText: strings.t('destinationHint')))"),
    ("Expanded(child: _dateButton('開始日期', startDate, (value) => setState(() => startDate = value)))", "Expanded(child: _dateButton(strings.t('startDate'), startDate, (value) => setState(() => startDate = value)))"),
    ("Expanded(child: _dateButton('結束日期', endDate, (value) => setState(() => endDate = value)))", "Expanded(child: _dateButton(strings.t('endDate'), endDate, (value) => setState(() => endDate = value)))"),
    ("title: const Text('旅程基準幣別'),", "title: Text(strings.t('tripBaseCurrency')),"),
    ("title: '旅程基準幣別'", "title: strings.t('tripBaseCurrency')"),
    ("Text('旅伴', style:", "Text(strings.t('members'), style:"),
    ("label: const Text('新增旅伴'),", "label: Text(strings.t('addTraveler')),"),
    ("decoration: InputDecoration(labelText: '旅伴 ${index + 1}'),", "decoration: InputDecoration(labelText: '${strings.t('traveler')} ${index + 1}'),"),
    ("'免費版每趟旅程最多 3 位旅伴；${PremiumService.productLabel} ${PremiumService.priceLabel} 可使用更多旅伴。'", "strings.t('moreThan3Travelers')"),
    ("label: const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Text('建立旅程')),", "label: Padding(padding: const EdgeInsets.symmetric(vertical: 14), child: Text(strings.t('newTrip'))),")
]
for old, new in replacements:
    if old not in s:
        raise SystemExit(f'CreateTrip target not found: {old}')
    s = s.replace(old, new, 1)
s = s.replace("  Future<void> _addMemberField(bool premium) async {\n", "  Future<void> _addMemberField(bool premium) async {\n    final strings = AppStrings(widget.controller.languageCode);\n", 1)
s = s.replace("title: const Text('需要 TripBanBan Plus'),", "title: Text(PremiumService.productLabel),")
s = s.replace("content: const Text('免費版每趟旅程最多 3 人。Plus 為 US\\$1.99 一次買斷，可使用更多旅伴。'),", "content: Text(strings.t('moreThan3Travelers')),")
s = s.replace("actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('知道了'))]", "actions: [FilledButton(onPressed: () => Navigator.pop(context), child: Text(strings.t('ok')))]")
s = s.replace("  Widget _dateButton(String label, DateTime? value, ValueChanged<DateTime> onPicked) {\n    return OutlinedButton(", "  Widget _dateButton(String label, DateTime? value, ValueChanged<DateTime> onPicked) {\n    final strings = AppStrings(widget.controller.languageCode);\n    return OutlinedButton(", 1)
s = s.replace("Text(value == null ? '選擇' : '${value.year}/${value.month}/${value.day}')", "Text(value == null ? strings.t('choose') : '${value.year}/${value.month}/${value.day}')")
s = s.replace("  Future<void> _save() async {\n    FocusScope.of(context).unfocus();", "  Future<void> _save() async {\n    final strings = AppStrings(widget.controller.languageCode);\n    FocusScope.of(context).unfocus();", 1)
s = s.replace("const SnackBar(content: Text('請輸入旅程名稱並至少保留一位旅伴。'))", "SnackBar(content: Text(strings.t('tripValidation')))")
s = s.replace("const SnackBar(content: Text('免費版每趟旅程最多 3 位旅伴。'))", "SnackBar(content: Text(strings.t('moreThan3Travelers')))")
s = s.replace("throw StateError('旅伴同步失敗：預期 ${memberNames.length} 人，實際 ${verifiedMembers.length} 人');", "throw StateError('${strings.t('traveler')}: ${verifiedMembers.length}/${memberNames.length}');")
p.write_text(s)

# Google Drive: support a Web OAuth client ID supplied at build time.
p = Path('lib/features/backup/google_drive_backup_service.dart')
s = p.read_text()
s = s.replace("  static const _scopes = <String>[drive.DriveApi.driveAppdataScope];", "  static const _scopes = <String>[drive.DriveApi.driveAppdataScope];\n  static const _serverClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID', defaultValue: '');")
s = s.replace("    await _signIn.initialize();", "    if (_serverClientId.trim().isEmpty) {\n      _initialized = true;\n      return;\n    }\n    await _signIn.initialize(serverClientId: _serverClientId);")
s = s.replace("  Future<GoogleDriveBackupState> connectInteractive() async {\n    await initialize();", "  Future<GoogleDriveBackupState> connectInteractive() async {\n    if (_serverClientId.trim().isEmpty) {\n      throw StateError('GOOGLE_SERVER_CLIENT_ID_NOT_CONFIGURED');\n    }\n    await initialize();")
s = s.replace("  Future<void> disconnect() async {\n    await initialize();\n    await _signIn.signOut();", "  Future<void> disconnect() async {\n    await initialize();\n    if (_serverClientId.trim().isEmpty) return;\n    await _signIn.signOut();")
p.write_text(s)

# Replace the raw Google exception with a localizable setup message.
p = Path('lib/screens/settings_screen.dart')
s = p.read_text()
needle = "content: Text('$e'),"
if needle not in s:
    raise SystemExit('Settings error target not found')
s = s.replace(needle, "content: Text('$e'.contains('GOOGLE_SERVER_CLIENT_ID_NOT_CONFIGURED') ? _strings.t('driveConfigMissing') : '$e'),", 1)
p.write_text(s)

print('Run50 localization and Drive OAuth patch applied')
