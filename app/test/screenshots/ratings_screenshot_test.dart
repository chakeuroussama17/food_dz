// Rating screens: sheet, order page, restaurant reviews, portal, admin.
// Run: flutter test test/screenshots/ratings_screenshot_test.dart --update-goldens --tags screenshot --run-skipped
@Tags(['screenshot'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_app/features/orders/data/orders_repository.dart';
import 'package:food_app/features/ratings/ratings_repository.dart';
import 'package:food_app/features/restaurant_owner/data/owner_repository.dart';
import 'package:go_router/go_router.dart';

import '../checkout_flow_test.dart' show Setup;
import '../helpers/fake_auth.dart';

DateTime ago({int days = 0, int hours = 0}) =>
    DateTime.now().subtract(Duration(days: days, hours: hours));

Future<void> go(WidgetTester t, String path) async {
  GoRouter.of(t.element(find.byType(Scaffold).first)).go(path);
  await t.pumpAndSettle();
}

CustomerOrder delivered() => CustomerOrder(
  id: 'o1',
  code: 'K7P2Q1',
  status: 'delivered',
  restaurantId: 'r1',
  restaurantName: 'Pizzeria El Bahdja',
  addressText: 'Rue Didouche 12',
  customerPhone: '0550123456',
  foodTotal: 1400,
  deliveryFee: 200,
  total: 1600,
  placedAt: ago(hours: 2),
  deliveredAt: ago(hours: 0),
  driverName: 'Rachid',
  items: const [
    OrderLine(
      name: 'Pizza Margherita',
      unitPrice: 700,
      quantity: 2,
      lineTotal: 1400,
    ),
  ],
);

void main() {
  setUpAll(loadFonts);

  for (final (lang, dark) in [('fr', false), ('ar', false), ('fr', true)]) {
    final tag = '$lang${dark ? '_dark' : ''}';

    Future<(Setup, FakeRatingsRepository)> customer(WidgetTester t) async {
      final s = Setup();
      final ratings = FakeRatingsRepository();
      s.catalog.restaurantsList[0] = s.catalog.restaurantsList[0].withStatus(
        open: true,
        ratingAvg: 4.6,
        ratingCount: 128,
      );
      ratings.reviewsBySlug['pizzeria-el-bahdja'] = [
        Review(
          customerLabel: 'Amina B.',
          stars: 5,
          comment: 'Excellente pizza, livrée chaude et à l’heure !',
          ratedAt: ago(days: 1),
          reply: 'Merci Amina, à très bientôt !',
        ),
        Review(
          customerLabel: 'Bilal K.',
          stars: 2,
          reasons: const ['cold', 'small_portion'],
          comment: 'Froide à l’arrivée.',
          ratedAt: ago(days: 3),
        ),
      ];
      final o = delivered();
      s.orders.orders.add(o);
      ratings.addDelivered('o1', deliveredAt: o.deliveredAt);
      final auth = FakeAuthRepository()
        ..seedUser('k@mail.dz', 'secret123')
        ..signInDirect('k@mail.dz');
      await pumpFoodApp(
        t,
        repo: auth,
        lang: lang,
        dark: dark,
        catalog: s.catalog,
        account: s.account,
        orders: s.orders,
        ratings: ratings,
        size: const Size(390, 1500),
      );
      return (s, ratings);
    }

    testWidgets('sheet $tag', (t) async {
      await customer(t);
      await go(t, '/orders/o1'); // the delivery pop-up opens by itself
      expect(t.takeException(), isNull);
      await t.tap(find.byIcon(Icons.star_outline_rounded).at(1));
      await t.pumpAndSettle();
      await t.tap(find.byType(FilterChip).first);
      await t.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('rt_sheet_$tag.png'),
      );
    });

    testWidgets('order $tag', (t) async {
      final (_, ratings) = await customer(t);
      ratings.ratings['o1'] = OrderRating(
        orderId: 'o1',
        deliveredAt: ago(hours: 3),
        driverStars: 4,
        driverRatedAt: ago(hours: 2),
        foodStars: 5,
        foodRatedAt: ago(hours: 1),
        reply: 'Merci pour votre commande !',
      );
      await go(t, '/orders/o1');
      await t.drag(find.byType(Scrollable).first, const Offset(0, -600));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('rt_order_$tag.png'),
      );
    });

    testWidgets('restaurant $tag', (t) async {
      await customer(t);
      await go(t, '/r/pizzeria-el-bahdja');
      await t.drag(find.byType(Scrollable).first, const Offset(0, -700));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('rt_restaurant_$tag.png'),
      );
    });

    testWidgets('portal reviews $tag', (t) async {
      OwnerReview r(
        String id,
        int stars, {
        List<String> reasons = const [],
        String c = '',
        int d = 2,
        String? reply,
      }) => OwnerReview(
        orderId: id,
        code: id.toUpperCase(),
        restaurantId: 'own1',
        restaurantName: 'Pizzeria El Bahdja',
        customerLabel: [
          'Amina B.',
          'Bilal K.',
          'Sofia M.',
          'Yacine T.',
        ][id.hashCode % 4],
        stars: stars,
        ratedAt: ago(days: d),
        reasons: reasons,
        comment: c,
        reply: reply,
        items: '2× Pizza Margherita, 1× Burger maison',
        total: 2450,
      );
      final ratings = FakeRatingsRepository()
        ..owner.addAll([
          r(
            'k7p2',
            5,
            c: 'Excellente pizza, livrée chaude !',
            d: 1,
            reply: 'Merci beaucoup !',
          ),
          r('k7p3', 5, c: 'Très bon, rapide.', d: 2),
          r('k7p4', 4, d: 3),
          r(
            'k7p5',
            2,
            reasons: ['cold', 'small_portion'],
            c: 'Froide à l’arrivée, portion petite.',
            d: 4,
          ),
          r('k7p6', 5, d: 6),
          r(
            'k7p7',
            1,
            reasons: ['missing_item', 'wrong_order'],
            c: 'Il manquait le burger.',
            d: 9,
          ),
          r('k7p8', 4, d: 12),
          r('k7p9', 5, d: 20),
          r('k7pa', 3, reasons: ['bad_taste'], d: 38),
        ]);
      final auth = FakeAuthRepository()
        ..seedUser('o@mail.dz', 'secret123', name: 'Omar')
        ..roles['o@mail.dz'] = 'restaurant'
        ..signInDirect('o@mail.dz');
      final owner = FakeOwnerRepository()
        ..restaurant = const OwnedRestaurant(
          id: 'own1',
          slug: 'x',
          name: 'Pizzeria El Bahdja',
          isActive: true,
          isOpen: true,
        );
      await pumpFoodApp(
        t,
        repo: auth,
        owner: owner,
        ratings: ratings,
        lang: lang,
        dark: dark,
        portal: true,
        size: const Size(1440, 1500),
      );
      await go(t, '/reviews');
      expect(t.takeException(), isNull);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('rt_portal_$tag.png'),
      );
    });
  }

  testWidgets('admin fr', (t) async {
    final ratings = FakeRatingsRepository()
      ..flagged.add(
        FlaggedReview(
          orderId: 'f1',
          code: 'F1',
          restaurantName: 'Pizzeria El Bahdja',
          customerLabel: 'Amina B.',
          stars: 1,
          ratedAt: ago(days: 2),
          flaggedAt: ago(days: 1),
          comment: 'Le livreur était impoli et en retard.',
          flagReason: 'Parle de la livraison, pas de la cuisine',
        ),
      )
      ..reports.add(
        CustomerReport(
          id: 7,
          orderCode: 'R7',
          reporterRole: 'driver',
          reporterName: 'Rachid',
          restaurantName: 'Pizzeria El Bahdja',
          customerId: 'c1',
          customerName: 'Chakib H.',
          customerPhone: '0550123456',
          reason: 'no_answer',
          note: 'Téléphone éteint',
          createdAt: ago(hours: 3),
          customerReportsTotal: 3,
        ),
      );
    final auth = FakeAuthRepository()
      ..seedUser('a@mail.dz', 'secret123', name: 'Admin')
      ..roles['a@mail.dz'] = 'admin'
      ..signInDirect('a@mail.dz');
    await pumpFoodApp(
      t,
      repo: auth,
      ratings: ratings,
      lang: 'fr',
      size: const Size(1100, 800),
    );
    await go(t, '/admin/ratings');
    expect(t.takeException(), isNull);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('rt_admin_fr.png'),
    );
  });
}
