import 'package:food_app/core/session/session_tracker.dart';

/// Records "app opened" calls instead of sending them.
class FakeSessionRepository implements SessionRepository {
  final touches = <String>[];

  @override
  Future<void> touch(DeviceSnapshot d, String lang) async =>
      touches.add('${d.platform}:${d.appVersion}:${d.device}:$lang');
}

const fakeDevice = DeviceSnapshot(
  platform: 'android',
  appVersion: '0.3.0+12',
  os: 'Android 14',
  device: 'Samsung SM-A155F',
);
