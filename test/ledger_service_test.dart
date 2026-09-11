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
}
