import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The new-order chime.
abstract interface class AlertSound {
  Future<void> play();
}

class AssetAlertSound implements AlertSound {
  AudioPlayer? _player;

  @override
  Future<void> play() async {
    final p = _player ??= AudioPlayer();
    await p.stop();
    await p.play(AssetSource('sounds/new_order.wav'), volume: 1);
  }

  Future<void> dispose() async => _player?.dispose();
}

final alertSoundProvider = Provider<AlertSound>((ref) {
  final s = AssetAlertSound();
  ref.onDispose(s.dispose);
  return s;
});

/// Browsers only allow sound after the user has tapped the page once.
/// Native apps can play right away.
bool _unlocked = !kIsWeb;

/// True once sound may play (always on phones; after a tap in browsers).
bool get audioUnlocked => _unlocked;

/// Call from a tap handler.
void markAudioUnlocked() => _unlocked = true;
