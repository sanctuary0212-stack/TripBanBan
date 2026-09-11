import '../data/local/app_database.dart';
import '../data/repositories/ledger_repository.dart';
import 'ledger_models.dart';

class LedgerService {
  const LedgerService(this.repository);

  final LedgerRepository repository;

  Future<LedgerSnapshot> calculate(String tripId) async {
    final trip = await repository.getTrip(tripId);
    if (trip == null) throw ArgumentError.value(tripId, 'tripId', 'Unknown trip');

    final members = await repository.getMembers(tripId);
    final expenses = await repository.getExpenses(tripId);
    final shares = await repository.getSharesForTrip(tripId);
    final fund = await repository.getFundTransactions(tripId);
    final settlements = await repository.getSettlementPayments(tripId);

    final paid = {for (final member in members) member.id: 0};
    final owed = {for (final member in members) member.id: 0};
    final fundNet = {for (final member in members) member.id: 0};
    final settlementNet = {for (final member in members) member.id: 0};

    var totalExpenseMinor = 0;
    var fundExpenseMinor = 0;

    for (final expense in expenses) {
      totalExpenseMinor += expense.baseAmountMinor;
      if (expense.payerType == 'FUND') {
        fundExpenseMinor += expense.baseAmountMinor;
      } else if (expense.payerType == 'MEMBER') {
        final payer = expense.payerMemberId;
        if (payer != null && paid.containsKey(payer)) {
          paid[payer] = paid[payer]! + expense.baseAmountMinor;
        }
      }
    }

    for (final share in shares) {
      if (owed.containsKey(share.memberId)) {
        owed[share.memberId] = owed[share.memberId]! + share.amountMinor;
      }
    }

    var fundInMinor = 0;
    var fundOutMinor = 0;
    for (final tx in fund) {
      switch (tx.type) {
        case 'CONTRIBUTION':
          fundInMinor += tx.amountMinor;
          if (tx.memberId case final String memberId when fundNet.containsKey(memberId)) {
            fundNet[memberId] = fundNet[memberId]! + tx.amountMinor;
          }
        case 'REFUND':
          fundOutMinor += tx.amountMinor;
          if (tx.memberId case final String memberId when fundNet.containsKey(memberId)) {
            fundNet[memberId] = fundNet[memberId]! - tx.amountMinor;
          }
        case 'ADJUSTMENT_IN':
          fundInMinor += tx.amountMinor;
        case 'ADJUSTMENT_OUT':
          fundOutMinor += tx.amountMinor;
        default:
          throw StateError('Unknown fund transaction type: ${tx.type}');
      }
    }

    for (final payment in settlements) {
      if (settlementNet.containsKey(payment.fromMemberId)) {
        settlementNet[payment.fromMemberId] =
            settlementNet[payment.fromMemberId]! + payment.amountMinor;
      }
      if (settlementNet.containsKey(payment.toMemberId)) {
        settlementNet[payment.toMemberId] =
            settlementNet[payment.toMemberId]! - payment.amountMinor;
      }
    }

    final balances = members
        .map(
          (member) => MemberBalance(
            memberId: member.id,
            paidMinor: paid[member.id]!,
            shareMinor: owed[member.id]!,
            fundNetContributionMinor: fundNet[member.id]!,
            settlementNetMinor: settlementNet[member.id]!,
          ),
        )
        .toList(growable: false);

    final fundBalanceMinor = fundInMinor - fundOutMinor - fundExpenseMinor;
    final suggestedTransfers = _suggestTransfers(balances);

    final status = switch (expenses.isEmpty) {
      true => TripAccountingStatus.notStarted,
      false when fundBalanceMinor == 0 && balances.every((b) => b.netMinor == 0) =>
        TripAccountingStatus.settled,
      false => TripAccountingStatus.pendingSettlement,
    };

    return LedgerSnapshot(
      tripId: tripId,
      currency: trip.baseCurrency,
      totalExpenseMinor: totalExpenseMinor,
      fundBalanceMinor: fundBalanceMinor,
      balances: balances,
      suggestedTransfers: suggestedTransfers,
      status: status,
    );
  }

  List<SuggestedTransfer> _suggestTransfers(List<MemberBalance> balances) {
    final creditors = <_BalanceBucket>[];
    final debtors = <_BalanceBucket>[];
    for (final balance in balances) {
      if (balance.netMinor > 0) {
        creditors.add(_BalanceBucket(balance.memberId, balance.netMinor));
      } else if (balance.netMinor < 0) {
        debtors.add(_BalanceBucket(balance.memberId, -balance.netMinor));
      }
    }

    creditors.sort((a, b) => b.amount.compareTo(a.amount));
    debtors.sort((a, b) => b.amount.compareTo(a.amount));

    final result = <SuggestedTransfer>[];
    var creditorIndex = 0;
    var debtorIndex = 0;
    while (creditorIndex < creditors.length && debtorIndex < debtors.length) {
      final creditor = creditors[creditorIndex];
      final debtor = debtors[debtorIndex];
      final amount = creditor.amount < debtor.amount ? creditor.amount : debtor.amount;
      if (amount > 0) {
        result.add(
          SuggestedTransfer(
            fromMemberId: debtor.memberId,
            toMemberId: creditor.memberId,
            amountMinor: amount,
          ),
        );
        creditor.amount -= amount;
        debtor.amount -= amount;
      }
      if (creditor.amount == 0) creditorIndex++;
      if (debtor.amount == 0) debtorIndex++;
    }
    return result;
  }
}

class _BalanceBucket {
  _BalanceBucket(this.memberId, this.amount);
  final String memberId;
  int amount;
}
