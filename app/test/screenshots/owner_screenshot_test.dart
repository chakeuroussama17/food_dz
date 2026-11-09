// Renders the restaurant-owner pages (real fonts) for visual review.
// Run: flutter test test/screenshots --update-goldens --tags screenshot --run-skipped
@Tags(['screenshot'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_app/features/catalog/data/catalog_models.dart';
import 'package:food_app/features/restaurant_owner/data/owner_repository.dart';
import 'package:go_router/go_router.dart';

import '../helpers/fake_auth.dart';

void main() {
  setUpAll(loadFonts);

  const pages = {
    'dashboard': '/restaurant',
    'menu': '/restaurant/menu',
    'item_new': '/restaurant/menu/new',
    'profile': '/restaurant/profile',
  };

  for (final lang in ['fr', 'ar']) {
    testWidgets('register $lang', (t) async {
      await pumpFoodApp(t, lang: lang);
      GoRouter.of(
        t.element(find.byType(Scaffold).first),
      ).go('/restaurant/register');
      await t.pump(const Duration(milliseconds: 600));
      expect(t.takeException(), isNull);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('o_register_$lang.png'),
      );
    });

    for (final e in pages.entries) {
      testWidgets('${e.key} $lang', (t) async {
        final auth = FakeAuthRepository()
          ..seedUser('o@mail.dz', 'secret123')
          ..roles['o@mail.dz'] = 'restaurant'
          ..signInDirect('o@mail.dz');
        final owner = FakeOwnerRepository()
          ..restaurant = const OwnedRestaurant(
            id: 'own1',
            slug: 'chez-omar',
            name: 'Chez Omar',
            area: 'Kouba',
            phone: '0550111222',
            address: 'Rue Didouche Mourad',
          )
          ..dishes.addAll(const [
            MenuItem(
              id: 'm1',
              restaurantId: 'own1',
              categoryId: 'c-burger',
              name: 'Burger maison',
              price: 850,
            ),
            MenuItem(
              id: 'm2',
              restaurantId: 'own1',
              categoryId: 'c-pizza',
              name: 'Pizza Thon',
              price: 900,
              isAvailable: false,
            ),
          ]);
        await pumpFoodApp(t, repo: auth, owner: owner, lang: lang);
        GoRouter.of(t.element(find.byType(Scaffold).first)).go(e.value);
        await t.pump(const Duration(milliseconds: 600));
        await t.pump(const Duration(milliseconds: 600));
        expect(t.takeException(), isNull);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('o_${e.key}_$lang.png'),
        );
      });
    }
  }
}
