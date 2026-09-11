import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

@DataClassName('TripRow')
class Trips extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get destination => text().nullable()();
  TextColumn get countryCode => text().nullable()();
  DateTimeColumn get startDate => dateTime().nullable()();
  DateTimeColumn get endDate => dateTime().nullable()();
  TextColumn get baseCurrency => text().withLength(min: 3, max: 8)();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('MemberRow')
class Members extends Table {
  TextColumn get id => text()();
  TextColumn get tripId => text().references(Trips, #id, onDelete: KeyAction.cascade)();
  TextColumn get displayName => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ExpenseRow')
class Expenses extends Table {
  TextColumn get id => text()();
  TextColumn get tripId => text().references(Trips, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get note => text().nullable()();

  // Source amount/currency entered by the user.
  IntColumn get originalAmountMinor => integer()();
  TextColumn get originalCurrency => text().withLength(min: 3, max: 8)();

  // Frozen settlement amount in the trip base currency.
  IntColumn get baseAmountMinor => integer()();
  TextColumn get baseCurrency => text().withLength(min: 3, max: 8)();
  TextColumn get exchangeRateText => text().withDefault(const Constant('1'))();
  DateTimeColumn get exchangeRateDate => dateTime().nullable()();
  TextColumn get exchangeRateSource => text().nullable()();

  // FUND or MEMBER. If MEMBER, payerMemberId must be non-null.
  TextColumn get payerType => text()();
  TextColumn get payerMemberId => text().nullable().references(Members, #id, onDelete: KeyAction.restrict)();

  // System category key (FOOD, STAY, ...), or CUSTOM.
  TextColumn get categoryKey => text()();
  TextColumn get customCategoryId => text().nullable()();

  DateTimeColumn get occurredAt => dateTime()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ExpenseShareRow')
class ExpenseShares extends Table {
  TextColumn get expenseId => text().references(Expenses, #id, onDelete: KeyAction.cascade)();
  TextColumn get memberId => text().references(Members, #id, onDelete: KeyAction.restrict)();
  IntColumn get amountMinor => integer()();
  TextColumn get mode => text().withDefault(const Constant('EQUAL'))();
  TextColumn get ratioText => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {expenseId, memberId};
}

@DataClassName('FundTransactionRow')
class FundTransactions extends Table {
  TextColumn get id => text()();
  TextColumn get tripId => text().references(Trips, #id, onDelete: KeyAction.cascade)();
  TextColumn get memberId => text().nullable().references(Members, #id, onDelete: KeyAction.restrict)();
  // CONTRIBUTION, REFUND, ADJUSTMENT.
  TextColumn get type => text()();
  IntColumn get amountMinor => integer()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get occurredAt => dateTime()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Actual money transfers that have been completed between members.
/// Suggested settlement transfers are derived and are never persisted.
@DataClassName('SettlementPaymentRow')
class SettlementPayments extends Table {
  TextColumn get id => text()();
  TextColumn get tripId => text().references(Trips, #id, onDelete: KeyAction.cascade)();
  TextColumn get fromMemberId => text().references(Members, #id, onDelete: KeyAction.restrict)();
  TextColumn get toMemberId => text().references(Members, #id, onDelete: KeyAction.restrict)();
  IntColumn get amountMinor => integer()();
  TextColumn get currency => text()();
  DateTimeColumn get occurredAt => dateTime()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('AttachmentRow')
class Attachments extends Table {
  TextColumn get id => text()();
  TextColumn get expenseId => text().references(Expenses, #id, onDelete: KeyAction.cascade)();
  // RECEIPT or PHOTO.
  TextColumn get type => text()();
  TextColumn get relativePath => text()();
  TextColumn get mimeType => text().nullable()();
  IntColumn get byteLength => integer().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('CustomCategoryRow')
class CustomCategories extends Table {
  TextColumn get id => text()();
  TextColumn get tripId => text().references(Trips, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  TextColumn get iconKey => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('CustomCurrencyRow')
class CustomCurrencies extends Table {
  TextColumn get id => text()();
  TextColumn get tripId => text().nullable().references(Trips, #id, onDelete: KeyAction.cascade)();
  TextColumn get code => text()();
  TextColumn get name => text()();
  TextColumn get symbol => text()();
  IntColumn get decimalPlaces => integer().withDefault(const Constant(2))();
  TextColumn get manualRateToTripBase => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('FxRateRow')
class FxRates extends Table {
  TextColumn get baseCurrency => text()();
  TextColumn get quoteCurrency => text()();
  TextColumn get rateText => text()();
  DateTimeColumn get rateDate => dateTime()();
  TextColumn get source => text()();
  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {baseCurrency, quoteCurrency, rateDate};
}

@DataClassName('AppSettingRow')
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

@DriftDatabase(
  tables: [
    Trips,
    Members,
    Expenses,
    ExpenseShares,
    FundTransactions,
    SettlementPayments,
    Attachments,
    CustomCategories,
    CustomCurrencies,
    FxRates,
    AppSettings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase()
      : super(
          driftDatabase(
            name: 'tripbanban',
            native: const DriftNativeOptions(shareAcrossIsolates: true),
          ),
        );

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
        onCreate: (m) async {
          await m.createAll();
        },
      );
}
