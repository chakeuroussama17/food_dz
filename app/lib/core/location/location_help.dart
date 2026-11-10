import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import 'location_service.dart';

/// Explains why the location didn't work, with a button that fixes it
/// (turn on GPS, or allow the app in the phone settings).
void showLocationProblem(BuildContext context, LocationResult r) {
  if (r == LocationResult.granted) return;
  final l = AppLocalizations.of(context);
  final (
    String text,
    String? action,
    Future<bool> Function()? open,
  ) = switch (r) {
    LocationResult.serviceOff when !kIsWeb => (
      l.locationServiceOff,
      l.turnOn,
      Geolocator.openLocationSettings,
    ),
    LocationResult.deniedForever when !kIsWeb => (
      l.locationBlocked,
      l.openSettings,
      Geolocator.openAppSettings,
    ),
    LocationResult.denied ||
    LocationResult.deniedForever => (l.locationDenied, null, null),
    _ => (l.locationUnavailable, null, null),
  };
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(text),
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
      duration: const Duration(seconds: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      action: action == null
          ? null
          : SnackBarAction(
              label: action,
              textColor: AppColors.primary,
              onPressed: () => open!(),
            ),
    ),
  );
}
