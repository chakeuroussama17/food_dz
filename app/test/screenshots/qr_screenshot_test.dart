// Restaurant QR page (owner) and the in-app scanner.
// Run: flutter test test/screenshots/qr_screenshot_test.dart --update-goldens --tags screenshot --run-skipped
@Tags(['screenshot'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_app/features/qr/qr_repository.dart';
import 'package:food_app/features/restaurant_owner/data/owner_repository.dart';
import 'package:go_router/go_router.dart';

import '../helpers/fake_auth.dart';

Future<void> _images(WidgetTester t) => t.runAsync(() async {
  for (final e in find.byType(Image).evaluate()) {
    await precacheImage((e.widget as Image).image, e);
  }
});

void main() {
  setUpAll(loadFonts);

  for (final (lang, dark) in [('fr', false), ('ar', false), ('fr', true)]) {
    final tag = '$lang${dark ? '_dark' : ''}';
    testWidgets('owner qr $tag', (t) async {
      final owner = FakeOwnerRepository()
        ..restaurant = const OwnedRestaurant(
          id: 'own1',
          slug: 'pizzeria-el-bahdja',
          name: 'Pizzeria El Bahdja',
          area: 'Kouba',
          isActive: true,
          isOpen: true,
        );
      final qr = FakeQrRepository()
        ..statsValue = const QrStats(
          total: 57,
          last30: 41,
          app: 20,
          web: 37,
          people: 33,
          ordersAfter: 12,
        );
      final auth = FakeAuthRepository()
        ..seedUser('o@mail.dz', 'secret123', name: 'Omar')
        ..roles['o@mail.dz'] = 'restaurant'
        ..signInDirect('o@mail.dz');
      await pumpFoodApp(
        t,
        repo: auth,
        owner: owner,
        qr: qr,
        lang: lang,
        dark: dark,
        size: const Size(390, 1250),
      );
      GoRouter.of(t.element(find.byType(Scaffold).first)).go('/restaurant/qr');
      await t.pumpAndSettle();
      await _images(t);
      await t.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('qr_owner_$tag.png'),
      );
    });
  }

  testWidgets('scan page fr', (t) async {
    final auth = FakeAuthRepository()
      ..seedUser('k@mail.dz', 'secret123', name: 'Karim')
      ..signInDirect('k@mail.dz');
    await pumpFoodApp(t, repo: auth);
    GoRouter.of(t.element(find.byType(Scaffold).first)).go('/home');
    await t.pumpAndSettle();
    await _images(t);
    await t.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('qr_home_fr.png'),
    );
    await t.tap(find.byKey(const Key('scan-qr')));
    await t.pumpAndSettle();
    await _images(t);
    await t.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('qr_scan_fr.png'),
    );
  });
}
