import 'package:flutter/material.dart';

import '../app/app_controller.dart';
import '../domain/currency_catalog.dart';
import '../features/backup/backup_service.dart';
import '../features/backup/google_drive_backup_service.dart';
import '../features/premium/premium_service.dart';
import '../localization/app_strings.dart';
import '../widgets/currency_picker.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.controller});
  final AppController controller;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool busy = false;
  GoogleDriveBackupState? driveState;
  bool autoBackup = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller.services.premium.isPremium) _refreshDriveState();
    _loadAutoBackup();
  }

  Future<void> _refreshDriveState() async {
    try {
      final state = await widget.controller.services.driveBackup.state();
      if (mounted) setState(() => driveState = state);
    } catch (_) {}
  }

  Future<void> _loadAutoBackup() async {
    final raw = await widget.controller.services.repository.getSetting('backup.autoDrive');
    if (mounted) setState(() => autoBackup = raw == 'true');
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings(widget.controller.languageCode);
    final currency = CurrencyCatalog.find(widget.controller.defaultCurrency);
    final premium = widget.controller.services.premium;
    return Scaffold(
      appBar: AppBar(title: Text(strings.t('settings'), style: const TextStyle(fontWeight: FontWeight.w800))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          _section('一般', [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.language),
              title: Text(strings.t('language')),
              subtitle: Text(_languageName(widget.controller.languageCode)),
              trailing: const Icon(Icons.chevron_right),
              onTap: _selectLanguage,
            ),
            const Divider(height: 1),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.currency_exchange),
              title: Text(strings.t('defaultCurrency')),
              subtitle: Text('${widget.controller.defaultCurrency} · ${currency?.name ?? ''}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final code = await showCurrencyPicker(context, selected: widget.controller.defaultCurrency, title: strings.t('defaultCurrency'));
                if (code != null) await widget.controller.setDefaultCurrency(code);
              },
            ),
          ]),
          const SizedBox(height: 12),
          _premiumSection(premium),
          const SizedBox(height: 12),
          _section('Google Drive', premium.isPremium ? _premiumDriveChildren(strings) : _lockedDriveChildren()),
          const SizedBox(height: 12),
          _section('本機匯入 / 匯出', [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.archive_outlined),
              title: Text(strings.t('localBackup')),
              subtitle: const Text('包含帳本 JSON 快照與本機照片附件'),
              onTap: busy ? null : _shareLocalBackup,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.unarchive_outlined),
              title: Text(strings.t('localRestore')),
              subtitle: const Text('先顯示備份摘要，確認後才覆蓋本機資料'),
              onTap: busy ? null : _restoreLocalBackup,
            ),
          ]),
          const SizedBox(height: 12),
          _section('關於', const [
            Padding(
              padding: EdgeInsets.only(top: 8, bottom: 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('v0.8.4', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
              ),
            ),
            _ReleaseNote(text: '更新 App Logo 與 Android launcher icon'),
            _ReleaseNote(text: '旅程卡片加入依目的地顯示的地標剪影圖樣'),
            _ReleaseNote(text: '多國語言擴充至 10 種常用語言'),
            _ReleaseNote(text: '旅程頁修正：已有專案後仍可建立新旅程'),
            _ReleaseNote(text: '結算頁可切換旅程，並優化每人支出欄位與最終轉帳建議'),
            _ReleaseNote(text: '持續支援公基金退款與 Plus / Google Drive 功能'),
          ]),
        ],
      ),
    );
  }

  Widget _premiumSection(PremiumService premium) => Card(
        clipBehavior: Clip.antiAlias,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFFE8FFF8), Color(0xFFF9FFF3)]),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.workspace_premium_rounded, color: Color(0xFF00796B)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      premium.isPremium ? 'TripBanBan Plus 已啟用' : '${PremiumService.productLabel} · ${PremiumService.priceLabel}',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text('一次買斷 · 解鎖更多旅伴與雲端功能'),
              const SizedBox(height: 10),
              const _FeatureLine(icon: Icons.group_add_outlined, text: '旅伴可超過 3 人'),
              const _FeatureLine(icon: Icons.cloud_outlined, text: 'Google Drive 備份與還原'),
              const _FeatureLine(icon: Icons.import_export_rounded, text: 'Google Drive 匯入 / 匯出流程'),
              if (premium.canUseDebugToggle) ...[
                const Divider(height: 26),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('測試付費版功能'),
                  subtitle: const Text('僅 Debug APK 顯示，方便目前測試；正式版不會有此開關。'),
                  value: premium.isPremium,
                  onChanged: busy ? null : _toggleDebugPremium,
                ),
              ] else if (!premium.isPremium) ...[
                const SizedBox(height: 12),
                const SizedBox(
                  width: double.infinity,
                  child: FilledButton(onPressed: null, child: Text('Google Play 商品建立後開放購買')),
                ),
              ],
            ],
          ),
        ),
      );

  List<Widget> _lockedDriveChildren() => const [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.lock_outline),
          title: Text('Google Drive 為 Plus 功能'),
          subtitle: Text('升級 US\$1.99 Plus 後，可將備份存放在自己的 Google Drive，並從雲端還原。'),
        ),
      ];

  List<Widget> _premiumDriveChildren(AppStrings strings) => [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.cloud_outlined),
          title: Text(strings.t('driveBackup')),
          subtitle: Text(
            driveState?.email.isNotEmpty == true
                ? '${driveState!.email}\n最後備份：${_dateTime(driveState!.lastBackupAt)}'
                : '尚未連結 · 備份存放在使用者自己的 Drive AppData',
          ),
          isThreeLine: driveState?.email.isNotEmpty == true,
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(onPressed: busy ? null : _connectDrive, icon: const Icon(Icons.link), label: Text(strings.t('connectGoogle'))),
            FilledButton.tonalIcon(onPressed: busy || driveState?.email.isEmpty != false ? null : _driveBackupNow, icon: const Icon(Icons.cloud_upload_outlined), label: Text(strings.t('backupNow'))),
            OutlinedButton.icon(onPressed: busy || driveState?.email.isEmpty != false ? null : _restoreDrive, icon: const Icon(Icons.cloud_download_outlined), label: Text(strings.t('restoreDrive'))),
          ],
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('每日自動備份'),
          subtitle: const Text('最佳努力排程；離線時仍以本機資料為準。'),
          value: autoBackup,
          onChanged: driveState?.email.isEmpty != false || busy ? null : _toggleAutoBackup,
        ),
      ];

  Widget _section(String title, List<Widget> children) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
            const SizedBox(height: 8),
            ...children,
          ]),
        ),
      );

  Future<void> _toggleDebugPremium(bool value) async {
    setState(() => busy = true);
    try {
      await widget.controller.services.premium.setDebugPremium(value);
      if (value) {
        await _refreshDriveState();
      } else {
        autoBackup = false;
        driveState = null;
        await widget.controller.services.repository.setSetting('backup.autoDrive', 'false');
        try {
          await widget.controller.services.background.disableDailyBackup();
        } catch (_) {}
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _selectLanguage() async {
    final options = const <String, String>{
      'zh_Hant': '繁體中文',
      'zh_Hans': '简体中文',
      'en': 'English',
      'ja': '日本語',
      'ko': '한국어',
      'fr': 'Français',
      'de': 'Deutsch',
      'es': 'Español',
      'it': 'Italiano',
      'th': 'ไทย',
    };
    final code = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .75),
          child: ListView(
            shrinkWrap: true,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 18, 20, 8),
                child: Text('選擇語言', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              ),
              for (final entry in options.entries)
                RadioListTile<String>(
                  value: entry.key,
                  groupValue: widget.controller.languageCode,
                  title: Text(entry.value),
                  onChanged: (value) => Navigator.pop(context, value),
                ),
            ],
          ),
        ),
      ),
    );
    if (code != null) await widget.controller.setLanguage(code);
  }

  Future<void> _connectDrive() => _run(() async {
        _requirePremium();
        await widget.controller.services.driveBackup.connectInteractive();
        await _refreshDriveState();
      });

  Future<void> _driveBackupNow() => _run(() async {
        _requirePremium();
        final ok = await widget.controller.services.driveBackup.backupNow(allowInteractiveAuthorization: true);
        if (!ok) throw StateError('Google Drive 尚未授權。');
        await _refreshDriveState();
        _toast('Google Drive 備份完成');
      });

  Future<void> _restoreDrive() => _run(() async {
        _requirePremium();
        final info = await widget.controller.services.driveBackup.inspectRemoteBackup(allowInteractiveAuthorization: true);
        if (info == null) throw StateError('Google Drive 中沒有 TripBanBan 備份。');
        final yes = await _confirmRestore(info, 'Google Drive');
        if (!yes) return;
        final ok = await widget.controller.services.driveBackup.restoreRemoteBackup(allowInteractiveAuthorization: true);
        if (!ok) throw StateError('還原失敗。');
        await widget.controller.initialize();
        _toast('還原完成');
      });

  void _requirePremium() {
    if (!widget.controller.services.premium.isPremium) {
      throw StateError('此功能需要 TripBanBan Plus。');
    }
  }

  Future<void> _shareLocalBackup() => _run(() async {
        await widget.controller.services.backupFacade.createAndShareBackup();
      });

  Future<void> _restoreLocalBackup() => _run(() async {
        final file = await widget.controller.services.backupFacade.pickBackupFile();
        if (file == null) return;
        final info = await widget.controller.services.localBackup.inspectBackup(file);
        final yes = await _confirmRestore(info, '本機備份');
        if (!yes) return;
        await widget.controller.services.localBackup.restoreAccountBackup(file);
        await widget.controller.initialize();
        _toast('還原完成');
      });

  Future<void> _toggleAutoBackup(bool value) async {
    _requirePremium();
    setState(() => autoBackup = value);
    await widget.controller.services.repository.setSetting('backup.autoDrive', value.toString());
    try {
      if (value) {
        await widget.controller.services.background.enableDailyBackup();
      } else {
        await widget.controller.services.background.disableDailyBackup();
      }
    } catch (e) {
      _toast('背景排程設定失敗：$e');
    }
  }

  Future<bool> _confirmRestore(BackupInfo info, String source) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('從 $source 還原？'),
        content: Text(
          '備份時間：${_dateTime(info.createdAt)}\n'
          '旅程：${info.tripCount}\n支出：${info.expenseCount}\n照片附件：${info.attachmentCount}\n\n'
          '還原會覆蓋目前本機資料。',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('覆蓋並還原')),
        ],
      ),
    );
    return yes == true;
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) {
        showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('操作失敗'),
            content: Text('$e'),
            actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('知道了'))],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _dateTime(DateTime? value) {
    if (value == null) return '尚無';
    final local = value.toLocal();
    return '${local.year}/${local.month}/${local.day} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  String _languageName(String code) => switch (code) {
        'zh_Hans' => '简体中文',
        'en' => 'English',
        'ja' => '日本語',
        'ko' => '한국어',
        'fr' => 'Français',
        'de' => 'Deutsch',
        'es' => 'Español',
        'it' => 'Italiano',
        'th' => 'ไทย',
        _ => '繁體中文',
      };
}

class _FeatureLine extends StatelessWidget {
  const _FeatureLine({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 19, color: const Color(0xFF00796B)),
            const SizedBox(width: 9),
            Expanded(child: Text(text)),
          ],
        ),
      );
}

class _ReleaseNote extends StatelessWidget {
  const _ReleaseNote({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 7),
              child: Icon(Icons.circle, size: 6),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(text)),
          ],
        ),
      );
}
