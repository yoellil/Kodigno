import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/data/stats.dart';

void main() {
  final now = DateTime(2026, 10, 9, 15);

  test('no attempts = 0', () => expect(computeStreak([], now), 0));

  test('today and yesterday = 2', () {
    expect(computeStreak([DateTime(2026, 10, 9, 8), DateTime(2026, 10, 8, 22)], now), 2);
  });

  test('streak survives if today has no attempt yet', () {
    expect(computeStreak([DateTime(2026, 10, 8), DateTime(2026, 10, 7)], now), 2);
  });

  test('a gap resets the streak', () {
    expect(computeStreak([DateTime(2026, 10, 9), DateTime(2026, 10, 7)], now), 1);
  });

  test('several attempts on one day count once', () {
    expect(computeStreak([DateTime(2026, 10, 9, 1), DateTime(2026, 10, 9, 2)], now), 1);
  });

  test('older than yesterday only = 0', () {
    expect(computeStreak([DateTime(2026, 10, 6)], now), 0);
  });

  test('works across a month boundary', () {
    final n = DateTime(2026, 11, 1, 9);
    expect(computeStreak([DateTime(2026, 11, 1), DateTime(2026, 10, 31)], n), 2);
  });
}
