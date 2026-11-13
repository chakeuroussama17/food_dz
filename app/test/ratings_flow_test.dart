import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_app/features/admin/pages/admin_ratings_page.dart';
import 'package:food_app/features/driver/data/driver_repository.dart';
import 'package:food_app/features/driver/pages/driver_order_page.dart';
import 'package:food_app/features/orders/data/orders_repository.dart'
    show CheckoutFailure;
import 'package:food_app/features/ratings/ratings_repository.dart';
import 'package:food_app/features/restaurant_owner/data/owner_repository.dart';
import 'package:food_app/portal/pages/portal_reviews_page.dart';
import 'package:go_router/go_router.dart';

import 'checkout_flow_test.dart' show Setup, fillCartAndOpen, signedIn, tap;
import 'driver_flow_test.dart' show DriverSetup;
import 'helpers/fake_auth.dart';

final _now = DateTime.now();
DateTime ago({int days = 0, int hours = 0}) =>
    _now.subtract(Duration(days: days, hours: hours));

final vertical = find
    .byWidgetPredicate(
      (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
    )
    .first;

/// A customer who placed order "o1" and is on its tracking page.
Future<(Setup, FakeRatingsRepository)> onTrackingPage(WidgetTester t) async {
  final s = Setup();
  final ratings = FakeRatingsRepository();
  await signedIn(t, s, ratings: ratings);
  await fillCartAndOpen(t);
  await tap(t, find.textContaining('PLACE ORDER'));
  await tap(t, find.text('TRACK ORDER'));
  return (s, ratings);
}

/// The order page is a long list: bring [f] on screen.
Future<void> reveal(WidgetTester t, Finder f) =>
    t.scrollUntilVisible(f, 300, scrollable: vertical);

Future<void> go(WidgetTester t, String path) async {
  GoRouter.of(t.element(find.byType(Scaffold).first)).go(path);
  await t.pumpAndSettle();
}

void main() {
  setUpAll(loadFonts);

  group('customer', () {
    testWidgets('delivery pop-up appears live and sends the driver rating', (
      t,
    ) async {
      final (s, ratings) = await onTrackingPage(t);
      expect(find.text('How was the delivery?'), findsNothing);

      // The driver hands over the food: the customer's page reacts.
      ratings.addDelivered('o1');
      s.orders.deliver('o1');
      await t.pumpAndSettle();
      expect(find.text('How was the delivery?'), findsOneWidget);
      expect(find.text('Rachid'), findsWidgets);

      await t.tap(find.byIcon(Icons.star_outline_rounded).at(1)); // 2 stars
      await t.pumpAndSettle();
      expect(find.text('What went wrong?'), findsOneWidget);
      await t.tap(find.text('Late'));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField), 'Slow');
      await tap(t, find.text('SEND MY RATING'));

      expect(ratings.calls.single, 'rate:o1:driver:2:late:Slow');
      expect(find.text('How was the delivery?'), findsNothing);
      await reveal(t, find.text('Your rating'));
      expect(find.text('Your rating'), findsOneWidget);
      // The food can be rated for 7 days.
      await reveal(t, find.text('Rate the food'));
      expect(find.text('Rate the food'), findsOneWidget);
      expect(find.text('7 days left to rate'), findsOneWidget);
    });

    testWidgets('"Later" sends nothing; the cards keep the Rate buttons', (
      t,
    ) async {
      final (s, ratings) = await onTrackingPage(t);
      ratings.addDelivered('o1');
      s.orders.deliver('o1');
      await t.pumpAndSettle();
      await tap(t, find.text('Later'));
      expect(ratings.calls, isEmpty);
      expect(find.text('How was the delivery?'), findsNothing);
      await reveal(t, find.text('Rate the delivery'));
      expect(find.text('Rate the delivery'), findsOneWidget);
      expect(find.text('Rate the food'), findsOneWidget);

      // Rate the food later from its card; good ratings keep no reasons.
      await tap(t, find.text('Rate').last);
      expect(find.text('How was the food?'), findsOneWidget);
      await t.tap(find.byIcon(Icons.star_outline_rounded).at(4));
      await t.pumpAndSettle();
      expect(find.text('What went wrong?'), findsNothing);
      await tap(t, find.text('SEND MY RATING'));
      expect(ratings.calls.single, 'rate:o1:food:5::');
      expect(find.text('Excellent'), findsNothing);
    });

    testWidgets('24 h to change a rating, 7 days to give it', (t) async {
      final (s, ratings) = await onTrackingPage(t);
      // Food rated 25 h ago (locked), delivery rated 1 h ago (editable).
      ratings.ratings['o1'] = OrderRating(
        orderId: 'o1',
        deliveredAt: ago(days: 2),
        foodStars: 4,
        foodRatedAt: ago(hours: 25),
        driverStars: 5,
        driverRatedAt: ago(hours: 1),
        reply: 'Merci !',
      );
      s.orders.deliver('o1');
      await t.pumpAndSettle();
      expect(find.text('How was the delivery?'), findsNothing); // already rated
      await reveal(t, find.text('Edit'));
      expect(find.text('Your rating'), findsNWidgets(2));
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Restaurant reply'), findsOneWidget);
      expect(find.text('Merci !'), findsOneWidget);
    });

    testWidgets('after 7 days there is nothing left to rate', (t) async {
      final (s, ratings) = await onTrackingPage(t);
      ratings.addDelivered('o1', deliveredAt: ago(days: 8));
      s.orders.deliver('o1');
      await t.pumpAndSettle();
      expect(find.text('How was the delivery?'), findsNothing);
      await reveal(t, find.text('Download receipt'));
      expect(find.text('Rate the food'), findsNothing);
      expect(find.text('Rate the delivery'), findsNothing);
    });

    testWidgets('My orders shows a Rate button only while something is open', (
      t,
    ) async {
      final (s, ratings) = await onTrackingPage(t);
      ratings.addDelivered('o1');
      s.orders.deliver('o1');
      await t.pumpAndSettle();
      await tap(t, find.text('Later'));
      await go(t, '/orders');
      await t.tap(find.text('History'));
      await t.pumpAndSettle();
      expect(find.text('Rate'), findsOneWidget);

      await t.tap(find.text('Rate'));
      await t.pumpAndSettle();
      // Opens the order page; once everything is rated the button is gone.
      await ratings.rate('o1', 'driver', 5);
      await ratings.rate('o1', 'food', 5);
    });

    testWidgets('a blocked account sees a clear message', (t) async {
      final s = Setup();
      await signedIn(t, s);
      await fillCartAndOpen(t);
      s.orders.failNext = CheckoutFailure.accountBlocked;
      await tap(t, find.textContaining('PLACE ORDER'));
      expect(
        find.text('Your account is suspended. Please contact support.'),
        findsOneWidget,
      );
    });

    testWidgets('restaurant page: rating, "New" and public reviews', (t) async {
      final s = Setup();
      final ratings = FakeRatingsRepository();
      s.catalog.restaurantsList[0] = s.catalog.restaurantsList[0].withStatus(
        open: true,
        ratingAvg: 4.6,
        ratingCount: 12,
      );
      ratings.reviewsBySlug['pizzeria-el-bahdja'] = [
        Review(
          customerLabel: 'Amina B.',
          stars: 5,
          comment: 'Excellente pizza',
          ratedAt: ago(days: 1),
          reply: 'Merci Amina !',
        ),
        Review(
          customerLabel: 'Bilal',
          stars: 2,
          reasons: const ['cold'],
          ratedAt: ago(days: 3),
        ),
      ];
      await signedIn(t, s, ratings: ratings);
      await go(t, '/r/pizzeria-el-bahdja');
      expect(find.text('4.6'), findsOneWidget);
      expect(find.text(' (12)'), findsOneWidget);
      await t.scrollUntilVisible(
        find.text('Reviews'),
        300,
        scrollable: vertical,
      );
      expect(find.text('12 ratings'), findsOneWidget);
      expect(find.text('Amina B.'), findsOneWidget);
      expect(find.text('Excellente pizza'), findsOneWidget);
      expect(find.text('Reply from the restaurant'), findsOneWidget);
      expect(find.text('Merci Amina !'), findsOneWidget);
      expect(find.text('Cold food'), findsOneWidget);

      // A restaurant with few ratings is "New", with no reviews yet.
      await go(t, '/r/burger-house-hydra');
      expect(find.text('New'), findsOneWidget);
      await t.scrollUntilVisible(
        find.text('No reviews yet'),
        300,
        scrollable: vertical,
      );
    });
  });

  group('portal: ratings and reviews', () {
    OwnerReview review(
      String id,
      int stars, {
      List<String> reasons = const [],
      String comment = '',
      int days = 2,
      String? reply,
      String outlet = 'own1',
    }) => OwnerReview(
      orderId: id,
      code: id.toUpperCase(),
      restaurantId: outlet,
      restaurantName: outlet == 'own1' ? 'Chez Omar' : 'Chez Omar Hydra',
      customerLabel: 'Client $id',
      stars: stars,
      ratedAt: ago(days: days),
      reasons: reasons,
      comment: comment,
      reply: reply,
      items: 'Pizza Margherita',
      total: 1600,
    );

    Future<FakeRatingsRepository> portalReviews(WidgetTester t) async {
      final ratings = FakeRatingsRepository()
        ..owner.addAll([
          review('a1', 5, comment: 'Parfait'),
          review('a2', 5, reply: 'Merci !'),
          review('a3', 4),
          review(
            'a4',
            2,
            reasons: ['cold', 'small_portion'],
            comment: 'Froide',
          ),
          review('a5', 1, reasons: ['cold']),
          review('old', 3, days: 40), // previous period
        ]);
      final auth = FakeAuthRepository()
        ..seedUser('o@mail.dz', 'secret123', name: 'Omar')
        ..roles['o@mail.dz'] = 'restaurant'
        ..signInDirect('o@mail.dz');
      final owner = FakeOwnerRepository()
        ..restaurant = const OwnedRestaurant(
          id: 'own1',
          slug: 'chez-omar',
          name: 'Chez Omar',
          isActive: true,
          isOpen: true,
        );
      await pumpFoodApp(
        t,
        repo: auth,
        owner: owner,
        ratings: ratings,
        portal: true,
        size: const Size(1440, 1200),
      );
      await go(t, '/reviews');
      return ratings;
    }

    testWidgets('summary: average, distribution, top complaints', (t) async {
      await portalReviews(t);
      expect(find.byType(PortalReviewsPage), findsOneWidget);
      expect(find.text('3.4'), findsOneWidget); // (5+5+4+2+1) / 5
      expect(find.text('5 ratings'), findsOneWidget);
      expect(find.text('Most common complaints'), findsOneWidget);
      expect(find.text('Cold food'), findsWidgets);
      expect(find.text('Parfait'), findsOneWidget);
      expect(find.text('Froide'), findsOneWidget);
      // Last 7 days: the old one is outside, so still 5.
      await t.tap(find.text('7 days'));
      await t.pumpAndSettle();
      expect(find.text('5 ratings'), findsOneWidget);
    });

    testWidgets('filter by stars and by "no reply yet"', (t) async {
      await portalReviews(t);
      await t.tap(find.text('1 stars'));
      await t.pumpAndSettle();
      expect(find.text('Client a5'), findsOneWidget);
      expect(find.text('Client a1'), findsNothing);
      await t.tap(find.text('All').first);
      await t.pumpAndSettle();
      await t.tap(find.text('No reply yet'));
      await t.pumpAndSettle();
      expect(find.text('Client a2'), findsNothing); // has a reply
      expect(find.text('Client a1'), findsOneWidget);
    });

    testWidgets('reply once; report a review to the admin', (t) async {
      final ratings = await portalReviews(t);
      await t.tap(find.text('Reply').first);
      await t.pumpAndSettle();
      expect(find.textContaining('cannot be edited'), findsOneWidget);
      await t.enterText(find.byType(TextField).last, 'Merci pour votre avis');
      await t.pumpAndSettle();
      await t.tap(find.text('Publish reply'));
      await t.pumpAndSettle();
      expect(ratings.calls.single, 'reply:a1:Merci pour votre avis');
      expect(find.text('Merci pour votre avis'), findsOneWidget);

      await t.tap(find.text('Report this review').first);
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField).last, 'Insulte');
      await t.pumpAndSettle();
      await t.tap(find.text('Send'));
      await t.pumpAndSettle();
      expect(ratings.calls.last, startsWith('flag:'));
      expect(find.text('Waiting for the admin'), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  });

  group('reports about customers', () {
    testWidgets('driver reports a customer once', (t) async {
      final s = DriverSetup();
      final ratings = FakeRatingsRepository();
      final auth = FakeAuthRepository()
        ..seedUser('d@mail.dz', 'secret123', name: 'Rachid')
        ..roles['d@mail.dz'] = 'driver'
        ..signInDirect('d@mail.dz');
      s.driver.seedDriver(online: true);
      s.driver.mine.add(s.driver.makeOrder('d1', status: 'picked_up'));
      await pumpFoodApp(t, repo: auth, driver: s.driver, ratings: ratings);
      await go(t, '/driver/orders/d1');
      expect(find.byType(DriverOrderPage), findsOneWidget);

      await tap(t, find.text('Report this customer'));
      expect(
        find.text('Only the admin sees this. The customer is not told.'),
        findsOneWidget,
      );
      await t.tap(find.text('Does not answer'));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField).last, 'Phone off');
      await t.tap(find.text('Send'));
      await t.pumpAndSettle();
      expect(ratings.calls.single, 'report:d1:no_answer:Phone off');
      expect(find.text('Reported'), findsOneWidget);
    });

    testWidgets('driver sees the rating summary on the profile', (t) async {
      final s = DriverSetup();
      final ratings = FakeRatingsRepository()
        ..driver = const DriverRatingSummary(
          average: 4.2,
          count: 8,
          reasons: {'late': 3, 'rude': 1},
        );
      final auth = FakeAuthRepository()
        ..seedUser('d@mail.dz', 'secret123', name: 'Rachid')
        ..roles['d@mail.dz'] = 'driver'
        ..signInDirect('d@mail.dz');
      await pumpFoodApp(t, repo: auth, driver: s.driver, ratings: ratings);
      s.driver.statsValue = const DriverStats(
        average: 4.2,
        count: 8,
        stars: {5: 4, 4: 2, 3: 1, 2: 1},
      );
      await go(t, '/driver/account/rating');
      expect(find.text('My rating'), findsOneWidget);
      expect(find.text('4.2'), findsWidgets);
      expect(find.text('8 ratings'), findsWidgets);
      expect(find.text('Late'), findsWidgets); // what customers mentioned
      expect(find.text('Rude'), findsWidgets);
    });

    testWidgets('before 5 ratings the driver sees no average', (t) async {
      final s = DriverSetup();
      final ratings = FakeRatingsRepository()
        ..driver = const DriverRatingSummary(count: 3);
      final auth = FakeAuthRepository()
        ..seedUser('d@mail.dz', 'secret123')
        ..roles['d@mail.dz'] = 'driver'
        ..signInDirect('d@mail.dz');
      s.driver.statsValue = const DriverStats(count: 3, stars: {5: 3});
      await pumpFoodApp(t, repo: auth, driver: s.driver, ratings: ratings);
      await go(t, '/driver/account');
      expect(
        find.text('Your average appears after 5 ratings.'),
        findsOneWidget,
      );
    });
  });

  group('admin', () {
    Future<FakeRatingsRepository> adminApp(WidgetTester t) async {
      final ratings = FakeRatingsRepository()
        ..flagged.add(
          FlaggedReview(
            orderId: 'f1',
            code: 'F1',
            restaurantName: 'Chez Omar',
            customerLabel: 'Amina B.',
            stars: 1,
            ratedAt: ago(days: 2),
            flaggedAt: ago(days: 1),
            comment: 'Livreur impoli',
            flagReason: 'Parle de la livraison, pas de la cuisine',
          ),
        )
        ..reports.add(
          CustomerReport(
            id: 7,
            orderCode: 'R7',
            reporterRole: 'driver',
            reporterName: 'Rachid',
            restaurantName: 'Chez Omar',
            customerId: 'cust1',
            customerName: 'Chakib H.',
            customerPhone: '0550123456',
            reason: 'no_answer',
            note: 'Ne répond pas',
            createdAt: ago(hours: 3),
            customerReportsTotal: 3,
          ),
        )
        ..adminDriverList.add(
          const AdminDriverRating(
            driverId: 'd1',
            name: 'Rachid',
            ratedCount: 9,
            average: 3.1,
            average30d: 2.8,
            low30d: 4,
            reasons: {'late': 5},
          ),
        )
        ..adminRestaurantList.add(
          const AdminRestaurantRating(
            restaurantId: 'r1',
            name: 'Chez Omar',
            ratedCount: 40,
            average: 4.4,
            flaggedPending: 1,
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
        size: const Size(1100, 1000),
      );
      await go(t, '/admin/ratings');
      return ratings;
    }

    testWidgets('flagged reviews: hide or keep', (t) async {
      final ratings = await adminApp(t);
      expect(find.byType(AdminRatingsPage), findsOneWidget);
      expect(find.text('Flagged reviews (1)'), findsOneWidget);
      expect(find.text('Livreur impoli'), findsOneWidget);
      expect(
        find.textContaining('Parle de la livraison, pas de la cuisine'),
        findsOneWidget,
      );
      await t.tap(find.text('Hide'));
      await t.pumpAndSettle();
      expect(ratings.calls.single, 'decision:f1:hide');
      expect(find.text('Hidden'), findsOneWidget);
    });

    testWidgets('customer reports: warn, block, dismiss', (t) async {
      final ratings = await adminApp(t);
      await t.tap(find.textContaining('Customer reports'));
      await t.pumpAndSettle();
      expect(find.text('Chakib H. · 0550123456'), findsOneWidget);
      expect(find.text('Does not answer'), findsOneWidget);
      expect(find.text('3 reports about this customer'), findsOneWidget);

      await t.tap(find.text('Warn'));
      await t.pumpAndSettle();
      expect(ratings.calls.last, 'handle:7:warned');
      expect(find.text('Warned'), findsOneWidget);

      await t.tap(find.text('Block customer'));
      await t.pumpAndSettle();
      expect(ratings.calls.last, 'handle:7:blocked');
      expect(find.text('Customer blocked: cannot order'), findsOneWidget);

      await t.tap(find.text('Unblock'));
      await t.pumpAndSettle();
      expect(ratings.calls.last, 'block:cust1:false');
    });

    testWidgets('drivers and restaurants with their averages', (t) async {
      await adminApp(t);
      await t.tap(find.text('Drivers').last);
      await t.pumpAndSettle();
      expect(find.text('Rachid'), findsOneWidget);
      expect(find.text('3.1'), findsOneWidget);
      expect(find.textContaining('Late 5'), findsOneWidget);
      await t.tap(find.text('Restaurants').last);
      await t.pumpAndSettle();
      expect(find.text('Chez Omar'), findsOneWidget);
      expect(find.text('4.4'), findsOneWidget);
    });
  });
}
