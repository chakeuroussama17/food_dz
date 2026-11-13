import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/data/auth_providers.dart';
import '../config/env.dart';

/// 'android', 'ios' or 'web' ('' elsewhere).
String appPlatform() {
  if (kIsWeb) return 'web';
  return switch (defaultTargetPlatform) {
    TargetPlatform.android => 'android',
    TargetPlatform.iOS => 'ios',
    _ => '',
  };
}

/// What the app tells the server when it starts (for the admin's analysis).
class DeviceSnapshot {
  const DeviceSnapshot({
    this.platform = '',
    this.appVersion = '',
    this.os = '',
    this.device = '',
  });
  final String platform;
  final String appVersion;
  final String os;
  final String device;
}

Future<DeviceSnapshot> readDevice() async {
  var version = '';
  var os = '';
  var device = '';
  try {
    final p = await PackageInfo.fromPlatform();
    version = p.buildNumber.isEmpty
        ? p.version
        : '${p.version}+${p.buildNumber}';
  } catch (_) {}
  try {
    final info = DeviceInfoPlugin();
    if (kIsWeb) {
      final w = await info.webBrowserInfo;
      os = w.platform ?? '';
      device = w.browserName.name;
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      final a = await info.androidInfo;
      os = 'Android ${a.version.release}';
      device = '${a.manufacturer} ${a.model}';
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final i = await info.iosInfo;
      os = '${i.systemName} ${i.systemVersion}';
      device = i.utsname.machine;
    }
  } catch (_) {}
  return DeviceSnapshot(
    platform: appPlatform(),
    appVersion: version,
    os: os,
    device: device,
  );
}

abstract interface class SessionRepository {
  /// Never throws.
  Future<void> touch(DeviceSnapshot d, String lang);
}

class SupabaseSessionRepository implements SessionRepository {
  SupabaseSessionRepository(this._db);
  final SupabaseClient _db;

  @override
  Future<void> touch(DeviceSnapshot d, String lang) async {
    try {
      await _db.rpc(
        'touch_session',
        params: {
          'p_platform': d.platform,
          'p_app_version': d.appVersion,
          'p_os': d.os,
          'p_device': d.device,
          'p_lang': lang,
        },
      );
    } catch (_) {
      // Analysis only: never in the user's way.
    }
  }
}

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  if (!Env.hasSupabase) {
    throw StateError('Supabase not configured (env.json)');
  }
  return SupabaseSessionRepository(Supabase.instance.client);
});

/// Overridden in tests (no platform channels there).
final deviceSnapshotProvider = FutureProvider<DeviceSnapshot>(
  (ref) => readDevice(),
);

/// Tells the server "this user opened the app" once per sign-in and app
/// launch. Watched by the app with the current language.
final sessionTouchProvider = FutureProvider.family<void, String>((
  ref,
  lang,
) async {
  final uid = ref.watch(currentUserIdProvider).value;
  if (uid == null) return;
  final device = await ref.watch(deviceSnapshotProvider.future);
  await ref.read(sessionRepositoryProvider).touch(device, lang);
});
