// Renders the redesigned customer pages (home, account, address map) to
// PNGs for visual review. Fails on any overflow.
// Run: flutter test test/screenshots --update-goldens --tags screenshot --run-skipped
@Tags(['screenshot'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_app/main.dart';
import 'package:go_router/go_router.dart';

import '../helpers/fake_auth.dart';

void main() {
  setUpAll(loadFonts);

  const pages = {
    'home': '/home',
    'account': '/account',
    'address_map': '/account/addresses/new',
  };

  for (final lang in ['fr', 'ar']) {
    for (final entry in pages.entries) {
      testWidgets('${entry.key} $lang', (tester) async {
        final repo = FakeAuthRepository()
          ..seedUser('k@mail.dz', 'secret123', name: 'Karim Benali')
          ..signInDirect('k@mail.dz');
        await pumpFoodApp(tester, lang: lang, repo: repo);
        GoRouter.of(
          tester.element(find.byType(Scaffold).first),
        ).go(entry.value);
        await tester.pump(const Duration(milliseconds: 900));
        await tester.pump(const Duration(milliseconds: 900));
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byType(FoodApp),
          matchesGoldenFile('redesign_${entry.key}_$lang.png'),
        );
      });
    }
  }
}
