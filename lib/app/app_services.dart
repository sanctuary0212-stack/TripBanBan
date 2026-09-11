import '../data/local/app_database.dart';
import '../data/repositories/ledger_repository.dart';
import '../domain/ledger_service.dart';
import '../domain/split_service.dart';
import '../features/backup/backup_scheduler.dart';
import '../features/backup/backup_service.dart';
import '../features/backup/google_drive_backup_service.dart';
import '../features/backup/local_backup_facade.dart';
import '../features/expenses/expense_application_service.dart';
import '../features/expenses/fund_application_service.dart';
import '../features/expenses/trip_application_service.dart';
import '../features/fx/fx_rate_service.dart';
import '../features/share/csv_export_service.dart';
import '../features/share/platform_share_service.dart';
import '../features/share/report_factory.dart';
import '../features/share/settlement_image_service.dart';
import '../platform/attachment_storage_service.dart';

class AppServices {
  AppServices._({
    required this.db,
    required this.repository,
    required this.ledger,
    required this.split,
    required this.fx,
    required this.expenses,
    required this.fund,
    required this.trips,
    required this.attachments,
    required this.localBackup,
    required this.driveBackup,
    required this.backupFacade,
    required this.background,
    required this.reportFactory,
    required this.settlementImage,
    required this.csv,
    required this.share,
  });

  factory AppServices.create() {
    final db = AppDatabase();
    final repository = LedgerRepository(db);
    final ledger = LedgerService(repository);
    const split = SplitService();
    final fx = FxRateService(db);
    final attachments = AttachmentStorageService(db);
    final localBackup = LocalBackupService(db);
    const share = PlatformShareService();
    return AppServices._(
      db: db,
      repository: repository,
      ledger: ledger,
      split: split,
      fx: fx,
      expenses: ExpenseApplicationService(
        repository: repository,
        ledger: ledger,
        fx: fx,
        split: split,
        attachments: attachments,
      ),
      fund: FundApplicationService(repository: repository, ledger: ledger),
      trips: TripApplicationService(repository: repository, attachments: attachments),
      attachments: attachments,
      localBackup: localBackup,
      driveBackup: GoogleDriveBackupService(
        localBackup: localBackup,
        repository: repository,
      ),
      backupFacade: LocalBackupFacade(backups: localBackup, share: share),
      background: const BackgroundScheduler(),
      reportFactory: ReportFactory(repository: repository, ledger: ledger),
      settlementImage: SettlementImageService(),
      csv: CsvExportService(repository),
      share: share,
    );
  }

  final AppDatabase db;
  final LedgerRepository repository;
  final LedgerService ledger;
  final SplitService split;
  final FxRateService fx;
  final ExpenseApplicationService expenses;
  final FundApplicationService fund;
  final TripApplicationService trips;
  final AttachmentStorageService attachments;
  final LocalBackupService localBackup;
  final GoogleDriveBackupService driveBackup;
  final LocalBackupFacade backupFacade;
  final BackgroundScheduler background;
  final ReportFactory reportFactory;
  final SettlementImageService settlementImage;
  final CsvExportService csv;
  final PlatformShareService share;

  Future<void> dispose() => db.close();
}
