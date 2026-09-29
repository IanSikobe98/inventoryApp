import 'package:flutter_test/flutter_test.dart';
import 'package:stockroom_app/utils/format.dart';

void main() {
  test('formatMoney groups thousands and rounds', () {
    expect(formatMoney(3200), 'KSh 3,200');
    expect(formatMoney(0), 'KSh 0');
    expect(formatMoney(null), 'KSh 0');
    expect(formatMoney(1234567.6), 'KSh 1,234,568');
  });

  test('compactMoney shortens big numbers for chart labels', () {
    expect(compactMoney(850), '850');
    expect(compactMoney(12500), '12.5k');
    expect(compactMoney(2400000), '2.4M');
  });

  test('plainNumber drops a trailing .0 only', () {
    expect(plainNumber(3200.0), '3200');
    expect(plainNumber(3200.5), '3200.50');
  });

  test('isoDate matches what the API expects', () {
    expect(isoDate(DateTime(2026, 9, 5)), '2026-09-05');
    expect(isoDate(DateTime(2026, 12, 31)), '2026-12-31');
  });
}
