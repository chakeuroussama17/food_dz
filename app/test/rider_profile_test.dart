import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_app/features/driver/data/driver_repository.dart';
import 'package:food_app/features/driver/data/rider_levels.dart';
import 'package:food_app/features/ratings/ratings_models.dart';
import 'package:go_router/go_router.dart';

import 'driver_flow_test.dart' show DriverSetup, da;
import 'helpers/fake_auth.dart';

Future<void> go(WidgetTester t, String path) async {
  GoRouter.of(t.element(find.byType(Scaffold).first)).go(path);
  await t.pumpAndSettle();
}

/// Scrolls the page until [f] is built, then shows it.
Future<void> reveal(WidgetTester t, Finder f) async {
  if (f.evaluate().isEmpty) {
    await t.scrollUntilVisible(
      f,
      300,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await t.ensureVisible(f);
}

Future<void> tap(WidgetTester t, Finder f) async {
  await reveal(t, f);
  await t.pumpAndSettle();
  await t.tap(f);
  await t.pumpAndSettle();
}

const pro = DriverStats(
  deliveries: 48,
  earned: 9600,
  average: 4.6,
  count: 41,
  average30d: 4.8,
  count30d: 12,
  stars: {5: 30, 4: 7, 3: 2, 2: 1, 1: 1},
  fiveStarStreak: 6,
);

Future<(DriverSetup, FakeAuthRepository)> app(
  WidgetTester t, {
  DriverStats stats = pro,
  Map<String, int> reasons = const {'late': 3, 'no_contact': 1},
  String lang = 'en',
  bool dark = false,
  Size size = const Size(375, 812),
}) async {
  final s = DriverSetup();
  s.driver.statsValue = stats;
  final ratings = FakeRatingsRepository()
    ..driver = DriverRatingSummary(
      average: stats.average,
      count: stats.count,
      reasons: reasons,
    );
  final auth = FakeAuthRepository()
    ..seedUser('d@mail.dz', 'secret123', name: 'Rachid Benali')
    ..roles['d@mail.dz'] = 'driver'
    ..signInDirect('d@mail.dz');
  await pumpFoodApp(
    t,
    repo: auth,
    driver: s.driver,
    ratings: ratings,
    lang: lang,
    dark: dark,
    size: size,
  );
  await go(t, '/driver/account');
  return (s, auth);
}

void main() {
  setUpAll(loadFonts);

  test('levels: earned with deliveries, kept with the rating', () {
    expect(RiderLevel.of(const DriverStats()), RiderLevel.rookie);
    expect(RiderLevel.of(pro), RiderLevel.pro);
    // Enough deliveries for Expert, not the rating.
    expect(
      RiderLevel.of(const DriverStats(deliveries: 150, average: 4.3)),
      RiderLevel.pro,
    );
    expect(
      RiderLevel.of(const DriverStats(deliveries: 150, average: 4.6)),
      RiderLevel.expert,
    );
    expect(RiderLevel.pro.progress(pro), closeTo(28 / 80, .001));
  });

  testWidgets('profile: level, numbers, rating summary', (t) async {
    await app(t);
    expect(find.text('Rachid Benali'), findsOneWidget);
    expect(find.text('Pro level'), findsOneWidget);
    expect(find.text('52 more deliveries to become Expert'), findsOneWidget);
    expect(find.text('48'), findsOneWidget);
    expect(find.text(da('9 600 DA')), findsOneWidget);
    expect(find.text('4.6'), findsWidgets);
    expect(find.text('6 five-star ratings in a row'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('rating details: 30 days vs all time, reasons and tips', (
    t,
  ) async {
    await app(t);
    await tap(t, find.text('See details'));
    expect(find.text('Last 30 days'), findsOneWidget);
    expect(find.text('All time'), findsOneWidget);
    expect(find.byIcon(Icons.trending_up_rounded), findsOneWidget);
    await reveal(t, find.text('Tips to improve'));
    await reveal(
      t,
      find.text('Call the customer 2 minutes before you arrive.'),
    );
    expect(
      find.text('Call the customer 2 minutes before you arrive.'),
      findsOneWidget,
    );
  });

  testWidgets('edit: name, phone and vehicle saved; bad phone refused', (
    t,
  ) async {
    final (s, _) = await app(t);
    await tap(t, find.text('Edit my profile'));
    final fields = find.byType(TextField);
    await t.enterText(fields.at(0), 'Rachid  Benali');
    await t.enterText(fields.at(1), '123');
    await tap(t, find.text('Car'));
    await tap(t, find.text('Save changes'));
    expect(
      find.text('Invalid number (05, 06 or 07 + 8 digits)'),
      findsOneWidget,
    );
    await t.enterText(fields.at(1), '0770 11 22 33');
    await tap(t, find.text('Save changes'));
    expect(s.driver.calls.last, 'profile:Rachid Benali:0770112233:car');
    expect(find.text('Saved'), findsOneWidget);
  });

  testWidgets('photo: picked and uploaded', (t) async {
    await app(t);
    await tap(t, find.byIcon(Icons.photo_camera_rounded));
    expect(t.takeException(), isNull);
  });

  testWidgets('delete: like the customer, refused while money is owed', (
    t,
  ) async {
    final (s, auth) = await app(t);
    s.driver.cash.add(
      CashDue(
        orderId: 'o9',
        code: 'OLD999',
        restaurantName: 'Pizzeria El Bahdja',
        amount: 1400,
        deliveredAt: DateTime.now(),
      ),
    );
    await tap(t, find.text('Delete my account'));
    expect(find.byType(AlertDialog), findsOneWidget);
    await tap(t, find.text('Delete my account').last);
    expect(s.driver.calls, isNot(contains('delete')));
    expect(
      find.text('First hand the food money to the restaurants.'),
      findsOneWidget,
    );
    await t.pump(const Duration(seconds: 5));
    await t.pumpAndSettle();

    s.driver.cash.clear();
    await tap(t, find.text('Delete my account'));
    await tap(t, find.text('Delete my account').last);
    expect(s.driver.calls.last, 'delete');
    expect(auth.currentUser, isNull); // signed out
  });
}
