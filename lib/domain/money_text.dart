import 'package:intl/intl.dart';

import 'currency_catalog.dart';

class MoneyText {
  const MoneyText._();

  static String formatMinor(
    int minor,
    String currency, {
    String locale = 'en',
    bool showCode = true,
  }) {
    final info = CurrencyCatalog.find(currency);
    final digits = info?.decimalPlaces ?? 2;
    final divisor = _pow10(digits);
    final value = minor / divisor;
    final format = NumberFormat.currency(
      locale: locale,
      name: showCode ? currency.toUpperCase() : null,
      symbol: showCode ? '${currency.toUpperCase()} ' : (info?.symbol ?? ''),
      decimalDigits: digits,
    );
    return format.format(value);
  }

  static int _pow10(int n) {
    var out = 1;
    for (var i = 0; i < n; i++) out *= 10;
    return out;
  }
}
