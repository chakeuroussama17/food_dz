import 'package:flutter_test/flutter_test.dart';
import 'package:food_app/core/utils/validators.dart';
import 'package:food_app/features/auth/data/auth_repository.dart';

void main() {
  test('maps Supabase auth error codes', () {
    expect(
      mapAuthException('invalid_credentials', '400'),
      AuthFailure.invalidCredentials,
    );
    expect(
      mapAuthException('email_not_confirmed', '400'),
      AuthFailure.emailNotConfirmed,
    );
    expect(
      mapAuthException('user_already_exists', '422'),
      AuthFailure.userExists,
    );
    expect(mapAuthException('otp_expired', '403'), AuthFailure.invalidCode);
    expect(
      mapAuthException('over_email_send_rate_limit', '429'),
      AuthFailure.tooManyRequests,
    );
    expect(mapAuthException(null, '429'), AuthFailure.tooManyRequests);
    expect(mapAuthException('something_new', '500'), AuthFailure.unknown);
  });

  test('5xx answers are not reported as "no connection"', () {
    expect(
      mapRetryableFailure(null, 'ClientException: Failed to fetch'),
      AuthFailure.network,
    );
    expect(
      mapRetryableFailure(
        '500',
        '{"code":500,"error_code":"unexpected_failure",'
            '"msg":"Error sending confirmation email"}',
      ),
      AuthFailure.emailSendFailed,
    );
    expect(mapRetryableFailure('503', 'upstream timeout'), AuthFailure.server);
  });

  test('email and password validation', () {
    expect(isValidEmail('karim@gmail.com'), isTrue);
    expect(isValidEmail('  karim@mail.dz '), isTrue);
    expect(isValidEmail('karim@gmail'), isFalse);
    expect(isValidEmail('kar im@gmail.com'), isFalse);
    expect(isValidEmail(''), isFalse);
    expect(isValidPassword('1234567'), isFalse);
    expect(isValidPassword('12345678'), isTrue);
    expect(isValidPassword('x' * 73), isFalse);
  });
}
