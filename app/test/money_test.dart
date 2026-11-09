import 'package:flutter_test/flutter_test.dart';
import 'package:food_app/core/utils/money.dart';

void main() {
  test('formats whole dinars with thin spaces and unit per language', () {
    expect(formatDzd(200, 'fr'), '200 DA');
    expect(formatDzd(1250, 'fr'), '1 250 DA');
    expect(formatDzd(1250000, 'en'), '1 250 000 DA');
    expect(formatDzd(1250, 'ar'), '1 250 دج');
    expect(formatDzd(0, 'fr'), '0 DA');
    expect(formatDzd(-300, 'fr'), '-300 DA');
  });
}
