import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tripbanban_app/data/local/app_database.dart';
import 'package:tripbanban_app/data/repositories/ledger_repository.dart';
import 'package:tripbanban_app/domain/ledger_models.dart';
import 'package:tripbanban_app/domain/ledger_service.dart';

void main() {
  late AppDatabase db;
  late LedgerRepository repo;
  late LedgerService ledger;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = LedgerRepository(db);
    ledger = LedgerService(repo);
  });

  tearDown(() => db.close());

  test('trip status is notStarted before any expense', () async {
    final tripId = await repo.createTrip(name: 'Tokyo', baseCurrency: 'JPY', memberNames: ['A', 'B']);
    final snapshot = await ledger.calculate(tripId);
    expect(snapshot.status, TripAccountingStatus.notStarted);
    expect(snapshot.totalExpenseMinor, 0);
  });

  test('single member-paid equal expense creates one suggested transfer', () async {
    final tripId = await repo.createTrip(name: 'Tokyo', baseCurrency: 'JPY', memberNames: ['A', 'B']);
    final members = await repo.getMembers(tripId);
    await repo.saveExpense(
      ExpenseDraft(
        tripId: tripId,
        title: 'Dinner',
        originalAmountMinor: 1000,
        originalCurrency: 'JPY',
        baseAmountMinor: 1000,
        baseCurrency: 'JPY',
        exchangeRateText: '1',
        payerType: 'MEMBER',
        payerMemberId: members[0].id,
        categoryKey: 'FOOD',
        occurredAt: DateTime(2026, 9, 11),
        shares: [
          ExpenseShareDraft(memberId: members[0].id, amountMinor: 500, mode: 'EQUAL'),
          ExpenseShareDraft(memberId: members[1].id, amountMinor: 500, mode: 'EQUAL'),
        ],
      ),
    );

    final snapshot = await ledger.calculate(tripId);
    expect(snapshot.status, TripAccountingStatus.pendingSettlement);
    expect(snapshot.suggestedTransfers, hasLength(1));
    final transfer = snapshot.suggestedTransfers.single;
    expect(transfer.fromMemberId, members[1].id);
    expect(transfer.toMemberId, members[0].id);
    expect(transfer.amountMinor, 500);

    await repo.addSettlementPayment(
      tripId: tripId,
      fromMemberId: members[1].id,
      toMemberId: members[0].id,
      amountMinor: 500,
      currency: 'JPY',
    );
    final settled = await ledger.calculate(tripId);
    expect(settled.status, TripAccountingStatus.settled);
    expect(settled.suggestedTransfers, isEmpty);
  });

  test('public fund is isolated and must be zero before settled', () async {
    final trip1 = await repo.createTrip(name: 'Tokyo', baseCurrency: 'JPY', memberNames: ['A', 'B']);
    final trip2 = await repo.createTrip(name: 'Seoul', baseCurrency: 'KRW', memberNames: ['A', 'B']);
    final members = await repo.getMembers(trip1);
    await repo.addFundTransaction(tripId: trip1, memberId: members[0].id, type: 'CONTRIBUTION', amountMinor: 1000);

    final one = await ledger.calculate(trip1);
    final two = await ledger.calculate(trip2);
    expect(one.fundBalanceMinor, 1000);
    expect(two.fundBalanceMinor, 0);
  });

  test('multiple expenses accumulate and editing one does not replace another', () async {
    final tripId = await repo.createTrip(name: 'Tokyo', baseCurrency: 'JPY', memberNames: ['A', 'B']);
    final members = await repo.getMembers(tripId);

    final firstId = await repo.saveExpense(
      ExpenseDraft(
        tripId: tripId,
        title: 'Hotel',
        originalAmountMinor: 500,
        originalCurrency: 'JPY',
        baseAmountMinor: 500,
        baseCurrency: 'JPY',
        exchangeRateText: '1',
        payerType: 'MEMBER',
        payerMemberId: members[0].id,
        categoryKey: 'STAY',
        occurredAt: DateTime(2026, 9, 12, 9),
        shares: [
          ExpenseShareDraft(memberId: members[0].id, amountMinor: 250, mode: 'EQUAL'),
          ExpenseShareDraft(memberId: members[1].id, amountMinor: 250, mode: 'EQUAL'),
        ],
      ),
    );

    await repo.saveExpense(
      ExpenseDraft(
        tripId: tripId,
        title: 'Lunch',
        originalAmountMinor: 800,
        originalCurrency: 'JPY',
        baseAmountMinor: 800,
        baseCurrency: 'JPY',
        exchangeRateText: '1',
        payerType: 'MEMBER',
        payerMemberId: members[1].id,
        categoryKey: 'FOOD',
        occurredAt: DateTime(2026, 9, 12, 12),
        shares: [
          ExpenseShareDraft(memberId: members[0].id, amountMinor: 400, mode: 'EQUAL'),
          ExpenseShareDraft(memberId: members[1].id, amountMinor: 400, mode: 'EQUAL'),
        ],
      ),
    );

    var rows = await repo.getExpenses(tripId);
    expect(rows, hasLength(2));
    expect(rows.fold<int>(0, (sum, e) => sum + e.baseAmountMinor), 1300);
    expect((await ledger.calculate(tripId)).totalExpenseMinor, 1300);

    await repo.saveExpense(
      ExpenseDraft(
        id: firstId,
        tripId: tripId,
        title: 'Hotel updated',
        originalAmountMinor: 700,
        originalCurrency: 'JPY',
        baseAmountMinor: 700,
        baseCurrency: 'JPY',
        exchangeRateText: '1',
        payerType: 'MEMBER',
        payerMemberId: members[0].id,
        categoryKey: 'STAY',
        occurredAt: DateTime(2026, 9, 12, 9),
        shares: [
          ExpenseShareDraft(memberId: members[0].id, amountMinor: 350, mode: 'EQUAL'),
          ExpenseShareDraft(memberId: members[1].id, amountMinor: 350, mode: 'EQUAL'),
        ],
      ),
    );

    rows = await repo.getExpenses(tripId);
    expect(rows, hasLength(2));
    expect(rows.fold<int>(0, (sum, e) => sum + e.baseAmountMinor), 1500);
    expect((await ledger.calculate(tripId)).totalExpenseMinor, 1500);
  });
}
