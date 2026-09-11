import '../../data/repositories/ledger_repository.dart';
import '../../platform/attachment_storage_service.dart';

class TripApplicationService {
  const TripApplicationService({required this.repository, required this.attachments});

  final LedgerRepository repository;
  final AttachmentStorageService attachments;

  Future<void> deleteTripCompletely(String tripId) async {
    final expenses = await repository.getExpenses(tripId);
    for (final expense in expenses) {
      await attachments.deleteAttachmentsForExpense(expense.id);
    }
    await repository.deleteTrip(tripId);
  }
}
