import '../../data/repositories/ledger_repository.dart';
import '../../domain/ledger_service.dart';
import 'report_models.dart';

class ReportFactory {
  const ReportFactory({required this.repository, required this.ledger});

  final LedgerRepository repository;
  final LedgerService ledger;

  Future<SettlementShareReport> settlementReport(String tripId) async {
    final trip = await repository.getTrip(tripId);
    if (trip == null) throw ArgumentError.value(tripId, 'tripId', 'Unknown trip');
    final members = await repository.getMembers(tripId);
    final snapshot = await ledger.calculate(tripId);
    final balancesById = {for (final item in snapshot.balances) item.memberId: item};
    return SettlementShareReport(
      tripName: trip.name,
      currency: snapshot.currency,
      totalExpenseMinor: snapshot.totalExpenseMinor,
      fundBalanceMinor: snapshot.fundBalanceMinor,
      members: [
        for (final member in members)
          if (balancesById[member.id] case final balance?)
            ShareReportMember(id: member.id, name: member.displayName, balance: balance),
      ],
      transfers: snapshot.suggestedTransfers,
      generatedAt: DateTime.now(),
    );
  }
}
