// Sign-up with wilaya, complete-profile sheet, cancel request, restaurant
// banner, suspended screen, warning, admin customers.
// Run: flutter test test/screenshots/v1_final_screenshot_test.dart --update-goldens --tags screenshot --run-skipped
@Tags(['screenshot'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_app/features/admin/data/admin_models.dart';
import 'package:food_app/features/sanctions/sanctions_repository.dart';
import 'package:go_router/go_router.dart';

import '../checkout_flow_test.dart' show Setup, fillCartAndOpen, placeOrder, signedIn, tap;
import '../helpers/fake_auth.dart';
import '../owner_orders_flow_test.dart' show OwnerSetup, ownerApp, openOrders;

Future<void> _images(WidgetTester t) async {
  await t.runAsync(() async {
    for (final e in find.byType(Image).evaluate()) {
      await precacheImage((e.widget as Image).image, e);
    }
  });
  await t.pumpAndSettle();
}

Future<void> go(WidgetTester t, String path) async {
  GoRouter.of(t.element(find.byType(Scaffold).first)).go(path);
  await t.pumpAndSettle();
}

Future<void> shot(WidgetTester t, String name) => expectLater(
  find.byType(MaterialApp),
  matchesGoldenFile('v1_$name.png'),
);

void main() {
  setUpAll(loadFonts);

  for (final lang in ['fr', 'ar']) {
    testWidgets('signup $lang', (t) async {
      await pumpFoodApp(t, lang: lang, size: const Size(390, 1250));
      await go(t, '/signup');
      await shot(t, 'signup_$lang');
    });

    testWidgets('complete profile $lang', (t) async {
      final account = FakeAccountRepository();
      account.profile = account.profile.copyWith(promptAnswered: false);
      final auth = FakeAuthRepository()
        ..seedUser('k@mail.dz', 'secret123', name: 'Karim')
        ..signInDirect('k@mail.dz');
      await pumpFoodApp(t, repo: auth, account: account, lang: lang);
      await go(t, '/home');
      await _images(t);
      await shot(t, 'profile_card_$lang');
      await t.tap(find.byKey(const Key('complete-profile')).last);
      await t.tap(find.byType(FilledButton).first);
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('choice:female')));
      await t.tap(find.byKey(const Key('choice:social')));
      await t.pumpAndSettle();
      await shot(t, 'profile_sheet_$lang');
    });

    testWidgets('cancel request $lang', (t) async {
      if (lang == 'ar') return; // the checkout test helpers are in English
      final s = await signedIn(t, Setup(), size: const Size(390, 1000));
      await fillCartAndOpen(t);
      await tap(t, placeOrder);
      s.orders.setStatus('o1', 'accepted');
      await go(t, '/orders/o1');
      await t.scrollUntilVisible(find.byKey(const Key('cancel-order')), 200,
          scrollable: find.byType(Scrollable).first);
      await t.tap(find.byKey(const Key('cancel-order')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('reason:too_long')));
      await t.pumpAndSettle();
      await shot(t, 'cancel_sheet_$lang');
      await t.tap(find.byKey(const Key('confirm-cancel')));
      await t.pump(const Duration(seconds: 5));
      await t.pumpAndSettle();
      await t.scrollUntilVisible(find.byKey(const Key('cancel-note')), -200,
          scrollable: find.byType(Scrollable).first);
      await shot(t, 'cancel_pending_$lang');
    });

    testWidgets('restaurant request $lang', (t) async {
      final s = OwnerSetup();
      final o = s.orders.addIncoming();
      await ownerApp(t, setup: s);
      if (lang == 'ar') return; // the owner test app is in English
      await openOrders(t);
      s.orders.setStatus(o.id, 'accepted');
      s.orders.customerAsksCancel(o.id, reason: 'wrong_address', note: 'Mauvais bâtiment');
      await t.pumpAndSettle();
      await t.tap(find.text('In progress (1)'));
      await t.pumpAndSettle();
      await shot(t, 'owner_request_en');
    });

    testWidgets('suspended $lang', (t) async {
      final sanctions = FakeSanctionsRepository()
        ..current = Sanction(
          id: 3,
          kind: 'suspension',
          reason: 'fake_orders',
          message: lang == 'ar'
              ? 'ثلاث طلبات وهمية هذا الأسبوع.'
              : 'Trois fausses commandes cette semaine.',
          endsAt: DateTime(2026, 12, 1, 18, 30),
        );
      final auth = FakeAuthRepository()
        ..seedUser('k@mail.dz', 'secret123', name: 'Karim')
        ..signInDirect('k@mail.dz');
      await pumpFoodApp(t, repo: auth, sanctions: sanctions, lang: lang);
      await _images(t);
      await shot(t, 'suspended_$lang');
    });
  }

  testWidgets('warning fr', (t) async {
    final sanctions = FakeSanctionsRepository()
      ..current = const Sanction(
        id: 9,
        kind: 'warning',
        reason: 'too_many_cancellations',
        message: 'Merci de ne commander que si vous êtes disponible.',
      );
    final auth = FakeAuthRepository()
      ..seedUser('k@mail.dz', 'secret123', name: 'Karim')
      ..signInDirect('k@mail.dz');
    await pumpFoodApp(t, repo: auth, sanctions: sanctions, lang: 'fr');
    await go(t, '/home');
    await _images(t);
    await shot(t, 'warning_fr');
  });

  for (final dark in [false, true]) {
    testWidgets('admin customers ${dark ? 'dark' : 'light'}', (t) async {
      final sanctions = FakeSanctionsRepository()
        ..watch = const [
          WatchlistEntry(userId: 'c2', fullName: 'Yacine', email: 'y@mail.dz', cancels30d: 4, openReports: 1),
        ];
      final admin = FakeAdminRepository()
        ..customerList = [
          AdminCustomer(id: 'c1', fullName: 'Amina Benali', email: 'amina@gmail.com', phone: '0661000001',
              wilaya: 16, commune: 'Kouba', gender: 'female', birthDate: DateTime(1998, 5, 2),
              lastDevice: 'Samsung SM-A155F', lastOs: 'Android 14', lastPlatform: 'android', lastAppVersion: '0.3.0+12',
              lastSeenAt: DateTime(2026, 11, 13, 12, 5), activeDays30: 12, referral: 'social', lastLang: 'fr',
              createdAt: DateTime(2026, 10, 2), ordersCount: 7, deliveredCount: 6, cancelledCount: 1, spent: 12400,
              lastOrderAt: DateTime(2026, 11, 12)),
          const AdminCustomer(id: 'c2', fullName: 'Yacine Haddad', email: 'yacine@gmail.com', wilaya: 31,
              ordersCount: 9, cancelledCount: 5, cancels30d: 4, spent: 3100, restriction: 'suspension'),
          const AdminCustomer(id: 'c3', fullName: 'Karim B.', email: 'karim@gmail.com', wilaya: 25, ordersCount: 2, spent: 2300),
        ]
        ..insights = const CustomerInsights(
          customers: 120, new7d: 14, active7d: 61, active1d: 22, ordered: 80, profileDone: 45,
          wilaya: {'16': 70, '31': 20, '25': 12, 'unknown': 18},
          age: {'18-24': 30, '25-34': 41, '35-44': 15, 'unknown': 34},
          gender: {'female': 40, 'male': 50, 'unknown': 30},
          referral: {'social': 50, 'friend': 30, 'restaurant': 10, 'unknown': 30},
          platform: {'android': 90, 'ios': 12, 'web': 18},
        );
      final auth = FakeAuthRepository()
        ..seedUser('a@mail.dz', 'secret123', name: 'Admin')
        ..roles['a@mail.dz'] = 'admin'
        ..signInDirect('a@mail.dz');
      await pumpFoodApp(t, repo: auth, admin: admin, sanctions: sanctions, lang: 'fr', dark: dark,
          size: const Size(1280, 1100));
      await go(t, '/admin/customers');
      await shot(t, 'admin_customers_${dark ? 'dark' : 'light'}');
      if (!dark) {
        await t.tap(find.byKey(const Key('customer:c1')));
        await t.pumpAndSettle();
        await shot(t, 'admin_customer_sheet');
      }
    });
  }
}
