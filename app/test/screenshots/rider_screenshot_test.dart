// Rider screens (after the rider prototype): home, jobs, each delivery step,
// the item checklist and "Well done".
// Run: flutter test test/screenshots/rider_screenshot_test.dart --update-goldens --tags screenshot --run-skipped
@Tags(['screenshot'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_app/core/location/location_service.dart';
import 'package:food_app/features/driver/data/driver_repository.dart';
import 'package:go_router/go_router.dart';

import '../driver_flow_test.dart' show DriverSetup;
import '../helpers/fake_auth.dart';

DriverOrder order(String status) => DriverOrder(
  id: 'd1',
  code: 'K7P2Q1',
  status: status,
  restaurantName: 'Pizzeria El Bahdja',
  restaurantAddress: 'Rue Larbi Ben Mhidi',
  restaurantArea: 'Alger Centre',
  restaurantPhone: '0550111222',
  restaurantLat: 36.7690,
  restaurantLng: 3.0560,
  customerName: 'Amina Benali',
  customerPhone: '0550123456',
  addressText: 'Rue Didouche Mourad 12',
  area: 'Sidi M’Hamed',
  addressDetails: '3e étage',
  lat: 36.7600,
  lng: 3.0480,
  notes: 'Sonner deux fois',
  foodTotal: 1400,
  deliveryFee: 200,
  total: 1600,
  placedAt: DateTime.now().subtract(const Duration(minutes: 20)),
  items: const [
    OrderLine(
      name: 'Pizza Margherita (Large)',
      unitPrice: 700,
      quantity: 2,
      lineTotal: 1400,
    ),
    OrderLine(
      name: 'Coca-Cola 33 cl',
      unitPrice: 100,
      quantity: 1,
      lineTotal: 100,
    ),
  ],
);

Future<void> go(WidgetTester t, String path) async {
  GoRouter.of(t.element(find.byType(Scaffold).first)).go(path);
  await t.pumpAndSettle();
}

void main() {
  setUpAll(loadFonts);

  for (final (lang, dark) in [('fr', false), ('ar', false), ('fr', true)]) {
    final tag = '$lang${dark ? '_dark' : ''}';

    Future<DriverSetup> app(
      WidgetTester t, {
      bool online = false,
      DriverOrder? mine,
      bool jobs = false,
    }) async {
      final s = DriverSetup(online: online);
      if (mine != null) s.driver.mine.add(mine);
      if (jobs) {
        s.driver.offers.addAll([
          AvailableOrder(
            id: 'a1',
            code: 'K7P2Q1',
            status: 'ready',
            restaurantName: 'Pizzeria El Bahdja',
            restaurantAddress: 'Rue Larbi Ben Mhidi',
            restaurantArea: 'Alger Centre',
            restaurantLat: 36.7690,
            restaurantLng: 3.0560,
            area: 'Sidi M’Hamed',
            lat: 36.7600,
            lng: 3.0480,
            deliveryFee: 200,
            total: 1600,
            itemCount: 3,
            placedAt: DateTime.now().subtract(const Duration(minutes: 6)),
          ),
          AvailableOrder(
            id: 'a2',
            code: 'B4R9X2',
            status: 'accepted',
            restaurantName: 'Burger House',
            restaurantAddress: 'Hydra',
            restaurantArea: 'Hydra',
            restaurantLat: 36.7450,
            restaurantLng: 3.0400,
            area: 'El Biar',
            lat: 36.7680,
            lng: 3.0300,
            deliveryFee: 250,
            total: 2100,
            itemCount: 2,
            placedAt: DateTime.now().subtract(const Duration(minutes: 2)),
          ),
        ]);
      }
      final auth = FakeAuthRepository()
        ..seedUser('d@mail.dz', 'secret123', name: 'Rachid')
        ..roles['d@mail.dz'] = 'driver'
        ..signInDirect('d@mail.dz');
      await pumpFoodApp(
        t,
        repo: auth,
        driver: s.driver,
        sound: s.sound,
        lang: lang,
        dark: dark,
        size: const Size(390, 844),
        driverPosition: const GeoPoint(36.7735, 3.0590),
      );
      return s;
    }

    Future<void> shot(String name) => expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('rider_${name}_$tag.png'),
    );

    testWidgets('home offline $tag', (t) async {
      await app(t);
      await shot('home');
    });

    testWidgets('jobs $tag', (t) async {
      await app(t, online: true, jobs: true);
      await shot('jobs');
    });

    testWidgets('to restaurant $tag', (t) async {
      await app(t, online: true, mine: order('accepted'));
      await go(t, '/driver/orders/d1');
      expect(t.takeException(), isNull);
      await shot('to_shop');
    });

    testWidgets('checklist $tag', (t) async {
      await app(t, online: true, mine: order('ready'));
      await go(t, '/driver/orders/d1');
      await t.tap(find.byIcon(Icons.storefront_rounded).last); // check in
      await t.pumpAndSettle();
      await t.tap(find.byIcon(Icons.checklist_rounded));
      await t.pumpAndSettle();
      await t.tap(find.text('Pizza Margherita (Large)'));
      await t.pumpAndSettle();
      await shot('checklist');
    });

    testWidgets('to customer $tag', (t) async {
      await app(t, online: true, mine: order('picked_up'));
      await go(t, '/driver/orders/d1');
      await shot('to_customer');
    });

    testWidgets('well done $tag', (t) async {
      await app(t, online: true, mine: order('picked_up'));
      await go(t, '/driver/orders/d1');
      await t.tap(find.byIcon(Icons.task_alt_rounded));
      await t.pumpAndSettle();
      await t.tap(find.byIcon(Icons.photo_camera_rounded));
      await t.pumpAndSettle();
      await t.tap(find.byIcon(Icons.task_alt_rounded).last);
      await t.pumpAndSettle();
      await shot('done');
    });
  }
}
