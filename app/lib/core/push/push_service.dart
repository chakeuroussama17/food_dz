import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';

/// Alerts while the app is closed (Firebase Cloud Messaging).
abstract interface class PushService {
  /// After login: asks permission, registers this phone for [lang] alerts.
  /// Calls [onOpen] with the screen to show when an alert is tapped.
  Future<void> start({
    required String lang,
    required void Function(String route) onOpen,
  });

  /// Before logout: this phone stops receiving the account's alerts.
  Future<void> stop();
}

/// Used when Firebase isn't configured (web for now, local runs, tests).
class NoPushService implements PushService {
  const NoPushService();
  @override
  Future<void> start({
    required String lang,
    required void Function(String route) onOpen,
  }) async {}
  @override
  Future<void> stop() async {}
}

class FirebasePushService implements PushService {
  FirebasePushService(this._db);
  final SupabaseClient _db;
  String? _token;
  bool _listening = false;
  StreamSubscription<String>? _refresh;

  static Future<void> _init() async {
    if (Firebase.apps.isNotEmpty) return;
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: Env.firebaseApiKey,
        appId: Env.firebaseAppId,
        messagingSenderId: Env.firebaseSenderId,
        projectId: Env.firebaseProjectId,
      ),
    );
  }

  String get _platform =>
      defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';

  Future<void> _register(String token, String lang) async {
    _token = token;
    await _db.rpc(
      'register_push_token',
      params: {'p_token': token, 'p_platform': _platform, 'p_lang': lang},
    );
  }

  @override
  Future<void> start({
    required String lang,
    required void Function(String route) onOpen,
  }) async {
    try {
      await _init();
      final fm = FirebaseMessaging.instance;
      final perm = await fm.requestPermission();
      if (perm.authorizationStatus == AuthorizationStatus.denied) return;
      // getToken/onTokenRefresh still work in firebase_messaging 17; the new
      // register()/onRegistered gives an installation id meant for a
      // different send API, while the push function uses FCM tokens.
      // ignore: deprecated_member_use
      final token = await fm.getToken();
      if (token != null) await _register(token, lang);
      await _refresh?.cancel();
      // ignore: deprecated_member_use
      _refresh = fm.onTokenRefresh.listen((t) => _register(t, lang));

      void open(RemoteMessage m) {
        final r = m.data['route'];
        if (r is String && r.startsWith('/')) onOpen(r);
      }

      if (!_listening) {
        _listening = true;
        FirebaseMessaging.onMessageOpenedApp.listen(open);
        final first = await fm.getInitialMessage();
        if (first != null) open(first);
      }
    } catch (e) {
      // Never block the app because of notifications.
      debugPrint('push disabled: $e');
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _refresh?.cancel();
      final t = _token;
      if (t != null) {
        await _db.rpc('unregister_push_token', params: {'p_token': t});
      }
      _token = null;
    } catch (_) {}
  }
}

final pushServiceProvider = Provider<PushService>((ref) {
  // Web push comes with the web version; Android/iOS first.
  if (kIsWeb || !Env.hasFirebase || !Env.hasSupabase) {
    return const NoPushService();
  }
  return FirebasePushService(Supabase.instance.client);
});
