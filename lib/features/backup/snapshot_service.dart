import 'package:drift/drift.dart';

import '../../data/local/app_database.dart';

class SnapshotService {
  const SnapshotService(this.db);

  final AppDatabase db;

  Future<Map<String, dynamic>> exportJson() async {
    return {
      'schemaVersion': db.schemaVersion,
      'trips': (await db.select(db.trips).get()).map(_trip).toList(),
      'members': (await db.select(db.members).get()).map(_member).toList(),
      'expenses': (await db.select(db.expenses).get()).map(_expense).toList(),
      'expenseShares': (await db.select(db.expenseShares).get()).map(_share).toList(),
      'fundTransactions':
          (await db.select(db.fundTransactions).get()).map(_fund).toList(),
      'settlementPayments':
          (await db.select(db.settlementPayments).get()).map(_settlement).toList(),
      'attachments': (await db.select(db.attachments).get()).map(_attachment).toList(),
      'customCategories':
          (await db.select(db.customCategories).get()).map(_category).toList(),
      'customCurrencies':
          (await db.select(db.customCurrencies).get()).map(_currency).toList(),
      'fxRates': (await db.select(db.fxRates).get()).map(_fx).toList(),
      'settings': (await db.select(db.appSettings).get()).map(_setting).toList(),
    };
  }

  Future<void> restoreJson(Map<String, dynamic> snapshot) async {
    final version = snapshot['schemaVersion'];
    if (version is! int || version < 1 || version > db.schemaVersion) {
      throw FormatException('Unsupported snapshot schemaVersion: $version');
    }

    List<Map<String, dynamic>> rows(String key) =>
        ((snapshot[key] as List?) ?? const []).cast<Map<String, dynamic>>();

    await db.transaction(() async {
      // Delete in FK-safe order.
      await db.delete(db.attachments).go();
      await db.delete(db.expenseShares).go();
      await db.delete(db.settlementPayments).go();
      await db.delete(db.fundTransactions).go();
      await db.delete(db.expenses).go();
      await db.delete(db.customCategories).go();
      await db.delete(db.customCurrencies).go();
      await db.delete(db.members).go();
      await db.delete(db.trips).go();
      await db.delete(db.fxRates).go();
      await db.delete(db.appSettings).go();

      for (final j in rows('trips')) {
        await db.into(db.trips).insert(TripsCompanion.insert(
              id: j['id'] as String,
              name: j['name'] as String,
              destination: Value(j['destination'] as String?),
              countryCode: Value(j['countryCode'] as String?),
              startDate: Value(_dt(j['startDate'])),
              endDate: Value(_dt(j['endDate'])),
              baseCurrency: j['baseCurrency'] as String,
              createdAt: DateTime.parse(j['createdAt'] as String),
              updatedAt: DateTime.parse(j['updatedAt'] as String),
            ));
      }
      for (final j in rows('members')) {
        await db.into(db.members).insert(MembersCompanion.insert(
              id: j['id'] as String,
              tripId: j['tripId'] as String,
              displayName: j['displayName'] as String,
              sortOrder: Value(j['sortOrder'] as int? ?? 0),
              createdAt: DateTime.parse(j['createdAt'] as String),
              updatedAt: DateTime.parse(j['updatedAt'] as String),
            ));
      }
      for (final j in rows('expenses')) {
        await db.into(db.expenses).insert(ExpensesCompanion.insert(
              id: j['id'] as String,
              tripId: j['tripId'] as String,
              title: Value(j['title'] as String? ?? ''),
              note: Value(j['note'] as String?),
              originalAmountMinor: j['originalAmountMinor'] as int,
              originalCurrency: j['originalCurrency'] as String,
              baseAmountMinor: j['baseAmountMinor'] as int,
              baseCurrency: j['baseCurrency'] as String,
              exchangeRateText: Value(j['exchangeRateText'] as String? ?? '1'),
              exchangeRateDate: Value(_dt(j['exchangeRateDate'])),
              exchangeRateSource: Value(j['exchangeRateSource'] as String?),
              payerType: j['payerType'] as String,
              payerMemberId: Value(j['payerMemberId'] as String?),
              categoryKey: j['categoryKey'] as String,
              customCategoryId: Value(j['customCategoryId'] as String?),
              occurredAt: DateTime.parse(j['occurredAt'] as String),
              createdAt: DateTime.parse(j['createdAt'] as String),
              updatedAt: DateTime.parse(j['updatedAt'] as String),
            ));
      }
      for (final j in rows('expenseShares')) {
        await db.into(db.expenseShares).insert(ExpenseSharesCompanion.insert(
              expenseId: j['expenseId'] as String,
              memberId: j['memberId'] as String,
              amountMinor: j['amountMinor'] as int,
              mode: Value(j['mode'] as String? ?? 'EQUAL'),
              ratioText: Value(j['ratioText'] as String?),
            ));
      }
      for (final j in rows('fundTransactions')) {
        await db.into(db.fundTransactions).insert(FundTransactionsCompanion.insert(
              id: j['id'] as String,
              tripId: j['tripId'] as String,
              memberId: Value(j['memberId'] as String?),
              type: j['type'] as String,
              amountMinor: j['amountMinor'] as int,
              note: Value(j['note'] as String?),
              occurredAt: DateTime.parse(j['occurredAt'] as String),
              createdAt: DateTime.parse(j['createdAt'] as String),
            ));
      }
      for (final j in rows('settlementPayments')) {
        await db.into(db.settlementPayments).insert(SettlementPaymentsCompanion.insert(
              id: j['id'] as String,
              tripId: j['tripId'] as String,
              fromMemberId: j['fromMemberId'] as String,
              toMemberId: j['toMemberId'] as String,
              amountMinor: j['amountMinor'] as int,
              currency: j['currency'] as String,
              occurredAt: DateTime.parse(j['occurredAt'] as String),
              createdAt: DateTime.parse(j['createdAt'] as String),
            ));
      }
      for (final j in rows('customCategories')) {
        await db.into(db.customCategories).insert(CustomCategoriesCompanion.insert(
              id: j['id'] as String,
              tripId: j['tripId'] as String,
              name: j['name'] as String,
              iconKey: j['iconKey'] as String,
              createdAt: DateTime.parse(j['createdAt'] as String),
              updatedAt: DateTime.parse(j['updatedAt'] as String),
            ));
      }
      for (final j in rows('customCurrencies')) {
        await db.into(db.customCurrencies).insert(CustomCurrenciesCompanion.insert(
              id: j['id'] as String,
              tripId: Value(j['tripId'] as String?),
              code: j['code'] as String,
              name: j['name'] as String,
              symbol: j['symbol'] as String,
              decimalPlaces: Value(j['decimalPlaces'] as int? ?? 2),
              manualRateToTripBase: Value(j['manualRateToTripBase'] as String?),
              createdAt: DateTime.parse(j['createdAt'] as String),
              updatedAt: DateTime.parse(j['updatedAt'] as String),
            ));
      }
      for (final j in rows('fxRates')) {
        await db.into(db.fxRates).insert(FxRatesCompanion.insert(
              baseCurrency: j['baseCurrency'] as String,
              quoteCurrency: j['quoteCurrency'] as String,
              rateText: j['rateText'] as String,
              rateDate: DateTime.parse(j['rateDate'] as String),
              source: j['source'] as String,
              fetchedAt: DateTime.parse(j['fetchedAt'] as String),
            ));
      }
      for (final j in rows('settings')) {
        await db.into(db.appSettings).insert(AppSettingsCompanion.insert(
              key: j['key'] as String,
              value: j['value'] as String,
              updatedAt: DateTime.parse(j['updatedAt'] as String),
            ));
      }
      for (final j in rows('attachments')) {
        await db.into(db.attachments).insert(AttachmentsCompanion.insert(
              id: j['id'] as String,
              expenseId: j['expenseId'] as String,
              type: j['type'] as String,
              relativePath: j['relativePath'] as String,
              mimeType: Value(j['mimeType'] as String?),
              byteLength: Value(j['byteLength'] as int?),
              createdAt: DateTime.parse(j['createdAt'] as String),
            ));
      }
    });
  }

  static DateTime? _dt(Object? value) => value == null ? null : DateTime.parse(value as String);

  static Map<String, dynamic> _trip(TripRow r) => {
        'id': r.id,
        'name': r.name,
        'destination': r.destination,
        'countryCode': r.countryCode,
        'startDate': r.startDate?.toIso8601String(),
        'endDate': r.endDate?.toIso8601String(),
        'baseCurrency': r.baseCurrency,
        'createdAt': r.createdAt.toIso8601String(),
        'updatedAt': r.updatedAt.toIso8601String(),
      };
  static Map<String, dynamic> _member(MemberRow r) => {
        'id': r.id,
        'tripId': r.tripId,
        'displayName': r.displayName,
        'sortOrder': r.sortOrder,
        'createdAt': r.createdAt.toIso8601String(),
        'updatedAt': r.updatedAt.toIso8601String(),
      };
  static Map<String, dynamic> _expense(ExpenseRow r) => {
        'id': r.id,
        'tripId': r.tripId,
        'title': r.title,
        'note': r.note,
        'originalAmountMinor': r.originalAmountMinor,
        'originalCurrency': r.originalCurrency,
        'baseAmountMinor': r.baseAmountMinor,
        'baseCurrency': r.baseCurrency,
        'exchangeRateText': r.exchangeRateText,
        'exchangeRateDate': r.exchangeRateDate?.toIso8601String(),
        'exchangeRateSource': r.exchangeRateSource,
        'payerType': r.payerType,
        'payerMemberId': r.payerMemberId,
        'categoryKey': r.categoryKey,
        'customCategoryId': r.customCategoryId,
        'occurredAt': r.occurredAt.toIso8601String(),
        'createdAt': r.createdAt.toIso8601String(),
        'updatedAt': r.updatedAt.toIso8601String(),
      };
  static Map<String, dynamic> _share(ExpenseShareRow r) => {
        'expenseId': r.expenseId,
        'memberId': r.memberId,
        'amountMinor': r.amountMinor,
        'mode': r.mode,
        'ratioText': r.ratioText,
      };
  static Map<String, dynamic> _fund(FundTransactionRow r) => {
        'id': r.id,
        'tripId': r.tripId,
        'memberId': r.memberId,
        'type': r.type,
        'amountMinor': r.amountMinor,
        'note': r.note,
        'occurredAt': r.occurredAt.toIso8601String(),
        'createdAt': r.createdAt.toIso8601String(),
      };
  static Map<String, dynamic> _settlement(SettlementPaymentRow r) => {
        'id': r.id,
        'tripId': r.tripId,
        'fromMemberId': r.fromMemberId,
        'toMemberId': r.toMemberId,
        'amountMinor': r.amountMinor,
        'currency': r.currency,
        'occurredAt': r.occurredAt.toIso8601String(),
        'createdAt': r.createdAt.toIso8601String(),
      };
  static Map<String, dynamic> _attachment(AttachmentRow r) => {
        'id': r.id,
        'expenseId': r.expenseId,
        'type': r.type,
        'relativePath': r.relativePath,
        'mimeType': r.mimeType,
        'byteLength': r.byteLength,
        'createdAt': r.createdAt.toIso8601String(),
      };
  static Map<String, dynamic> _category(CustomCategoryRow r) => {
        'id': r.id,
        'tripId': r.tripId,
        'name': r.name,
        'iconKey': r.iconKey,
        'createdAt': r.createdAt.toIso8601String(),
        'updatedAt': r.updatedAt.toIso8601String(),
      };
  static Map<String, dynamic> _currency(CustomCurrencyRow r) => {
        'id': r.id,
        'tripId': r.tripId,
        'code': r.code,
        'name': r.name,
        'symbol': r.symbol,
        'decimalPlaces': r.decimalPlaces,
        'manualRateToTripBase': r.manualRateToTripBase,
        'createdAt': r.createdAt.toIso8601String(),
        'updatedAt': r.updatedAt.toIso8601String(),
      };
  static Map<String, dynamic> _fx(FxRateRow r) => {
        'baseCurrency': r.baseCurrency,
        'quoteCurrency': r.quoteCurrency,
        'rateText': r.rateText,
        'rateDate': r.rateDate.toIso8601String(),
        'source': r.source,
        'fetchedAt': r.fetchedAt.toIso8601String(),
      };
  static Map<String, dynamic> _setting(AppSettingRow r) => {
        'key': r.key,
        'value': r.value,
        'updatedAt': r.updatedAt.toIso8601String(),
      };
}
