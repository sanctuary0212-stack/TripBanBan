import 'package:flutter_test/flutter_test.dart';
import 'package:tripbanban_app/domain/currency_catalog.dart';

void main() {
  test('world currency catalog includes key travel currencies', () {
    expect(CurrencyCatalog.all.length, greaterThan(160));
    for (final code in ['TWD', 'JPY', 'CNY', 'USD', 'KRW', 'EUR', 'THB', 'SGD', 'HKD']) {
      expect(CurrencyCatalog.find(code), isNotNull, reason: code);
    }
  });
}
