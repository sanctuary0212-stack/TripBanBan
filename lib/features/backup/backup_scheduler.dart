import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

import '../../data/local/app_database.dart';
import '../../data/repositories/ledger_repository.dart';
import '../fx/fx_rate_service.dart';
import 'backup_service.dart';
import 'google_drive_backup_service.dart';

const String kTripBanBanDailyBackupTask = 'tripbanban.dailyDriveBackup';
const String kTripBanBanDailyFxTask = 'tripbanban.dailyFxRefresh';

@pragma('vm:entry-point')
void tripBanBanBackgroundDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    final db = AppDatabase();
    try {
      switch (task) {
        case kTripBanBanDailyBackupTask:
          final repo = LedgerRepository(db);
          final local = LocalBackupService(db);
          final drive = GoogleDriveBackupService(localBackup: local, repository: repo);
          // Never show authorization UI from background work. If cached authorization
          // is unavailable, the job safely skips and local data stays authoritative.
          await drive.backupNow(allowInteractiveAuthorization: false);
          return true;
        case kTripBanBanDailyFxTask:
          final fx = FxRateService(db);
          await fx.updateDaily();
          return true;
        default:
          return true;
      }
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

  Future<void> enableDailyBackup({bool wifiOnly = false}) async {
    await Workmanager().registerPeriodicTask(
      'tripbanban-drive-backup',
      kTripBanBanDailyBackupTask,
      frequency: const Duration(hours: 24),
      constraints: Constraints(
        networkType: wifiOnly ? NetworkType.unmetered : NetworkType.connected,
        requiresBatteryNotLow: true,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
    );
  }

  Future<void> disableDailyBackup() =>
      Workmanager().cancelByUniqueName('tripbanban-drive-backup');
}
