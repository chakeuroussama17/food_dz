import 'package:flutter_test/flutter_test.dart';
import 'package:food_app/core/utils/validators.dart';

void main() {
  group('normalizeDzPhone', () {
    test('accepts local mobile numbers', () {
      expect(normalizeDzPhone('0550123456'), '0550123456');
      expect(normalizeDzPhone('0661 12 34 56'), '0661123456');
      expect(normalizeDzPhone('07.70.12.34.56'), '0770123456');
    });
    test('accepts international prefixes', () {
      expect(normalizeDzPhone('+213550123456'), '0550123456');
      expect(normalizeDzPhone('00213 661 12 34 56'), '0661123456');
      expect(normalizeDzPhone('213770123456'), '0770123456');
    });
    test('rejects landlines, wrong length and junk', () {
      expect(normalizeDzPhone('021123456'), isNull); // landline
      expect(normalizeDzPhone('055012345'), isNull); // too short
      expect(normalizeDzPhone('05501234567'), isNull); // too long
      expect(normalizeDzPhone('0450123456'), isNull); // invalid prefix
      expect(normalizeDzPhone('abc'), isNull);
    });
  });

  test('isValidName', () {
    expect(isValidName(' K '), isFalse);
    expect(isValidName('Karim'), isTrue);
    expect(isValidName('x' * 81), isFalse);
  });
}
