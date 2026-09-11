import 'dart:io';

import '../../data/local/app_database.dart';
import '../../data/repositories/ledger_repository.dart';
import '../../platform/local_paths.dart';

class CsvExportService {
  CsvExportService(this.repository, {LocalPaths? paths}) : _paths = paths ?? const LocalPaths();

  final LedgerRepository repository;
  final LocalPaths _paths;

  Future<List<File>> exportTrip(String tripId) async {
    final trip = await repository.getTrip(tripId);
    if (trip == null) throw ArgumentError.value(tripId, 'tripId', 'Unknown trip');
    final members = await repository.getMembers(tripId);
    final expenses = await repository.getExpenses(tripId);
    final shares = await repository.getSharesForTrip(tripId);
    final memberNames = {for (final member in members) member.id: member.displayName};

    final dir = await _paths.tempExports();
    final base = _safeFileName(trip.name);
    final expenseFile = File('${dir.path}/${base}_expenses.csv');
    final shareFile = File('${dir.path}/${base}_expense_shares.csv');

    final expenseRows = <List<Object?>>[
      [
        'id', 'date', 'title', 'category', 'original_amount_minor', 'original_currency',
        'exchange_rate', 'base_amount_minor', 'base_currency', 'payer', 'note'
      ],
    ];
    for (final expense in expenses) {
      expenseRows.add([
        expense.id,
        expense.occurredAt.toIso8601String(),
        expense.title,
        expense.categoryKey,
        expense.originalAmountMinor,
        expense.originalCurrency,
        expense.exchangeRateText,
        expense.baseAmountMinor,
        expense.baseCurrency,
        expense.payerType == 'FUND' ? 'FUND' : memberNames[expense.payerMemberId] ?? expense.payerMemberId,
        expense.note,
      ]);
    }

    final shareRows = <List<Object?>>[
      ['expense_id', 'member_id', 'member_name', 'amount_minor', 'mode', 'ratio'],
      for (final share in shares)
        [share.expenseId, share.memberId, memberNames[share.memberId], share.amountMinor, share.mode, share.ratioText],
    ];

    await expenseFile.writeAsString(_csv(expenseRows), flush: true);
    await shareFile.writeAsString(_csv(shareRows), flush: true);
    return [expenseFile, shareFile];
  }

  static String _csv(List<List<Object?>> rows) =>
      rows.map((row) => row.map((cell) => _escape(cell?.toString() ?? '')).join(',')).join('\r\n');

  static String _escape(String value) => '"${value.replaceAll('"', '""')}"';

  static String _safeFileName(String value) => value.replaceAll(RegExp(r'[^\w\-\u4e00-\u9fff]+'), '_');
}
