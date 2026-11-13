import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_app/core/location/location_service.dart';
import 'package:food_app/features/orders/data/orders_repository.dart';
import 'package:go_router/go_router.dart';

import 'checkout_flow_test.dart' show Setup;
import 'driver_flow_test.dart' show DriverSetup;
import 'helpers/fake_auth.dart';
import 'screenshots/rider_screenshot_test.dart' as rider;

Future<void> go(WidgetTester t, String path) async {
  GoRouter.of(t.element(find.byType(Scaffold).first)).go(path);
  await t.pumpAndSettle();
}

Future<DriverSetup> riderApp(WidgetTester t, {String? status}) async {
  final s = DriverSetup(online: true);
  if (status != null) s.driver.mine.add(rider.order(status));
  final auth = FakeAuthRepository()
    ..seedUser('d@mail.dz', 'secret123', name: 'Rachid')
    ..roles['d@mail.dz'] = 'driver'
    ..signInDirect('d@mail.dz');
  await pumpFoodApp(
    t,
    repo: auth,
    driver: s.driver,
    driverPosition: const GeoPoint(36.7735, 3.0590),
  );
  return s;
}

void main() {
  setUpAll(loadFonts);

  testWidgets('rider: position sent only while a delivery runs', (t) async {
    final idle = await riderApp(t);
    expect(idle.driver.locations, isEmpty);

    final busy = await riderApp(t, status: 'picked_up');
    expect(busy.driver.locations, [(36.7735, 3.0590)]);
    // Standing still: sent again once a minute, so it never goes stale.
    await t.pump(const Duration(minutes: 1));
    expect(busy.driver.locations.length, 2);
  });

  testWidgets('rider: moving the map stops following, re-centre resumes', (
    t,
  ) async {
    await riderApp(t, status: 'picked_up');
    await go(t, '/driver/orders/d1');
    expect(find.byKey(const Key('recenter')), findsNothing);
    await t.dragFrom(const Offset(200, 290), const Offset(-80, 40));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('recenter')), findsOneWidget);
    await t.tap(find.byKey(const Key('recenter')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('recenter')), findsNothing);
  });

  testWidgets('customer: follows the rider once a position arrives', (t) async {
    final s = Setup();
    s.orders.orders.add(
      CustomerOrder(
        id: 'o1',
        code: 'K7P2Q1',
        status: 'picked_up',
        restaurantId: 'r1',
        restaurantName: 'Pizzeria El Bahdja',
        addressText: 'Rue Didouche 12',
        customerPhone: '0550123456',
        foodTotal: 1400,
        deliveryFee: 200,
        total: 1600,
        placedAt: DateTime.now().subtract(const Duration(minutes: 30)),
        driverName: 'Rachid',
        items: const [
          OrderLine(
            name: 'Pizza Margherita',
            unitPrice: 700,
            quantity: 2,
            lineTotal: 1400,
          ),
        ],
      ),
    );
    final auth = FakeAuthRepository()
      ..seedUser('k@mail.dz', 'secret123')
      ..signInDirect('k@mail.dz');
    await pumpFoodApp(
      t,
      repo: auth,
      catalog: s.catalog,
      account: s.account,
      orders: s.orders,
    );
    await go(t, '/orders/o1');
    expect(find.text('FOLLOW YOUR RIDER'), findsNothing); // no position yet

    s.orders.riderAt['o1'] = RiderLocation(
      lat: 36.7690,
      lng: 3.0560,
      updatedAt: DateTime.now(),
      toLat: 36.7600,
      toLng: 3.0480,
      shopLat: 36.7700,
      shopLng: 3.0600,
    );
    await t.pump(const Duration(seconds: 10)); // next refresh
    await t.pumpAndSettle();
    expect(find.text('FOLLOW YOUR RIDER'), findsOneWidget);
    expect(find.textContaining('1.2 km from you'), findsOneWidget);
    expect(find.byIcon(Icons.delivery_dining_rounded), findsWidgets);
  });

  testWidgets(
    'customer tracking screenshot',
    tags: ['screenshot'],
    skip: true, // run with --run-skipped --update-goldens
    (t) async {
      final s = Setup();
      s.orders.orders.add(
        CustomerOrder(
          id: 'o1',
          code: 'K7P2Q1',
          status: 'picked_up',
          restaurantId: 'r1',
          restaurantName: 'Pizzeria El Bahdja',
          addressText: 'Rue Didouche 12',
          customerPhone: '0550123456',
          foodTotal: 1400,
          deliveryFee: 200,
          total: 1600,
          placedAt: DateTime.now().subtract(const Duration(minutes: 30)),
          driverName: 'Rachid',
          driverPhone: '0661000001',
          items: const [
            OrderLine(
              name: 'Pizza Margherita',
              unitPrice: 700,
              quantity: 2,
              lineTotal: 1400,
            ),
          ],
        ),
      );
      s.orders.riderAt['o1'] = RiderLocation(
        lat: 36.7690,
        lng: 3.0560,
        updatedAt: DateTime(2026, 11, 12, 14, 32),
        toLat: 36.7600,
        toLng: 3.0480,
        shopLat: 36.7735,
        shopLng: 3.0610,
      );
      final auth = FakeAuthRepository()
        ..seedUser('k@mail.dz', 'secret123')
        ..signInDirect('k@mail.dz');
      await pumpFoodApp(
        t,
        repo: auth,
        lang: 'fr',
        catalog: s.catalog,
        account: s.account,
        orders: s.orders,
        size: const Size(390, 1100),
      );
      await go(t, '/orders/o1');
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('screenshots/track_customer_fr.png'),
      );
    },
  );
}
