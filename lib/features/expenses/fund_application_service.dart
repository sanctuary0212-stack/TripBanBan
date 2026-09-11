import '../../data/repositories/ledger_repository.dart';
import '../../domain/ledger_service.dart';

class FundApplicationService {
  const FundApplicationService({required this.repository, required this.ledger});

  final LedgerRepository repository;
  final LedgerService ledger;

  Future<String> contribute({
    required String tripId,
    required String memberId,
    required int amountMinor,
    String? note,
  }) =>
      repository.addFundTransaction(
        tripId: tripId,
        memberId: memberId,
        type: 'CONTRIBUTION',
        amountMinor: amountMinor,
        note: note,
      );

  Future<String> refund({
    required String tripId,
    required String memberId,
    required int amountMinor,
    String? note,
  }) async {
    final snapshot = await ledger.calculate(tripId);
    if (amountMinor > snapshot.fundBalanceMinor) {
      throw StateError('Refund exceeds the current shared-fund balance.');
    }
    return repository.addFundTransaction(
      tripId: tripId,
      memberId: memberId,
      type: 'REFUND',
      amountMinor: amountMinor,
      note: note,
    );
  }
}
