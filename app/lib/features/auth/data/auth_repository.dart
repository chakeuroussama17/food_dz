import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Why an auth call failed, mapped to a translated message in the UI.
enum AuthFailure {
  invalidCredentials,
  emailNotConfirmed,
  userExists,
  weakPassword,
  invalidCode,
  tooManyRequests,

  /// The server could not send the code email (e.g. the email provider
  /// refused the recipient).
  emailSendFailed,

  /// Supabase answered with a 5xx error.
  server,
  network,
  backendMissing,
  unknown,
}

class AuthError implements Exception {
  const AuthError(this.failure, [this.detail]);
  final AuthFailure failure;
  final String? detail;

  @override
  String toString() =>
      'AuthError($failure${detail == null ? '' : ': $detail'})';
}

/// The signed-in customer, as the app sees it.
class AppUser {
  const AppUser({required this.id, required this.email, this.name});
  final String id;
  final String email;
  final String? name;
}

/// Customer authentication: email + password, confirmed with a 6-digit code
/// sent by email. Password reset uses the same code flow.
abstract interface class AuthRepository {
  AppUser? get currentUser;
  Stream<AppUser?> get userChanges;

  Future<void> signIn({required String email, required String password});

  /// Creates the account. Returns true when the user is signed in right away
  /// (email confirmation off in Supabase). Returns false when a code was
  /// emailed and [verifySignupCode] must succeed first.
  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
    String? phone,
  });
  Future<void> verifySignupCode({required String email, required String code});
  Future<void> resendSignupCode(String email);

  Future<void> sendRecoveryCode(String email);

  /// Signs the user in on success so they can set a new password.
  Future<void> verifyRecoveryCode({
    required String email,
    required String code,
  });
  Future<void> updatePassword(String password);

  Future<void> signOut();

  /// The signed-in account's role from `profiles.role`
  /// ('customer', 'restaurant', 'driver', 'admin').
  Future<String> fetchRole();
}

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);
  final SupabaseClient _client;

  GoTrueClient get _auth => _client.auth;

  static AppUser? _map(User? u) => u == null
      ? null
      : AppUser(
          id: u.id,
          email: u.email ?? '',
          name: u.userMetadata?['full_name'] as String?,
        );

  @override
  AppUser? get currentUser => _map(_auth.currentUser);

  @override
  Stream<AppUser?> get userChanges =>
      _auth.onAuthStateChange.map((s) => _map(s.session?.user));

  @override
  Future<void> signIn({required String email, required String password}) =>
      _guard(
        () => _auth.signInWithPassword(email: email.trim(), password: password),
      );

  @override
  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    var signedIn = false;
    await _guard(() async {
      final res = await _auth.signUp(
        email: email.trim(),
        password: password,
        data: {'full_name': name.trim(), 'phone': ?phone},
      );
      // With email confirmation on, Supabase hides whether the email is
      // taken: it returns a user with no identities instead of an error.
      if (res.user != null && (res.user!.identities ?? const []).isEmpty) {
        throw const AuthError(AuthFailure.userExists);
      }
      signedIn = res.session != null;
    });
    return signedIn;
  }

  @override
  Future<void> verifySignupCode({
    required String email,
    required String code,
  }) => _guard(
    () =>
        _auth.verifyOTP(email: email.trim(), token: code, type: OtpType.signup),
  );

  @override
  Future<void> resendSignupCode(String email) =>
      _guard(() => _auth.resend(email: email.trim(), type: OtpType.signup));

  @override
  Future<void> sendRecoveryCode(String email) =>
      _guard(() => _auth.resetPasswordForEmail(email.trim()));

  @override
  Future<void> verifyRecoveryCode({
    required String email,
    required String code,
  }) => _guard(
    () => _auth.verifyOTP(
      email: email.trim(),
      token: code,
      type: OtpType.recovery,
    ),
  );

  @override
  Future<void> updatePassword(String password) =>
      _guard(() => _auth.updateUser(UserAttributes(password: password)));

  @override
  Future<void> signOut() => _guard(() => _auth.signOut());

  @override
  Future<String> fetchRole() async {
    final uid = _auth.currentUser?.id;
    if (uid == null) return 'customer';
    final row = await _client
        .from('profiles')
        .select('role')
        .eq('id', uid)
        .maybeSingle();
    return (row?['role'] as String?) ?? 'customer';
  }

  Future<void> _guard(Future<void> Function() call) async {
    try {
      await call();
    } on AuthError {
      rethrow;
    } on AuthRetryableFetchException catch (e) {
      // supabase_flutter uses this type both for "no network" (no status)
      // and for any 5xx answer from the server.
      throw AuthError(mapRetryableFailure(e.statusCode, e.message), e.message);
    } on AuthException catch (e) {
      throw AuthError(mapAuthException(e.code, e.statusCode), e.message);
    } on TimeoutException {
      throw const AuthError(AuthFailure.network);
    } catch (e) {
      // SocketException / ClientException (no network) on mobile and web.
      final s = e.toString();
      if (s.contains('SocketException') ||
          s.contains('ClientException') ||
          s.contains('Failed host lookup') ||
          s.contains('XMLHttpRequest')) {
        throw AuthError(AuthFailure.network, s);
      }
      throw AuthError(AuthFailure.unknown, s);
    }
  }
}

/// Maps Supabase Auth error codes to [AuthFailure]. Public for tests.
AuthFailure mapAuthException(String? code, String? statusCode) {
  switch (code) {
    case 'invalid_credentials':
      return AuthFailure.invalidCredentials;
    case 'email_not_confirmed':
      return AuthFailure.emailNotConfirmed;
    case 'user_already_exists':
    case 'email_exists':
      return AuthFailure.userExists;
    case 'weak_password':
      return AuthFailure.weakPassword;
    case 'otp_expired':
    case 'otp_disabled':
      return AuthFailure.invalidCode;
    case 'over_email_send_rate_limit':
    case 'over_request_rate_limit':
    case 'over_sms_send_rate_limit':
      return AuthFailure.tooManyRequests;
  }
  if (statusCode == '429') return AuthFailure.tooManyRequests;
  return AuthFailure.unknown;
}

/// Classifies an AuthRetryableFetchException. Public for tests.
AuthFailure mapRetryableFailure(String? statusCode, String? message) {
  if (statusCode == null) return AuthFailure.network;
  final m = (message ?? '').toLowerCase();
  if (m.contains('sending') && m.contains('email')) {
    return AuthFailure.emailSendFailed;
  }
  return AuthFailure.server;
}

/// Used when env.json is missing, so the UI shows a clear message instead
/// of crashing.
class UnconfiguredAuthRepository implements AuthRepository {
  @override
  AppUser? get currentUser => null;
  @override
  Stream<AppUser?> get userChanges => const Stream.empty();

  Never _fail() => throw const AuthError(AuthFailure.backendMissing);

  @override
  Future<void> signIn({
    required String email,
    required String password,
    String? phone,
  }) async => _fail();
  @override
  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async => _fail();
  @override
  Future<void> verifySignupCode({
    required String email,
    required String code,
  }) async => _fail();
  @override
  Future<void> resendSignupCode(String email) async => _fail();
  @override
  Future<void> sendRecoveryCode(String email) async => _fail();
  @override
  Future<void> verifyRecoveryCode({
    required String email,
    required String code,
  }) async => _fail();
  @override
  Future<void> updatePassword(String password) async => _fail();
  @override
  Future<void> signOut() async {}
  @override
  Future<String> fetchRole() async => 'customer';
}
