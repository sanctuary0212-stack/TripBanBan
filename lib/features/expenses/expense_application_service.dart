import 'package:decimal/decimal.dart';

import '../../data/local/app_database.dart';
import '../../data/repositories/ledger_repository.dart';
import '../../domain/ledger_service.dart';
import '../../domain/split_service.dart';
import '../fx/fx_rate_service.dart';
import '../../platform/attachment_storage_service.dart';

enum ExpenseSplitMode { equal, customAmount, percentage }

class ExpenseSaveRequest {
  const ExpenseSaveRequest({
    this.expenseId,
    required this.tripId,
    required this.title,
    this.note,
    required this.originalAmountMinor,
    required this.originalCurrency,
    required this.payerType,
    this.payerMemberId,
    required this.categoryKey,
    this.customCategoryId,
    required this.occurredAt,
    required this.selectedMemberIds,
    required this.splitMode,
    this.customAmountMinorByMember = const {},
    this.percentageByMember = const {},
    this.manualRateText,
  });

  final String? expenseId;
  final String tripId;
  final String title;
  final String? note;
  final int originalAmountMinor;
  final String originalCurrency;
  final String payerType;
  final String? payerMemberId;
  final String categoryKey;
  final String? customCategoryId;
  final DateTime occurredAt;
  final List<String> selectedMemberIds;
  final ExpenseSplitMode splitMode;
  final Map<String, int> customAmountMinorByMember;
  final Map<String, String> percentageByMember;
  final String? manualRateText;
}

class PreparedExpense {
  const PreparedExpense({
    required this.baseAmountMinor,
    required this.baseCurrency,
    required this.exchangeRateText,
    required this.exchangeRateDate,
    required this.exchangeRateSource,
    required this.shares,
  });

  final int baseAmountMinor;
  final String baseCurrency;
  final String exchangeRateText;
  final DateTime? exchangeRateDate;
  final String exchangeRateSource;
  final List<ExpenseShareDraft> shares;
}

/// Application boundary for expense creation/editing.
///
/// All money persisted in accounting is converted once to the trip base currency.
/// The conversion quote is frozen on the expense, so later FX updates never rewrite
/// historical balances.
class ExpenseApplicationService {
  const ExpenseApplicationService({
    required this.repository,
    required this.ledger,
    required this.fx,
    required this.split,
    this.attachments,
  });

  final LedgerRepository repository;
  final LedgerService ledger;
  final FxRateService fx;
  final SplitService split;
  final AttachmentStorageService? attachments;


  Future<void> delete(String expenseId) async {
    await attachments?.deleteAttachmentsForExpense(expenseId);
    await repository.deleteExpense(expenseId);
  }

  Future<PreparedExpense> prepare(ExpenseSaveRequest request) async {
    if (request.originalAmountMinor <= 0) {
      throw ArgumentError('Expense amount must be greater than zero.');
    }
    if (request.selectedMemberIds.isEmpty) {
      throw StateError('Select at least one member to share this expense.');
    }

    final trip = await repository.getTrip(request.tripId);
    if (trip == null) throw ArgumentError.value(request.tripId, 'tripId', 'Unknown trip');

    final source = request.originalCurrency.toUpperCase();
    final target = trip.baseCurrency.toUpperCase();

    String rateText = '1';
    DateTime? rateDate;
    String rateSource = 'identity';
    if (source != target) {
      final manual = request.manualRateText?.trim();
      if (manual != null && manual.isNotEmpty) {
        final parsed = Decimal.tryParse(manual);
        if (parsed == null || parsed <= Decimal.zero) {
          throw const FormatException('Manual exchange rate must be greater than zero.');
        }
        rateText = parsed.toString();
        rateDate = DateTime.now();
        rateSource = 'manual-expense';
      } else {
        final quote = await fx.manualOrCachedQuote(from: source, to: target);
        if (quote == null) {
          throw StateError('No exchange rate is available for $source/$target. Enter a manual rate.');
        }
        rateText = quote.rateText;
        rateDate = quote.rateDate;
        rateSource = quote.source;
      }
    }

    final baseAmount = fx.convertMinor(
      sourceAmountMinor: request.originalAmountMinor,
      sourceCurrency: source,
      targetCurrency: target,
      rateText: rateText,
    );
    if (baseAmount <= 0) throw StateError('Converted expense amount must be greater than zero.');

    final shares = _buildShares(request, baseAmount);
    return PreparedExpense(
      baseAmountMinor: baseAmount,
      baseCurrency: target,
      exchangeRateText: rateText,
      exchangeRateDate: rateDate,
      exchangeRateSource: rateSource,
      shares: shares,
    );
  }

  Future<String> save(ExpenseSaveRequest request) async {
    final prepared = await prepare(request);

    if (request.payerType == 'FUND') {
      final snapshot = await ledger.calculate(request.tripId);
      var available = snapshot.fundBalanceMinor;
      if (request.expenseId != null) {
        final existing = await repository.getExpense(request.expenseId!);
        if (existing != null && existing.payerType == 'FUND') {
          // The current snapshot already subtracts the old version. Add it back
          // while checking whether the edited replacement can be afforded.
          available += existing.baseAmountMinor;
        }
      }
      if (prepared.baseAmountMinor > available) {
        throw StateError('Public fund balance is insufficient.');
      }
    }

    return repository.saveExpense(
      ExpenseDraft(
        id: request.expenseId,
        tripId: request.tripId,
        title: request.title,
        note: request.note,
        originalAmountMinor: request.originalAmountMinor,
        originalCurrency: request.originalCurrency,
        baseAmountMinor: prepared.baseAmountMinor,
        baseCurrency: prepared.baseCurrency,
        exchangeRateText: prepared.exchangeRateText,
        exchangeRateDate: prepared.exchangeRateDate,
        exchangeRateSource: prepared.exchangeRateSource,
        payerType: request.payerType,
        payerMemberId: request.payerMemberId,
        categoryKey: request.categoryKey,
        customCategoryId: request.customCategoryId,
        occurredAt: request.occurredAt,
        shares: prepared.shares,
      ),
    );
  }

  List<ExpenseShareDraft> _buildShares(ExpenseSaveRequest request, int totalMinor) {
    final ids = request.selectedMemberIds;
    switch (request.splitMode) {
      case ExpenseSplitMode.equal:
        final amounts = split.equalSplit(totalMinor, ids.length);
        return [
          for (var i = 0; i < ids.length; i++)
            ExpenseShareDraft(
              memberId: ids[i],
              amountMinor: amounts[i],
              mode: 'EQUAL',
            ),
        ];
      case ExpenseSplitMode.customAmount:
        final amounts = [
          for (final id in ids) request.customAmountMinorByMember[id],
        ];
        if (amounts.any((value) => value == null || value! < 0)) {
          throw StateError('Every selected member needs a custom amount.');
        }
        final concrete = amounts.cast<int>();
        if (!split.customAmountsValid(totalMinor, concrete)) {
          final allocated = concrete.fold<int>(0, (a, b) => a + b);
          final delta = totalMinor - allocated;
          throw StateError(
            delta > 0
                ? 'Custom split is short by $delta minor units.'
                : 'Custom split exceeds the expense by ${-delta} minor units.',
          );
        }
        return [
          for (var i = 0; i < ids.length; i++)
            ExpenseShareDraft(
              memberId: ids[i],
              amountMinor: concrete[i],
              mode: 'CUSTOM',
            ),
        ];
      case ExpenseSplitMode.percentage:
        final raw = [for (final id in ids) request.percentageByMember[id]?.trim() ?? ''];
        if (!split.percentagesValid(raw)) {
          throw StateError('Percentage split must total exactly 100%.');
        }
        final percentages = raw.map(Decimal.parse).toList(growable: false);
        final amounts = _allocatePercentages(totalMinor, percentages);
        return [
          for (var i = 0; i < ids.length; i++)
            ExpenseShareDraft(
              memberId: ids[i],
              amountMinor: amounts[i],
              mode: 'PERCENTAGE',
              ratioText: raw[i],
            ),
        ];
    }
  }

  /// Converts exact percentage weights into integer minor units without losing
  /// or creating money. Remainders go to the rows with the largest fractional
  /// parts, providing deterministic totals.
  List<int> _allocatePercentages(int totalMinor, List<Decimal> percentages) {
    final hundred = Decimal.fromInt(100);
    final exact = percentages
        .map((p) => (Decimal.fromInt(totalMinor) * p / hundred).toDecimal(scaleOnInfinitePrecision: 12))
        .toList(growable: false);
    final floorValues = exact.map((value) => value.floor().toBigInt().toInt()).toList(growable: false);
    var missing = totalMinor - floorValues.fold<int>(0, (a, b) => a + b);
    final order = List<int>.generate(exact.length, (i) => i)
      ..sort((a, b) {
        final aFraction = exact[a] - Decimal.fromInt(floorValues[a]);
        final bFraction = exact[b] - Decimal.fromInt(floorValues[b]);
        final compare = bFraction.compareTo(aFraction);
        return compare != 0 ? compare : a.compareTo(b);
      });
    final result = List<int>.from(floorValues);
    var index = 0;
    while (missing > 0 && order.isNotEmpty) {
      result[order[index % order.length]]++;
      index++;
      missing--;
    }
    return result;
  }
}
