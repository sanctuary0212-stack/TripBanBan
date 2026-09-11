class MemberBalance {
  const MemberBalance({
    required this.memberId,
    required this.paidMinor,
    required this.shareMinor,
    required this.fundNetContributionMinor,
    required this.settlementNetMinor,
  });

  final String memberId;
  final int paidMinor;
  final int shareMinor;
  final int fundNetContributionMinor;
  final int settlementNetMinor;

  /// Positive = should receive. Negative = should pay.
  int get netMinor =>
      paidMinor + fundNetContributionMinor + settlementNetMinor - shareMinor;
}

class SuggestedTransfer {
  const SuggestedTransfer({
    required this.fromMemberId,
    required this.toMemberId,
    required this.amountMinor,
  });

  final String fromMemberId;
  final String toMemberId;
  final int amountMinor;
}

enum TripAccountingStatus { notStarted, pendingSettlement, settled }

class LedgerSnapshot {
  const LedgerSnapshot({
    required this.tripId,
    required this.currency,
    required this.totalExpenseMinor,
    required this.fundBalanceMinor,
    required this.balances,
    required this.suggestedTransfers,
    required this.status,
  });

  final String tripId;
  final String currency;
  final int totalExpenseMinor;
  final int fundBalanceMinor;
  final List<MemberBalance> balances;
  final List<SuggestedTransfer> suggestedTransfers;
  final TripAccountingStatus status;
}
