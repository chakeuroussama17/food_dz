import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env.dart';
import '../../../core/i18n/locale_controller.dart';
import '../../../l10n/app_localizations.dart';
import 'auth_repository.dart';
import '../../../core/push/push_service.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (!Env.hasSupabase) return UnconfiguredAuthRepository();
  return SupabaseAuthRepository(Supabase.instance.client);
});

const _onboardingKey = 'onboarding_done';
const _rememberKey = 'remember_me';

/// Everything the router needs to decide where the user may go.
/// Notifies the router whenever the session changes.
class AppSession extends ChangeNotifier {
  AppSession(this._repo, this._prefs) {
    _user = _repo.currentUser;
    if (_user != null) refreshRole();
    _sub = _repo.userChanges.listen((u) {
      final changed = u?.id != _user?.id;
      _user = u;
      if (changed) {
        _role = null;
        if (u != null) refreshRole();
      }
      notifyListeners();
    });
  }

  final AuthRepository _repo;
  final SharedPreferences _prefs;
  late final StreamSubscription<AppUser?> _sub;
  AppUser? _user;

  /// Set while the user is in the "forgot password" flow: they are signed in
  /// after verifying the code but must stay on the new-password page.
  bool recoveringPassword = false;

  AppUser? get user => _user;
  bool get signedIn => _user != null;

  String? _role;

  /// Null while loading (or signed out).
  String? get role => _role;

  /// True while the restaurant registration form is creating the account
  /// and the restaurant, so the router doesn't navigate away mid-way.
  bool registeringRestaurant = false;

  void setRegisteringRestaurant(bool v) {
    registeringRestaurant = v;
    notifyListeners();
  }

  int _roleRequest = 0;

  /// (Re)loads the role from the database, e.g. after registering a
  /// restaurant. Falls back to 'customer' if it can't be read.
  Future<void> refreshRole() async {
    final ticket = ++_roleRequest;
    String r;
    try {
      r = await _repo.fetchRole();
    } catch (_) {
      r = 'customer';
    }
    if (ticket != _roleRequest || _user == null) return; // outdated
    _role = r;
    notifyListeners();
  }

  bool get onboardingDone => _prefs.getBool(_onboardingKey) == true;
  Future<void> completeOnboarding() async {
    await _prefs.setBool(_onboardingKey, true);
    notifyListeners();
  }

  bool get rememberMe => _prefs.getBool(_rememberKey) ?? true;
  Future<void> setRememberMe(bool v) => _prefs.setBool(_rememberKey, v);

  /// Called once at startup: if the user unticked "Remember me", a session
  /// left over from last time is ended.
  Future<void> applyRememberMe() async {
    if (signedIn && !rememberMe) await _repo.signOut();
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

/// Listen with ListenableBuilder; the router uses it as refreshListenable.
final appSessionProvider = Provider<AppSession>((ref) {
  final session = AppSession(
    ref.watch(authRepositoryProvider),
    ref.watch(sharedPrefsProvider),
  );
  ref.onDispose(session.dispose);
  return session;
});

/// Id of the signed-in user (null when signed out). Providers that load
/// per-user data watch this so they reload after login / logout.
/// Logs out after stopping this phone's push alerts for the account.
Future<void> signOutAndStopPush(WidgetRef ref) async {
  await ref.read(pushServiceProvider).stop();
  await ref.read(authRepositoryProvider).signOut();
}

final currentUserIdProvider = StreamProvider<String?>((ref) async* {
  final repo = ref.watch(authRepositoryProvider);
  yield repo.currentUser?.id;
  yield* repo.userChanges.map((u) => u?.id).distinct();
});

/// Translated message for an auth failure.
String authErrorText(AppLocalizations l, Object error) {
  final f = error is AuthError ? error.failure : AuthFailure.unknown;
  if (kDebugMode && error is AuthError && f != AuthFailure.invalidCredentials) {
    debugPrint('Auth error: ${error.detail}');
  }
  return switch (f) {
    AuthFailure.invalidCredentials => l.errInvalidCredentials,
    AuthFailure.emailNotConfirmed => l.errInvalidCredentials,
    AuthFailure.userExists => l.errUserExists,
    AuthFailure.weakPassword => l.errWeakPassword,
    AuthFailure.invalidCode => l.errCodeInvalid,
    AuthFailure.tooManyRequests => l.errTooManyRequests,
    AuthFailure.emailSendFailed => l.errEmailSend,
    AuthFailure.server => l.errServer,
    AuthFailure.network => l.errNetwork,
    AuthFailure.backendMissing => l.errBackendMissing,
    AuthFailure.unknown => l.errGeneric,
  };
}
