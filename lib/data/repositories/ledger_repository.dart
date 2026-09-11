import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../local/app_database.dart';

class ExpenseShareDraft {
  const ExpenseShareDraft({
    required this.memberId,
    required this.amountMinor,
    required this.mode,
    this.ratioText,
  });

  final String memberId;
  final int amountMinor;
  final String mode;
  final String? ratioText;
}

class ExpenseDraft {
  const ExpenseDraft({
    this.id,
    required this.tripId,
    required this.title,
    this.note,
    required this.originalAmountMinor,
    required this.originalCurrency,
    required this.baseAmountMinor,
    required this.baseCurrency,
    required this.exchangeRateText,
    this.exchangeRateDate,
    this.exchangeRateSource,
    required this.payerType,
    this.payerMemberId,
    required this.categoryKey,
    this.customCategoryId,
    required this.occurredAt,
    required this.shares,
  });

  final String? id;
  final String tripId;
  final String title;
  final String? note;
  final int originalAmountMinor;
  final String originalCurrency;
  final int baseAmountMinor;
  final String baseCurrency;
  final String exchangeRateText;
  final DateTime? exchangeRateDate;
  final String? exchangeRateSource;
  final String payerType;
  final String? payerMemberId;
  final String categoryKey;
  final String? customCategoryId;
  final DateTime occurredAt;
  final List<ExpenseShareDraft> shares;
}

class LedgerRepository {
  LedgerRepository(this.db, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final AppDatabase db;
  final Uuid _uuid;

  Future<String> createTrip({
    required String name,
    String? destination,
    String? countryCode,
    DateTime? startDate,
    DateTime? endDate,
    required String baseCurrency,
    required List<String> memberNames,
  }) async {
    final now = DateTime.now();
    final tripId = _uuid.v7();
    await db.transaction(() async {
      await db.into(db.trips).insert(
            TripsCompanion.insert(
              id: tripId,
              name: name.trim(),
              destination: Value(destination?.trim().isEmpty == true ? null : destination?.trim()),
              countryCode: Value(countryCode),
              startDate: Value(startDate),
              endDate: Value(endDate),
              baseCurrency: baseCurrency.toUpperCase(),
              createdAt: now,
              updatedAt: now,
            ),
          );
      for (var index = 0; index < memberNames.length; index++) {
        final memberName = memberNames[index].trim();
        if (memberName.isEmpty) continue;
        await db.into(db.members).insert(
              MembersCompanion.insert(
                id: _uuid.v7(),
                tripId: tripId,
                displayName: memberName,
                sortOrder: Value(index),
                createdAt: now,
                updatedAt: now,
              ),
            );
      }
    });
    return tripId;
  }

  Stream<List<TripRow>> watchTrips() =>
      (db.select(db.trips)..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).watch();

  Future<TripRow?> getTrip(String tripId) =>
      (db.select(db.trips)..where((t) => t.id.equals(tripId))).getSingleOrNull();

  Future<List<MemberRow>> getMembers(String tripId) =>
      (db.select(db.members)
            ..where((m) => m.tripId.equals(tripId))
            ..orderBy([(m) => OrderingTerm.asc(m.sortOrder)]))
          .get();

  Stream<List<MemberRow>> watchMembers(String tripId) =>
      (db.select(db.members)
            ..where((m) => m.tripId.equals(tripId))
            ..orderBy([(m) => OrderingTerm.asc(m.sortOrder)]))
          .watch();

  Future<String> addMember(String tripId, String displayName) async {
    final now = DateTime.now();
    final existing = await getMembers(tripId);
    final id = _uuid.v7();
    await db.transaction(() async {
      await db.into(db.members).insert(
            MembersCompanion.insert(
              id: id,
              tripId: tripId,
              displayName: displayName.trim(),
              sortOrder: Value(existing.length),
              createdAt: now,
              updatedAt: now,
            ),
          );
      await (db.update(db.trips)..where((t) => t.id.equals(tripId))).write(
        TripsCompanion(updatedAt: Value(now)),
      );
    });
    return id;
  }

  Future<void> renameMember(String memberId, String displayName) =>
      (db.update(db.members)..where((m) => m.id.equals(memberId))).write(
        MembersCompanion(
          displayName: Value(displayName.trim()),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<bool> canDeleteMember(String memberId) async {
    final shareCount = await (db.selectOnly(db.expenseShares)
          ..addColumns([db.expenseShares.memberId.count()])
          ..where(db.expenseShares.memberId.equals(memberId)))
        .map((row) => row.read(db.expenseShares.memberId.count()) ?? 0)
        .getSingle();
    final payerCount = await (db.selectOnly(db.expenses)
          ..addColumns([db.expenses.id.count()])
          ..where(db.expenses.payerMemberId.equals(memberId)))
        .map((row) => row.read(db.expenses.id.count()) ?? 0)
        .getSingle();
    final fundCount = await (db.selectOnly(db.fundTransactions)
          ..addColumns([db.fundTransactions.id.count()])
          ..where(db.fundTransactions.memberId.equals(memberId)))
        .map((row) => row.read(db.fundTransactions.id.count()) ?? 0)
        .getSingle();
    final settlementCount = await (db.selectOnly(db.settlementPayments)
          ..addColumns([db.settlementPayments.id.count()])
          ..where(db.settlementPayments.fromMemberId.equals(memberId) |
              db.settlementPayments.toMemberId.equals(memberId)))
        .map((row) => row.read(db.settlementPayments.id.count()) ?? 0)
        .getSingle();
    return shareCount + payerCount + fundCount + settlementCount == 0;
  }

  Future<void> deleteMember(String memberId) async {
    if (!await canDeleteMember(memberId)) {
      throw StateError('This member is referenced by accounting records.');
    }
    await (db.delete(db.members)..where((m) => m.id.equals(memberId))).go();
  }

  Future<String> saveExpense(ExpenseDraft draft) async {
    if (draft.baseAmountMinor <= 0) throw ArgumentError('Expense amount must be > 0.');
    if (draft.shares.isEmpty) throw ArgumentError('At least one member must share the expense.');
    final shareTotal = draft.shares.fold<int>(0, (sum, share) => sum + share.amountMinor);
    if (shareTotal != draft.baseAmountMinor) {
      throw StateError('Expense shares must equal the base expense amount.');
    }
    if (draft.payerType == 'MEMBER' && draft.payerMemberId == null) {
      throw StateError('Member-paid expense requires payerMemberId.');
    }

    final now = DateTime.now();
    final expenseId = draft.id ?? _uuid.v7();
    await db.transaction(() async {
      if (draft.id == null) {
        await db.into(db.expenses).insert(
              ExpensesCompanion.insert(
                id: expenseId,
                tripId: draft.tripId,
                title: Value(draft.title.trim()),
                note: Value(draft.note?.trim().isEmpty == true ? null : draft.note?.trim()),
                originalAmountMinor: draft.originalAmountMinor,
                originalCurrency: draft.originalCurrency.toUpperCase(),
                baseAmountMinor: draft.baseAmountMinor,
                baseCurrency: draft.baseCurrency.toUpperCase(),
                exchangeRateText: Value(draft.exchangeRateText),
                exchangeRateDate: Value(draft.exchangeRateDate),
                exchangeRateSource: Value(draft.exchangeRateSource),
                payerType: draft.payerType,
                payerMemberId: Value(draft.payerMemberId),
                categoryKey: draft.categoryKey,
                customCategoryId: Value(draft.customCategoryId),
                occurredAt: draft.occurredAt,
                createdAt: now,
                updatedAt: now,
              ),
            );
      } else {
        await (db.update(db.expenses)..where((e) => e.id.equals(expenseId))).write(
          ExpensesCompanion(
            title: Value(draft.title.trim()),
            note: Value(draft.note?.trim().isEmpty == true ? null : draft.note?.trim()),
            originalAmountMinor: Value(draft.originalAmountMinor),
            originalCurrency: Value(draft.originalCurrency.toUpperCase()),
            baseAmountMinor: Value(draft.baseAmountMinor),
            baseCurrency: Value(draft.baseCurrency.toUpperCase()),
            exchangeRateText: Value(draft.exchangeRateText),
            exchangeRateDate: Value(draft.exchangeRateDate),
            exchangeRateSource: Value(draft.exchangeRateSource),
            payerType: Value(draft.payerType),
            payerMemberId: Value(draft.payerMemberId),
            categoryKey: Value(draft.categoryKey),
            customCategoryId: Value(draft.customCategoryId),
            occurredAt: Value(draft.occurredAt),
            updatedAt: Value(now),
          ),
        );
        await (db.delete(db.expenseShares)..where((s) => s.expenseId.equals(expenseId))).go();
      }

      for (final share in draft.shares) {
        await db.into(db.expenseShares).insert(
              ExpenseSharesCompanion.insert(
                expenseId: expenseId,
                memberId: share.memberId,
                amountMinor: share.amountMinor,
                mode: Value(share.mode),
                ratioText: Value(share.ratioText),
              ),
            );
      }
      await (db.update(db.trips)..where((t) => t.id.equals(draft.tripId))).write(
        TripsCompanion(updatedAt: Value(now)),
      );
    });
    return expenseId;
  }

  Future<ExpenseRow?> getExpense(String expenseId) =>
      (db.select(db.expenses)..where((e) => e.id.equals(expenseId))).getSingleOrNull();

  Future<List<ExpenseShareRow>> getExpenseShares(String expenseId) =>
      (db.select(db.expenseShares)..where((s) => s.expenseId.equals(expenseId))).get();

  Future<void> deleteExpense(String expenseId) async {
    final row = await (db.select(db.expenses)..where((e) => e.id.equals(expenseId))).getSingleOrNull();
    if (row == null) return;
    await db.transaction(() async {
      await (db.delete(db.expenses)..where((e) => e.id.equals(expenseId))).go();
      await (db.update(db.trips)..where((t) => t.id.equals(row.tripId))).write(
        TripsCompanion(updatedAt: Value(DateTime.now())),
      );
    });
  }

  Future<List<ExpenseRow>> getExpenses(String tripId) =>
      (db.select(db.expenses)
            ..where((e) => e.tripId.equals(tripId))
            ..orderBy([(e) => OrderingTerm.desc(e.occurredAt)]))
          .get();

  Stream<List<ExpenseRow>> watchExpenses(String tripId) =>
      (db.select(db.expenses)
            ..where((e) => e.tripId.equals(tripId))
            ..orderBy([(e) => OrderingTerm.desc(e.occurredAt)]))
          .watch();

  Future<List<ExpenseShareRow>> getSharesForTrip(String tripId) async {
    final query = db.select(db.expenseShares).join([
      innerJoin(db.expenses, db.expenses.id.equalsExp(db.expenseShares.expenseId)),
    ])
      ..where(db.expenses.tripId.equals(tripId));
    final rows = await query.get();
    return rows.map((row) => row.readTable(db.expenseShares)).toList();
  }

  Future<String> addFundTransaction({
    required String tripId,
    String? memberId,
    required String type,
    required int amountMinor,
    String? note,
    DateTime? occurredAt,
  }) async {
    if (amountMinor <= 0) throw ArgumentError('Fund transaction amount must be > 0.');
    final id = _uuid.v7();
    final now = DateTime.now();
    await db.transaction(() async {
      await db.into(db.fundTransactions).insert(
            FundTransactionsCompanion.insert(
              id: id,
              tripId: tripId,
              memberId: Value(memberId),
              type: type,
              amountMinor: amountMinor,
              note: Value(note),
              occurredAt: occurredAt ?? now,
              createdAt: now,
            ),
          );
      await (db.update(db.trips)..where((t) => t.id.equals(tripId))).write(
        TripsCompanion(updatedAt: Value(now)),
      );
    });
    return id;
  }

  Stream<List<FundTransactionRow>> watchFundTransactions(String tripId) =>
      (db.select(db.fundTransactions)
            ..where((f) => f.tripId.equals(tripId))
            ..orderBy([(f) => OrderingTerm.asc(f.occurredAt)]))
          .watch();

  Future<List<FundTransactionRow>> getFundTransactions(String tripId) =>
      (db.select(db.fundTransactions)
            ..where((f) => f.tripId.equals(tripId))
            ..orderBy([(f) => OrderingTerm.asc(f.occurredAt)]))
          .get();

  Future<String> addSettlementPayment({
    required String tripId,
    required String fromMemberId,
    required String toMemberId,
    required int amountMinor,
    required String currency,
    DateTime? occurredAt,
  }) async {
    if (amountMinor <= 0) throw ArgumentError('Settlement amount must be > 0.');
    if (fromMemberId == toMemberId) throw ArgumentError('A member cannot pay themself.');
    final id = _uuid.v7();
    final now = DateTime.now();
    await db.transaction(() async {
      await db.into(db.settlementPayments).insert(
            SettlementPaymentsCompanion.insert(
              id: id,
              tripId: tripId,
              fromMemberId: fromMemberId,
              toMemberId: toMemberId,
              amountMinor: amountMinor,
              currency: currency,
              occurredAt: occurredAt ?? now,
              createdAt: now,
            ),
          );
      await (db.update(db.trips)..where((t) => t.id.equals(tripId))).write(
        TripsCompanion(updatedAt: Value(now)),
      );
    });
    return id;
  }

  Stream<List<SettlementPaymentRow>> watchSettlementPayments(String tripId) =>
      (db.select(db.settlementPayments)
            ..where((p) => p.tripId.equals(tripId))
            ..orderBy([(p) => OrderingTerm.asc(p.occurredAt)]))
          .watch();

  Future<List<SettlementPaymentRow>> getSettlementPayments(String tripId) =>
      (db.select(db.settlementPayments)
            ..where((p) => p.tripId.equals(tripId))
            ..orderBy([(p) => OrderingTerm.asc(p.occurredAt)]))
          .get();

  Future<List<CustomCategoryRow>> getCustomCategories(String tripId) =>
      (db.select(db.customCategories)
            ..where((c) => c.tripId.equals(tripId))
            ..orderBy([(c) => OrderingTerm.asc(c.name)]))
          .get();

  Stream<List<CustomCategoryRow>> watchCustomCategories(String tripId) =>
      (db.select(db.customCategories)
            ..where((c) => c.tripId.equals(tripId))
            ..orderBy([(c) => OrderingTerm.asc(c.name)]))
          .watch();

  Future<String> addCustomCategory({
    required String tripId,
    required String name,
    required String iconKey,
  }) async {
    final id = _uuid.v7();
    final now = DateTime.now();
    await db.into(db.customCategories).insert(
          CustomCategoriesCompanion.insert(
            id: id,
            tripId: tripId,
            name: name.trim(),
            iconKey: iconKey,
            createdAt: now,
            updatedAt: now,
          ),
        );
    return id;
  }

  Future<void> deleteCustomCategory(String id) async {
    final inUse = await (db.selectOnly(db.expenses)
          ..addColumns([db.expenses.id.count()])
          ..where(db.expenses.customCategoryId.equals(id)))
        .map((row) => row.read(db.expenses.id.count()) ?? 0)
        .getSingle();
    if (inUse > 0) throw StateError('Category is used by existing expenses.');
    await (db.delete(db.customCategories)..where((c) => c.id.equals(id))).go();
  }

  Future<void> setSetting(String key, String value) async {
    final now = DateTime.now();
    await db.into(db.appSettings).insertOnConflictUpdate(
          AppSettingsCompanion.insert(key: key, value: value, updatedAt: now),
        );
  }

  Future<String?> getSetting(String key) async {
    final row = await (db.select(db.appSettings)..where((s) => s.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> deleteTrip(String tripId) async {
    await (db.delete(db.trips)..where((t) => t.id.equals(tripId))).go();
  }
}
