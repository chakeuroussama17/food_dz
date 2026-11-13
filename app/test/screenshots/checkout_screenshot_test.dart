// Checkout page (promo applied, tax, payment methods) and admin promo codes.
// Run: flutter test test/screenshots/checkout_screenshot_test.dart --update-goldens --tags screenshot --run-skipped
@Tags(['screenshot'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_app/features/admin/data/promo_repository.dart';
import 'package:go_router/go_router.dart';

import '../checkout_flow_test.dart' show Setup, fillCartAndOpen, signedIn, tap;
import '../helpers/fake_auth.dart';

void main() {
  setUpAll(loadFonts);

  for (final (lang, dark) in [('fr', false), ('ar', false), ('fr', true)]) {
    final tag = '$lang${dark ? '_dark' : ''}';
    testWidgets('checkout $tag', (t) async {
      final s = Setup();
      s.catalog.taxRateValue = 0.01;
      s.orders
        ..taxRate = 0.01
        ..promos['BIENVENUE'] = ('percent', 10, 0);
      await signedIn(t, s, lang: lang, dark: dark, size: const Size(390, 1700));
      await fillCartAndOpen(t);
      await t.enterText(find.byType(TextField).first, 'bienvenue');
      await tap(t, find.byType(FilledButton).first);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('co_checkout_$tag.png'),
      );
    });
  }

  for (final (name, size) in [
    ('pc', const Size(1200, 800)),
    ('phone', const Size(390, 844)),
  ]) {
    testWidgets('admin promos $name', (t) async {
      final promos = FakePromoRepository()
        ..codes.addAll([
          PromoCode(
            id: 'p1',
            code: 'BIENVENUE',
            kind: 'percent',
            value: 20,
            maxDiscount: 400,
            minOrder: 1000,
            maxUses: 500,
            perCustomer: 1,
            uses: 128,
            discountGiven: 31250,
            endsAt: DateTime(2026, 12, 31),
            note: 'Lancement',
          ),
          const PromoCode(
            id: 'p2',
            code: 'PIZZA300',
            kind: 'amount',
            value: 300,
            minOrder: 2000,
            restaurantId: 'r1',
            restaurantName: 'Pizzeria El Bahdja',
            fundedBy: 'restaurant',
            uses: 12,
            discountGiven: 3600,
          ),
          const PromoCode(
            id: 'p3',
            code: 'RAMADAN',
            kind: 'percent',
            value: 15,
            isActive: false,
            uses: 40,
            discountGiven: 9800,
          ),
        ]);
      final auth = FakeAuthRepository()
        ..seedUser('a@mail.dz', 'secret123', name: 'Admin')
        ..roles['a@mail.dz'] = 'admin'
        ..signInDirect('a@mail.dz');
      await pumpFoodApp(t, repo: auth, promos: promos, lang: 'fr', size: size);
      GoRouter.of(t.element(find.byType(Scaffold).first)).go('/admin/promos');
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('co_admin_promos_$name.png'),
      );
      if (name == 'pc') {
        await tap(t, find.text('Nouveau code'));
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('co_admin_promo_form.png'),
        );
      }
    });
  }
}
