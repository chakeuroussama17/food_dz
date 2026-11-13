// Restaurant side v2 (dashboard, orders table, insights, account) with a
// month of sample orders, light / dark, French / Arabic.
// Run: flutter test test/screenshots/restaurant_v2_screenshot_test.dart --update-goldens --tags screenshot --run-skipped
@Tags(['screenshot'])
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_app/features/catalog/data/catalog_models.dart';
import 'package:food_app/features/restaurant_owner/data/owner_orders_repository.dart';
import 'package:food_app/features/restaurant_owner/data/owner_repository.dart';
import 'package:go_router/go_router.dart';

import '../helpers/fake_auth.dart';

const _dishes = [
  ('Pizza Margherita', 700),
  ('Pizza Thon', 900),
  ('Burger maison', 850),
  ('Tacos poulet', 600),
  ('Chawarma', 450),
];

List<OwnerOrder> sampleOrders() {
  final rnd = Random(7);
  final now = DateTime.now();
  final list = <OwnerOrder>[];
  var n = 0;
  for (var d = 0; d < 40; d++) {
    final count = 3 + rnd.nextInt(d % 7 == 3 ? 3 : 8);
    for (var k = 0; k < count; k++) {
      final hour = [12, 12, 13, 13, 13, 19, 20, 20, 21][rnd.nextInt(9)];
      final at = DateTime(
        now.year,
        now.month,
        now.day - d,
        hour,
        rnd.nextInt(60),
      );
      if (at.isAfter(now)) continue;
      final dish = _dishes[min(rnd.nextInt(6), 4)];
      final q = 1 + rnd.nextInt(3);
      final food = dish.$2 * q;
      final r = rnd.nextInt(20);
      final status = d == 0 && k == 0
          ? 'placed'
          : r == 0
          ? 'rejected'
          : r == 1
          ? 'cancelled'
          : 'delivered';
      final acc = status == 'rejected'
          ? null
          : at.add(Duration(minutes: 1 + rnd.nextInt(4)));
      n++;
      list.add(
        OwnerOrder(
          id: 's$n',
          code: 'K${(4000 + n).toRadixString(36).toUpperCase()}',
          status: status,
          customerName: ['Amina', 'Bilal', 'Sofia', 'Yacine', 'Lina'][n % 5],
          customerPhone: '',
          addressText: '',
          area: ['Kouba', 'Hydra', 'Bab Ezzouar'][n % 3],
          foodTotal: food,
          deliveryFee: 200,
          total: food + 200,
          placedAt: at,
          acceptedAt: acc,
          readyAt: acc?.add(Duration(minutes: 15 + rnd.nextInt(15))),
          commissionAmount: status == 'delivered' ? (food * .08).round() : null,
          rejectReason: status == 'rejected' ? 'no_answer' : null,
          driverName: status == 'delivered' ? 'Rachid' : null,
          items: [
            OrderLine(
              name: dish.$1,
              unitPrice: dish.$2,
              quantity: q,
              lineTotal: food,
            ),
          ],
        ),
      );
    }
  }
  return list;
}

void main() {
  setUpAll(loadFonts);

  const pages = {
    'dashboard': '/restaurant',
    'table': '/restaurant/orders/table',
    'insights': '/restaurant/insights',
    'account': '/restaurant/account',
  };

  for (final (lang, dark) in [('fr', false), ('ar', false), ('fr', true)]) {
    for (final e in pages.entries) {
      final tag = '${e.key}_$lang${dark ? '_dark' : ''}';
      testWidgets(tag, (t) async {
        final auth = FakeAuthRepository()
          ..seedUser('o@mail.dz', 'secret123')
          ..roles['o@mail.dz'] = 'restaurant'
          ..signInDirect('o@mail.dz');
        final owner = FakeOwnerRepository()
          ..restaurant = const OwnedRestaurant(
            id: 'own1',
            slug: 'chez-omar',
            name: 'Pizzeria El Bahdja',
            area: 'Kouba',
            isActive: true,
            isOpen: true,
          )
          ..dishes.addAll(const [
            MenuItem(
              id: 'm1',
              restaurantId: 'own1',
              name: 'Burger maison',
              price: 850,
            ),
            MenuItem(
              id: 'm2',
              restaurantId: 'own1',
              name: 'Pizza Thon',
              price: 900,
              isAvailable: false,
            ),
          ]);
        final orders = FakeOwnerOrdersRepository()
          ..reportOrders.addAll(sampleOrders());
        await pumpFoodApp(
          t,
          repo: auth,
          owner: owner,
          ownerOrders: orders,
          lang: lang,
          dark: dark,
          size: const Size(390, 1400),
        );
        GoRouter.of(t.element(find.byType(Scaffold).first)).go(e.value);
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('r2_$tag.png'),
        );
      });
    }
  }
}
