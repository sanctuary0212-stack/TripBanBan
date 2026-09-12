from pathlib import Path

settings = r'''import 'package:flutter/material.dart';

import '../app/app_controller.dart';
import '../domain/currency_catalog.dart';
import '../features/backup/backup_service.dart';
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
          _section(strings.t('general'), [
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
                final code = await showCurrencyPicker(
                  context,
                  selected: widget.controller.defaultCurrency,
                  title: strings.t('defaultCurrency'),
                );
                if (code != null) await widget.controller.setDefaultCurrency(code);
              },
            ),
          ]),
          const SizedBox(height: 12),
          _premiumSection(premium, strings),
          const SizedBox(height: 12),
          _section(
            strings.t('localImportExport'),
            premium.isPremium ? _premiumBackupChildren(strings) : _lockedBackupChildren(strings),
          ),
          const SizedBox(height: 12),
          _section('About', const [
            Padding(
              padding: EdgeInsets.only(top: 8, bottom: 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('v0.8.4', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
              ),
            ),
            _ReleaseNote(text: 'Updated App logo and Android launcher icon'),
            _ReleaseNote(text: 'Added destination landmark silhouettes to trip cards'),
            _ReleaseNote(text: 'Expanded language selection to 10 commonly used languages'),
            _ReleaseNote(text: 'Trip page: new trips can still be created after projects exist'),
            _ReleaseNote(text: 'Settlement: trip switching, aligned per-person totals, and transfer suggestions'),
            _ReleaseNote(text: 'Plus: more travelers and complete .tripbanban import / export'),
            _ReleaseNote(text: 'Removed Google Drive backup and restore'),
          ]),
        ],
      ),
    );
  }

  Widget _premiumSection(PremiumService premium, AppStrings strings) => Card(
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
                      premium.isPremium
                          ? strings.t('plusEnabled')
                          : '${PremiumService.productLabel} · ${PremiumService.priceLabel}',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _FeatureLine(icon: Icons.group_add_outlined, text: strings.t('moreThan3Travelers')),
              _FeatureLine(icon: Icons.import_export_rounded, text: strings.t('localImportExport')),
              if (premium.canUseDebugToggle) ...[
                const Divider(height: 26),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(strings.t('debugPremium')),
                  subtitle: Text(strings.t('debugPremiumDesc')),
                  value: premium.isPremium,
                  onChanged: busy ? null : _toggleDebugPremium,
                ),
              ] else if (!premium.isPremium) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(onPressed: null, child: Text(strings.t('purchaseSoon'))),
                ),
              ],
            ],
          ),
        ),
      );

  List<Widget> _lockedBackupChildren(AppStrings strings) => [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.lock_outline),
          title: const Text(PremiumService.productLabel),
          subtitle: Text('${strings.t('localImportExport')} · ${PremiumService.priceLabel}'),
        ),
      ];

  List<Widget> _premiumBackupChildren(AppStrings strings) => [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.archive_outlined),
          title: Text(strings.t('localBackup')),
          subtitle: Text(strings.t('localBackupDesc')),
          onTap: busy ? null : _shareLocalBackup,
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.unarchive_outlined),
          title: Text(strings.t('localRestore')),
          subtitle: Text(strings.t('localRestoreDesc')),
          onTap: busy ? null : _restoreLocalBackup,
        ),
      ];

  Widget _section(String title, List<Widget> children) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
              const SizedBox(height: 8),
              ...children,
            ],
          ),
        ),
      );

  Future<void> _toggleDebugPremium(bool value) async {
    setState(() => busy = true);
    try {
      await widget.controller.services.premium.setDebugPremium(value);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _selectLanguage() async {
    final strings = AppStrings(widget.controller.languageCode);
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
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                child: Text(strings.t('selectLanguage'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
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

  void _requirePremium() {
    if (!widget.controller.services.premium.isPremium) {
      throw StateError('${PremiumService.productLabel} · ${PremiumService.priceLabel}');
    }
  }

  Future<void> _shareLocalBackup() => _run(() async {
        _requirePremium();
        await widget.controller.services.backupFacade.createAndShareBackup();
      });

  Future<void> _restoreLocalBackup() => _run(() async {
        _requirePremium();
        final file = await widget.controller.services.backupFacade.pickBackupFile();
        if (file == null) return;
        final info = await widget.controller.services.localBackup.inspectBackup(file);
        final yes = await _confirmRestore(info);
        if (!yes) return;
        await widget.controller.services.localBackup.restoreAccountBackup(file);
        await widget.controller.initialize();
      });

  Future<bool> _confirmRestore(BackupInfo info) async {
    final strings = AppStrings(widget.controller.languageCode);
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.t('localRestore')),
        content: Text(
          '${strings.t('trips')}: ${info.tripCount}\n'
          '${strings.t('expenseRecords')}: ${info.expenseCount}\n\n'
          '${strings.t('localRestoreDesc')}',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(strings.t('cancel'))),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(strings.t('localRestore'))),
        ],
      ),
    );
    return yes == true;
  }

  Future<void> _run(Future<void> Function() action) async {
    final strings = AppStrings(widget.controller.languageCode);
    setState(() => busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) {
        showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(strings.t('operationFailed')),
            content: Text('$e'),
            actions: [FilledButton(onPressed: () => Navigator.pop(context), child: Text(strings.t('ok')))],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
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
'''
Path('lib/screens/settings_screen.dart').write_text(settings, encoding='utf-8')

# Remove Google Drive service from runtime dependency injection.
p = Path('lib/app/app_services.dart')
s = p.read_text(encoding='utf-8')
s = s.replace("import '../features/backup/google_drive_backup_service.dart';\n", '')
s = s.replace('    required this.driveBackup,\n', '')
s = s.replace("      driveBackup: GoogleDriveBackupService(\n        localBackup: localBackup,\n        repository: repository,\n      ),\n", '')
s = s.replace('  final GoogleDriveBackupService driveBackup;\n', '')
p.write_text(s, encoding='utf-8')

# Keep Workmanager only for daily FX and actively cancel the legacy Drive job.
scheduler = r'''import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

import '../../data/local/app_database.dart';
import '../fx/fx_rate_service.dart';

const String kTripBanBanDailyFxTask = 'tripbanban.dailyFxRefresh';

@pragma('vm:entry-point')
void tripBanBanBackgroundDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    final db = AppDatabase();
    try {
      if (task == kTripBanBanDailyFxTask) {
        final fx = FxRateService(db);
        await fx.updateDaily();
      }
      return true;
    } catch (_) {
      return false;
    } finally {
      await db.close();
    }
  });
}

class BackgroundScheduler {
  const BackgroundScheduler();

  Future<void> initialize() => Workmanager().initialize(tripBanBanBackgroundDispatcher);

  Future<void> enableDailyFx() async {
    await Workmanager().registerPeriodicTask(
      'tripbanban-daily-fx',
      kTripBanBanDailyFxTask,
      frequency: const Duration(hours: 24),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
    );
  }

  Future<void> disableLegacyDriveBackup() =>
      Workmanager().cancelByUniqueName('tripbanban-drive-backup');
}
'''
Path('lib/features/backup/backup_scheduler.dart').write_text(scheduler, encoding='utf-8')

# Cancel any Drive job saved by earlier test builds and clear its setting.
p = Path('lib/app/app_controller.dart')
s = p.read_text(encoding='utf-8')
needle = '    await services.premium.initialize();\n    await services.fx.ensureBootstrapRates();\n'
replacement = "    await services.premium.initialize();\n    try {\n      await services.repository.setSetting('backup.autoDrive', 'false');\n      await services.background.disableLegacyDriveBackup();\n    } catch (_) {}\n    await services.fx.ensureBootstrapRates();\n"
if needle not in s:
    raise SystemExit('AppController initialize target not found')
s = s.replace(needle, replacement, 1)
p.write_text(s, encoding='utf-8')

# Drop Google-specific packages from this build. Workmanager stays for daily FX.
p = Path('pubspec.yaml')
s = p.read_text(encoding='utf-8')
for line in [
    '  # Google Drive AppData backup\n',
    '  google_sign_in: ^7.2.0\n',
    '  extension_google_sign_in_as_googleapis_auth: ^3.0.0\n',
    '  googleapis: ^17.0.0\n',
    '  googleapis_auth: ^2.3.3\n',
    '\n  # Best-effort background backup scheduling\n',
]:
    s = s.replace(line, '')
p.write_text(s, encoding='utf-8')

# The Drive implementation is intentionally removed from the compiled product.
drive_file = Path('lib/features/backup/google_drive_backup_service.dart')
if drive_file.exists():
    drive_file.unlink()

print('Run55 applied: Google Drive removed; local import/export is Plus-only')
