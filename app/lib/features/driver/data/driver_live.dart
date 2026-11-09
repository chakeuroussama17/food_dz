import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/alert_sound.dart';
import 'driver_repository.dart';

class DriverLiveState {
  const DriverLiveState({this.soundReady = false});

  /// False in browsers until the driver taps the page once.
  final bool soundReady;
}

/// While a driver uses the app: refreshes their orders live (Realtime),
/// checks for new available orders every 10 s when online, and chimes when
/// a new one appears and the driver is free.
class DriverLiveController extends Notifier<DriverLiveState> {
  static const pollEvery = Duration(seconds: 10);

  Set<String> _seen = {};

  @override
  DriverLiveState build() {
    final me = ref.watch(myDriverProvider).value;
    const idle = DriverLiveState();
    if (me == null) return idle;

    final sub = ref.read(driverRepositoryProvider).myOrderChanges(me.id).listen(
      (_) {
        ref.invalidate(driverActiveOrdersProvider);
        ref.invalidate(driverHistoryProvider);
        // The restaurant confirming the cash also arrives here.
        ref.invalidate(driverCashPendingProvider);
      },
      onError: (_) {},
    );
    ref.onDispose(sub.cancel);

    if (me.isApproved && me.isOnline) {
      final timer = Timer.periodic(pollEvery, (_) {
        ref.invalidate(availableOrdersProvider);
        ref.invalidate(driverActiveOrdersProvider);
      });
      ref.onDispose(timer.cancel);

      ref.listen(availableOrdersProvider, (_, next) {
        final list = next.value;
        if (list == null) return;
        final ids = {for (final o in list) o.id};
        final arrived = ids.difference(_seen);
        _seen = ids;
        final busy = ref.read(driverActiveOrdersProvider).value?.isNotEmpty;
        if (arrived.isNotEmpty && busy == false) _ring();
      });
      final current = ref.read(availableOrdersProvider).value;
      if (current != null) _seen = {for (final o in current) o.id};
    }
    return DriverLiveState(soundReady: audioUnlocked);
  }

  Future<void> _ring() async {
    if (!state.soundReady) return;
    try {
      await ref.read(alertSoundProvider).play();
    } catch (_) {}
  }

  /// From a tap: allows sound in browsers and plays a test chime.
  Future<void> enableSound() async {
    markAudioUnlocked();
    state = const DriverLiveState(soundReady: true);
    await _ring();
  }
}

final driverLiveProvider =
    NotifierProvider<DriverLiveController, DriverLiveState>(
      DriverLiveController.new,
    );
