import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_app/core/location/location_service.dart';
import 'package:food_app/features/driver/data/driver_position.dart';

import 'driver_flow_test.dart' show DriverSetup, tap;
import 'helpers/fake_auth.dart';

Future<void> rider(
  WidgetTester t,
  DriverSetup s, {
  GpsStatus gps = GpsStatus.ok,
  GeoPoint? at,
  List<GpsStatus>? opened,
}) async {
  final auth = FakeAuthRepository()
    ..seedUser('d@mail.dz', 'secret123', name: 'Rachid')
    ..roles['d@mail.dz'] = 'driver'
    ..signInDirect('d@mail.dz');
  await pumpFoodApp(
    t,
    repo: auth,
    driver: s.driver,
    sound: s.sound,
    gps: gps,
    gpsOpened: opened,
    driverPosition: at,
  );
}

void main() {
  setUpAll(loadFonts);

  test('ride time: 25 km/h plus 2 minutes', () {
    expect(rideMinutes(0), 2);
    expect(rideMinutes(5), 14);
  });

  testWidgets('no location: cannot go online, explained, settings opened', (
    t,
  ) async {
    final s = DriverSetup();
    final opened = <GpsStatus>[];
    await rider(t, s, gps: GpsStatus.off, opened: opened);
    await tap(t, find.text('Start riding'));
    expect(find.byKey(const Key('gps-required')), findsOneWidget);
    expect(find.textContaining('location (GPS) is off'), findsOneWidget);
    expect(s.driver.calls, isEmpty);

    // "Settings" opens the phone settings, then checks again (still off).
    await tap(t, find.text('Settings'));
    expect(opened, [GpsStatus.off]);
    expect(find.byKey(const Key('gps-required')), findsOneWidget);
    await tap(t, find.text('Not now'));
    expect(find.byKey(const Key('gps-required')), findsNothing);
    expect(s.driver.calls, isEmpty);
    expect(find.text('Ready to ride?'), findsOneWidget);
  });

  testWidgets('online: distance to each restaurant, nearest first, trip', (
    t,
  ) async {
    final s = DriverSetup();
    // Far one first in the list, near one second.
    s.driver.addAvailable(
      id: 'far',
      restaurant: 'Far Grill',
      restaurantLat: 36.80,
      restaurantLng: 3.20,
      lat: 36.81,
      lng: 3.21,
    );
    s.driver.addAvailable(
      id: 'near',
      restaurant: 'Near Pizza',
      restaurantLat: 36.7530,
      restaurantLng: 3.0590,
      lat: 36.7600,
      lng: 3.0600,
    );
    await rider(t, s, at: const GeoPoint(36.7525, 3.0588));
    await tap(t, find.text('Start riding'));
    expect(s.driver.calls, ['online:true']);

    final near = t.getTopLeft(find.text('Near Pizza'));
    final far = t.getTopLeft(find.text('Far Grill'));
    expect(near.dy, lessThan(far.dy));
    expect(find.byKey(const Key('to-restaurant:near')), findsOneWidget);
    expect(find.text('to the restaurant'), findsNWidgets(2));
    expect(find.textContaining('whole trip'), findsNWidgets(2));
    expect(t.takeException(), isNull);
  });

  testWidgets('online without a position: a card to turn GPS on', (t) async {
    final s = DriverSetup(online: true);
    s.driver.addAvailable();
    await rider(t, s);
    expect(find.textContaining('No position'), findsOneWidget);
  });
}
