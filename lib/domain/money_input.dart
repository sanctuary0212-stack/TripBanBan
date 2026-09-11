import 'package:decimal/decimal.dart';

import 'currency_catalog.dart';

class MoneyInput {
  const MoneyInput._();

  static int? parseMajorToMinor(String raw, String currency) {
    final value = Decimal.tryParse(raw.trim().replaceAll(',', ''));
    if (value == null || value < Decimal.zero) return null;
    final decimals = CurrencyCatalog.decimalPlacesFor(currency);
    return value.shift(decimals).round().toBigInt().toInt();
  }

  static String minorToMajorText(int minor, String currency) {
    final decimals = CurrencyCatalog.decimalPlacesFor(currency);
    if (decimals == 0) return minor.toString();
    final negative = minor < 0;
    final raw = minor.abs().toString().padLeft(decimals + 1, '0');
    final cut = raw.length - decimals;
    final fraction = raw.substring(cut).replaceFirst(RegExp(r'0+$'), '');
    final whole = raw.substring(0, cut);
    final value = fraction.isEmpty ? whole : '$whole.$fraction';
    return negative ? '-$value' : value;
  }
}
