import 'package:flutter/foundation.dart';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../i18n/locale_controller.dart';

class GeoPoint {
  const GeoPoint(this.lat, this.lng);
  final double lat;
  final double lng;
}

/// Great-circle distance in km (haversine). Pure, for tests and cards.
double distanceKm(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371.0;
  double rad(double d) => d * math.pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLng = rad(lng2 - lng1);
  final a =
      math.pow(math.sin(dLat / 2), 2) +
      math.cos(rad(lat1)) *
          math.cos(rad(lat2)) *
          math.pow(math.sin(dLng / 2), 2);
  return 2 * r * math.asin(math.sqrt(a));
}

/// "1.4" under 10 km, "12" above.
String formatKm(double km) =>
    km < 10 ? km.toStringAsFixed(1) : km.round().toString();

enum LocationResult {
  granted,

  /// "Don't allow" this time.
  denied,

  /// Refused for good: only the phone settings can allow it now.
  deniedForever,

  /// The phone's location (GPS) is turned off.
  serviceOff,

  /// No position (no signal, browser error…).
  unavailable,
}

/// The customer's last known position (kept between visits) and whether we
/// already showed the "Access location" screen.
class LocationState {
  const LocationState({this.position, this.asked = false});
  final GeoPoint? position;
  final bool asked;
}

final locationProvider = NotifierProvider<LocationController, LocationState>(
  LocationController.new,
);

class LocationController extends Notifier<LocationState> {
  static const _kAsked = 'location_asked';
  static const _kLat = 'last_lat';
  static const _kLng = 'last_lng';

  @override
  LocationState build() {
    final p = ref.read(sharedPrefsProvider);
    final lat = p.getDouble(_kLat);
    final lng = p.getDouble(_kLng);
    return LocationState(
      asked: p.getBool(_kAsked) ?? false,
      position: lat != null && lng != null ? GeoPoint(lat, lng) : null,
    );
  }

  Future<void> markAsked() async {
    await ref.read(sharedPrefsProvider).setBool(_kAsked, true);
    state = LocationState(position: state.position, asked: true);
  }

  /// Asks permission (if needed) and reads the position once.
  Future<LocationResult> locate() async {
    await markAsked();
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return LocationResult.serviceOff;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        return LocationResult.deniedForever;
      }
      if (perm == LocationPermission.denied) return LocationResult.denied;
      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 15),
          ),
        );
      } catch (_) {
        // Slow GPS (indoors): use the phone's last known position.
        if (!kIsWeb) pos = await Geolocator.getLastKnownPosition();
      }
      if (pos == null) return LocationResult.unavailable;
      await setPosition(GeoPoint(pos.latitude, pos.longitude));
      return LocationResult.granted;
    } catch (_) {
      return LocationResult.unavailable;
    }
  }

  Future<void> setPosition(GeoPoint p) async {
    final prefs = ref.read(sharedPrefsProvider);
    await prefs.setDouble(_kLat, p.lat);
    await prefs.setDouble(_kLng, p.lng);
    state = LocationState(position: p, asked: true);
  }
}
