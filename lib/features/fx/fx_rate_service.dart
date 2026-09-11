import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../../data/local/app_database.dart';
import '../../domain/currency_catalog.dart';

class FxQuote {
  const FxQuote({
    required this.from,
    required this.to,
    required this.rateText,
    required this.rateDate,
    required this.source,
  });

  final String from;
  final String to;
  final String rateText;
  final DateTime rateDate;
  final String source;
}

class FxRateService {
  FxRateService(
    this.db, {
    http.Client? httpClient,
    String? staticRatesUrl,
  })  : _http = httpClient ?? http.Client(),
        _staticRatesUrl = staticRatesUrl ??
            const String.fromEnvironment('FX_STATIC_URL', defaultValue: '');

  final AppDatabase db;
  final http.Client _http;
  final String _staticRatesUrl;

  Future<void> ensureBootstrapRates() async {
    final countExp = db.fxRates.baseCurrency.count();
    final count = await (db.selectOnly(db.fxRates)..addColumns([countExp]))
        .map((row) => row.read(countExp) ?? 0)
        .getSingle();
    if (count > 0) return;

    final raw = await rootBundle.loadString('assets/fx/fallback_usd_rates.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    await _storeUsdSnapshot(json, sourceOverride: 'bootstrap');
  }

  /// Checks at most once per local calendar day unless [force] is true.
  /// A static JSON endpoint is optional; if omitted or unreachable, cached rates remain usable.
  Future<bool> updateDaily({bool force = false}) async {
    await ensureBootstrapRates();
    if (_staticRatesUrl.isEmpty) return false;

    final today = _day(DateTime.now());
    if (!force) {
      final last = await _latestFetchTime();
      if (last != null && _day(last) == today) return false;
    }

    try {
      final response = await _http.get(Uri.parse(_staticRatesUrl)).timeout(const Duration(seconds: 10));
      if (response.statusCode < 200 || response.statusCode >= 300) return false;
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      await _storeUsdSnapshot(json, sourceOverride: 'static-json');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<FxQuote?> quote({required String from, required String to}) async {
    final source = from.toUpperCase();
    final target = to.toUpperCase();
    if (source == target) {
      return FxQuote(
        from: source,
        to: target,
        rateText: '1',
        rateDate: _day(DateTime.now()),
        source: 'identity',
      );
    }

    await ensureBootstrapRates();
    final sourceUsd = await _latestUsdRate(source);
    final targetUsd = await _latestUsdRate(target);
    if (sourceUsd == null || targetUsd == null) return null;

    final sourceRate = Decimal.parse(sourceUsd.rateText);
    final targetRate = Decimal.parse(targetUsd.rateText);
    final cross = (targetRate / sourceRate).toDecimal(scaleOnInfinitePrecision: 12);
    final date = sourceUsd.rateDate.isBefore(targetUsd.rateDate)
        ? sourceUsd.rateDate
        : targetUsd.rateDate;
    return FxQuote(
      from: source,
      to: target,
      rateText: _trimDecimal(cross.toString()),
      rateDate: date,
      source: '${sourceUsd.source}+${targetUsd.source}',
    );
  }

  int convertMinor({
    required int sourceAmountMinor,
    required String sourceCurrency,
    required String targetCurrency,
    required String rateText,
  }) {
    final sourceDecimals = CurrencyCatalog.decimalPlacesFor(sourceCurrency);
    final targetDecimals = CurrencyCatalog.decimalPlacesFor(targetCurrency);
    final major = sourceAmountMinor.toDecimal().shift(-sourceDecimals);
    final targetMajor = major * Decimal.parse(rateText);
    final targetMinor = targetMajor.shift(targetDecimals).round();
    return targetMinor.toBigInt().toInt();
  }

  Future<void> storeManualQuote({
    required String from,
    required String to,
    required String rateText,
    DateTime? date,
  }) async {
    // Store as direct base->quote row. quote() prioritizes direct manual rows first.
    final now = DateTime.now();
    await db.into(db.fxRates).insertOnConflictUpdate(
          FxRatesCompanion.insert(
            baseCurrency: from.toUpperCase(),
            quoteCurrency: to.toUpperCase(),
            rateText: rateText,
            rateDate: _day(date ?? now),
            source: 'manual',
            fetchedAt: now,
          ),
        );
  }

  Future<FxQuote?> manualOrCachedQuote({required String from, required String to}) async {
    final source = from.toUpperCase();
    final target = to.toUpperCase();
    final direct = await (db.select(db.fxRates)
          ..where((r) => r.baseCurrency.equals(source) & r.quoteCurrency.equals(target))
          ..orderBy([(r) => OrderingTerm.desc(r.rateDate), (r) => OrderingTerm.desc(r.fetchedAt)])
          ..limit(1))
        .getSingleOrNull();
    if (direct != null && direct.source == 'manual') {
      return FxQuote(
        from: source,
        to: target,
        rateText: direct.rateText,
        rateDate: direct.rateDate,
        source: direct.source,
      );
    }
    return quote(from: source, to: target);
  }

  Future<void> _storeUsdSnapshot(
    Map<String, dynamic> json, {
    required String sourceOverride,
  }) async {
    final base = (json['base'] as String? ?? 'USD').toUpperCase();
    if (base != 'USD') {
      throw const FormatException('TripBanBan static FX snapshot must use USD as base.');
    }
    final date = DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now();
    final rawRates = (json['rates'] as Map).cast<String, dynamic>();
    final now = DateTime.now();
    final rates = <String, dynamic>{'USD': 1, ...rawRates};
    await db.batch((batch) {
      for (final entry in rates.entries) {
        final number = entry.value;
        if (number is! num || number <= 0) continue;
        batch.insert(
          db.fxRates,
          FxRatesCompanion.insert(
            baseCurrency: 'USD',
            quoteCurrency: entry.key.toUpperCase(),
            rateText: _trimDecimal(number.toString()),
            rateDate: _day(date),
            source: sourceOverride,
            fetchedAt: now,
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<FxRateRow?> _latestUsdRate(String quoteCurrency) =>
      (db.select(db.fxRates)
            ..where((r) => r.baseCurrency.equals('USD') & r.quoteCurrency.equals(quoteCurrency))
            ..orderBy([(r) => OrderingTerm.desc(r.rateDate), (r) => OrderingTerm.desc(r.fetchedAt)])
            ..limit(1))
          .getSingleOrNull();

  Future<DateTime?> _latestFetchTime() async {
    final row = await (db.select(db.fxRates)
          ..orderBy([(r) => OrderingTerm.desc(r.fetchedAt)])
          ..limit(1))
        .getSingleOrNull();
    return row?.fetchedAt;
  }

  static DateTime _day(DateTime value) => DateTime(value.year, value.month, value.day);

  static String _trimDecimal(String value) {
    if (!value.contains('.')) return value;
    return value.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }
}
