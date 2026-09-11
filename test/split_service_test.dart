import 'package:flutter_test/flutter_test.dart';
import 'package:tripbanban_app/domain/split_service.dart';

void main() {
  const split = SplitService();

  test('equal split preserves every minor unit', () {
    expect(split.equalSplit(1000, 3), [334, 333, 333]);
    expect(split.equalSplit(12000, 4), [3000, 3000, 3000, 3000]);
  });

  test('custom amounts must total exactly', () {
    expect(split.customAmountsValid(1000, [600, 400]), isTrue);
    expect(split.customAmountsValid(1000, [600, 399]), isFalse);
    expect(split.customAmountsValid(1000, [600, 401]), isFalse);
  });

  test('percentages must total exactly 100', () {
    expect(split.percentagesValid(['70', '30']), isTrue);
    expect(split.percentagesValid(['33.33', '33.33', '33.34']), isTrue);
    expect(split.percentagesValid(['60', '30']), isFalse);
    expect(split.percentagesValid(['60', '50']), isFalse);
  });
}
