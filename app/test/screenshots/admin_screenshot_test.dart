// Renders the admin pages (real fonts), phone and PC sizes.
// Run: flutter test test/screenshots --update-goldens --tags screenshot --run-skipped
@Tags(['screenshot'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:food_app/features/admin/data/admin_repository.dart';

import '../helpers/fake_auth.dart';

void main() {
  setUpAll(loadFonts);

  const pages = {
    'dashboard': '/admin',
    'restaurants': '/admin/restaurants',
    'orders': '/admin/orders',
    'receipt_new': '/admin/receipts/new?restaurant=r1',
    'receipt': '/admin/receipts/s1',
    'settings': '/admin/settings',
  };

  for (final (lang, size, tag) in [
    ('fr', const Size(375, 812), 'phone'),
    ('ar', const Size(375, 812), 'phone'),
    ('fr', const Size(1280, 800), 'pc'),
  ]) {
    for (final e in pages.entries) {
      testWidgets('${e.key} $lang $tag', (t) async {
        final auth = FakeAuthRepository()
          ..seedUser('admin@food.dz', 'x')
          ..roles['admin@food.dz'] = 'admin'
          ..signInDirect('admin@food.dz');
        final admin = FakeAdminRepository();
        final now = DateTime.now();
        final day = now.day > 15
            ? DateTime(now.year, now.month, 5)
            : DateTime(now.year, now.month - 1, 20);
        admin.delivered.addAll([
          FakeDelivered('r1', 'AAA111', 1000, day),
          FakeDelivered('r1', 'BBB222', 2500, day),
          FakeDelivered('r1', 'CCC333', 1800, now),
        ]);
        await admin.generateStatement('r1', DateRange(day, day));
        await pumpFoodApp(t, repo: auth, admin: admin, lang: lang, size: size);
        GoRouter.of(t.element(find.byType(Scaffold).first)).go(e.value);
        await t.pump(const Duration(milliseconds: 600));
        await t.pump(const Duration(milliseconds: 600));
        expect(t.takeException(), isNull);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('a_${e.key}_${lang}_$tag.png'),
        );
      });
    }
  }
}
