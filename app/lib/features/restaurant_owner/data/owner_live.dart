import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/alert_sound.dart';
import '../../../core/i18n/locale_controller.dart';

export '../../../core/audio/alert_sound.dart';
import 'owner_orders_repository.dart';
import 'owner_repository.dart';

class OwnerLiveState {
  const OwnerLiveState({
    this.newCount = 0,
    this.muted = false,
    this.soundReady = false,
  });

  /// Orders waiting to be accepted or rejected.
  final int newCount;
  final bool muted;

  /// False on the web until the user taps "Enable sound alerts".
  final bool soundReady;

  OwnerLiveState copyWith({int? newCount, bool? muted, bool? soundReady}) =>
      OwnerLiveState(
        newCount: newCount ?? this.newCount,
        muted: muted ?? this.muted,
        soundReady: soundReady ?? this.soundReady,
      );
}

/// Keeps the restaurant's order lists live while the owner uses the app:
/// listens to Realtime, refreshes every 20 s as a fallback, and rings when
/// a new order arrives, then again every 20 s until it is handled.
class OwnerLiveController extends Notifier<OwnerLiveState> {
  static const ringEvery = Duration(seconds: 20);
  static const _mutedKey = 'owner_alerts_muted';

  Set<String> _seenNew = {};

  @override
  OwnerLiveState build() {
    final prefs = ref.read(sharedPrefsProvider);
    final restaurant = ref.watch(myRestaurantProvider).value;
    final initial = OwnerLiveState(
      muted: prefs.getBool(_mutedKey) ?? false,
      soundReady: audioUnlocked,
    );
    if (restaurant == null) return initial;

    void refresh() {
      ref.invalidate(ownerActiveOrdersProvider);
      ref.invalidate(ownerHistoryProvider);
      ref.invalidate(ownerCashPendingProvider);
    }

    final sub = ref
        .read(ownerOrdersRepositoryProvider)
        .restaurantChanges(restaurant.id)
        .listen((_) => refresh(), onError: (_) {});
    final timer = Timer.periodic(ringEvery, (_) {
      if (state.newCount > 0) _ring();
      ref.invalidate(ownerActiveOrdersProvider);
    });
    ref.onDispose(() {
      sub.cancel();
      timer.cancel();
    });

    Set<String> waitingIn(List<OwnerOrder> list) => {
      for (final o in list)
        if (o.isNew) o.id,
    };

    ref.listen(ownerActiveOrdersProvider, (_, next) {
      final list = next.value;
      if (list == null) return;
      final waiting = waitingIn(list);
      final arrived = waiting.difference(_seenNew);
      _seenNew = waiting;
      state = state.copyWith(newCount: waiting.length);
      if (arrived.isNotEmpty) _ring();
    });

    // Already loaded (e.g. rebuilt after a restaurant change).
    final current = ref.read(ownerActiveOrdersProvider).value;
    if (current != null) {
      _seenNew = waitingIn(current);
      if (_seenNew.isNotEmpty) Future.microtask(_ring);
      return initial.copyWith(newCount: _seenNew.length);
    }
    return initial;
  }

  Future<void> _ring() async {
    if (state.muted || !state.soundReady) return;
    try {
      await ref.read(alertSoundProvider).play();
    } catch (_) {
      // Blocked by the browser or no audio device: the badge still shows.
    }
  }

  /// Called from a tap (unlocks audio in browsers) and plays a test chime.
  Future<void> enableSound() async {
    markAudioUnlocked();
    await ref.read(sharedPrefsProvider).setBool(_mutedKey, false);
    state = state.copyWith(soundReady: true, muted: false);
    await _ring();
  }

  Future<void> setMuted(bool muted) async {
    await ref.read(sharedPrefsProvider).setBool(_mutedKey, muted);
    state = state.copyWith(muted: muted);
    if (!muted && !state.soundReady) await enableSound();
  }
}

final ownerLiveProvider = NotifierProvider<OwnerLiveController, OwnerLiveState>(
  OwnerLiveController.new,
);
