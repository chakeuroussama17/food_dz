// Renders the customer start-flow pages to PNGs (real fonts) for visual
// comparison with Figma, in French and Arabic. Fails on any overflow.
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
    'onboarding': '/welcome',
    'login': '/login',
    'signup': '/signup',
    'verify': '/verify?email=karim@gmail.com&purpose=signup',
    'forgot': '/forgot-password',
  };

  for (final lang in ['fr', 'ar']) {
    testWidgets('splash $lang', (tester) async {
      await pumpFoodApp(tester, lang: lang, onboardingDone: false);
      // Go back to splash and stop mid-way through the intro at the end
      // state of the animation.
      GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 950));
      await expectLater(
        find.byType(FoodApp),
        matchesGoldenFile('splash_$lang.png'),
      );
      await tester.pump(const Duration(seconds: 2));
    });

    for (final entry in pages.entries) {
      testWidgets('${entry.key} $lang', (tester) async {
        await pumpFoodApp(tester, lang: lang, onboardingDone: false);
        GoRouter.of(
          tester.element(find.byType(Scaffold).first),
        ).go(entry.value);
        await tester.pump(const Duration(milliseconds: 600));
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byType(FoodApp),
          matchesGoldenFile('${entry.key}_$lang.png'),
        );
      });
    }
  }
}
