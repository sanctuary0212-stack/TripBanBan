class SplitService {
  const SplitService();

  /// Splits [totalMinor] without losing the remainder.
  /// Example: 1000 / 3 => 334, 333, 333.
  List<int> equalSplit(int totalMinor, int count) {
    if (count <= 0) throw ArgumentError.value(count, 'count', 'Must be > 0');
    final base = totalMinor ~/ count;
    var remainder = totalMinor.remainder(count);
    return List<int>.generate(count, (index) {
      final add = remainder > 0 ? 1 : 0;
      if (remainder > 0) remainder--;
      return base + add;
    });
  }

  bool customAmountsValid(int totalMinor, Iterable<int> parts) =>
      parts.fold<int>(0, (sum, value) => sum + value) == totalMinor;

  bool percentagesValid(Iterable<String> percentageTexts) {
    const scale = 1000000;
    var total = 0;
    for (final raw in percentageTexts) {
      final value = double.tryParse(raw);
      if (value == null || value < 0) return false;
      total += (value * scale).round();
    }
    return total == 100 * scale;
  }
}
