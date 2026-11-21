// Login with Google / Facebook, consent screen, rider distances, GPS sheet.
// Run: flutter test test/screenshots/v1_1_screenshot_test.dart --update-goldens --tags screenshot --run-skipped
@Tags(['screenshot'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_app/core/location/location_service.dart';
import 'package:food_app/features/driver/data/driver_position.dart';
import 'package:go_router/go_router.dart';

import '../driver_flow_test.dart' show DriverSetup;
import '../helpers/fake_auth.dart';

Future<void> shot(WidgetTester t, String name) =>
    expectLater(find.byType(MaterialApp), matchesGoldenFile('v11_$name.png'));

Future<void> _images(WidgetTester t) async {
  await t.runAsync(() async {
    for (final e in find.byType(Image).evaluate()) {
      await precacheImage((e.widget as Image).image, e);
    }
  });
  await t.pumpAndSettle();
}

void main() {
  setUpAll(loadFonts);

  for (final lang in ['fr', 'ar']) {
    testWidgets('login $lang', (t) async {
      await pumpFoodApp(t, lang: lang, size: const Size(390, 1150));
      await shot(t, 'login_$lang');
    });

    testWidgets('consent $lang', (t) async {
      final auth = FakeAuthRepository()
        ..seedUser('d@mail.dz', 'secret123', name: 'Rachid')
        ..roles['d@mail.dz'] = 'driver'
        ..signInDirect('d@mail.dz');
      await pumpFoodApp(t, repo: auth, lang: lang,
          consent: FakeConsentRepository()..acceptedDocs = {},
          driver: FakeDriverRepository()..seedDriver());
      await _images(t);
      await shot(t, 'consent_$lang');
    });

    testWidgets('rider jobs $lang', (t) async {
      final s = DriverSetup();
      s.driver.addAvailable(id: 'far', restaurant: 'Grill Hydra',
          restaurantLat: 36.75, restaurantLng: 3.03, lat: 36.74, lng: 3.02);
      s.driver.addAvailable(id: 'near', restaurant: 'Pizzeria El Bahdja',
          restaurantLat: 36.7530, restaurantLng: 3.0590, lat: 36.7650, lng: 3.0700);
      final auth = FakeAuthRepository()
        ..seedUser('d@mail.dz', 'secret123', name: 'Rachid')
        ..roles['d@mail.dz'] = 'driver'
        ..signInDirect('d@mail.dz');
      s.driver.seedDriver(online: true);
      await pumpFoodApp(t, repo: auth, driver: s.driver, sound: s.sound, lang: lang,
          driverPosition: const GeoPoint(36.7525, 3.0588), size: const Size(390, 1700));
      await t.scrollUntilVisible(find.text('Pizzeria El Bahdja').first, 300,
          scrollable: find.byType(Scrollable).first);
      await shot(t, 'rider_jobs_$lang');
    });
  }

  testWidgets('gps sheet fr', (t) async {
    final auth = FakeAuthRepository()
      ..seedUser('d@mail.dz', 'secret123', name: 'Rachid')
      ..roles['d@mail.dz'] = 'driver'
      ..signInDirect('d@mail.dz');
    await pumpFoodApp(t, repo: auth, lang: 'fr', gps: GpsStatus.off,
        driver: FakeDriverRepository()..seedDriver());
    await t.tap(find.text('Commencer').first);
    await t.pumpAndSettle();
    await shot(t, 'gps_sheet_fr');
  });

  testWidgets('privacy fr', (t) async {
    await pumpFoodApp(t, lang: 'fr', size: const Size(390, 1500));
    GoRouter.of(t.element(find.byType(Scaffold).first)).go('/legal/privacy');
    await t.pumpAndSettle();
    await shot(t, 'privacy_fr');
  });
}
