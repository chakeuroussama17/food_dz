import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/i18n/locale_controller.dart';
import '../../../core/location/location_service.dart';
import 'driver_repository.dart';

/// The rider's live position while a delivery page is open: the last known
/// point first, then GPS updates every ~20 m. Null when the phone refuses or
/// has no GPS (the screens then simply don't show distances).
final driverPositionProvider = StreamProvider.autoDispose<GeoPoint?>((
  ref,
) async* {
  final last = ref.read(locationProvider).position;
  if (last != null) yield last;
  try {
    if (!await Geolocator.isLocationServiceEnabled()) return;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      return;
    }
    await for (final p in Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 20,
      ),
    )) {
      yield GeoPoint(p.latitude, p.longitude);
    }
  } catch (_) {
    // No GPS, or a browser that refuses: keep what we have.
  }
});

/// Distance in km from [me] to a point, or null when either is unknown.
double? kmTo(GeoPoint? me, double? lat, double? lng) =>
    me == null || lat == null || lng == null
    ? null
    : distanceKm(me.lat, me.lng, lat, lng);

/// Closer than this to the customer = "You have arrived".
const arrivedKm = 0.15;

/// Orders where the rider tapped "I'm at the restaurant" (check-in). Kept
/// on the phone: it only changes what the delivery screen asks next.
final checkedInProvider = NotifierProvider<CheckedIn, Set<String>>(
  CheckedIn.new,
);

class CheckedIn extends Notifier<Set<String>> {
  static const _key = 'rider_checked_in';

  @override
  Set<String> build() =>
      (ref.read(sharedPrefsProvider).getStringList(_key) ?? const []).toSet();

  Future<void> add(String orderId) async {
    // Only the last few matter.
    final next = [...state.where((x) => x != orderId), orderId];
    final keep = next.length > 20 ? next.sublist(next.length - 20) : next;
    state = keep.toSet();
    await ref.read(sharedPrefsProvider).setStringList(_key, keep);
  }
}

/// While the rider has a delivery running, sends the GPS position so the
/// customer can follow it: at most every 10 s, sooner after 50 m, and once
/// a minute when standing still (the server forgets points after 10 min).
/// Watched by the rider pages; does nothing without a delivery.
final driverTrackerProvider = Provider.autoDispose<void>((ref) {
  // Only "is a delivery running?": the list itself refreshes every 10 s.
  final running = ref.watch(
    driverActiveOrdersProvider.select(
      (v) => (v.value ?? const []).any((o) => o.isActive),
    ),
  );
  if (!running) return;
  GeoPoint? last;
  DateTime? lastAt;

  void send(GeoPoint p) {
    last = p;
    lastAt = DateTime.now();
    // Losing one point is fine: the next one follows.
    ref
        .read(driverRepositoryProvider)
        .updateLocation(p.lat, p.lng)
        .catchError((_) {});
  }

  ref.listen(driverPositionProvider, (_, next) {
    final p = next.value;
    if (p == null) return;
    final prev = last;
    final at = lastAt;
    final moved = prev == null
        ? double.infinity
        : distanceKm(prev.lat, prev.lng, p.lat, p.lng) * 1000;
    if (at != null &&
        DateTime.now().difference(at) < const Duration(seconds: 10) &&
        moved < 50) {
      return;
    }
    send(p);
  }, fireImmediately: true);

  final timer = Timer.periodic(const Duration(minutes: 1), (_) {
    final p = last;
    if (p != null) send(p);
  });
  ref.onDispose(timer.cancel);
});
