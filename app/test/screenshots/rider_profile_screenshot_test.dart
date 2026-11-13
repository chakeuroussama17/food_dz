// Rider profile: hero card, numbers, rating, settings, delete; rating
// details; edit page.
// Run: flutter test test/screenshots/rider_profile_screenshot_test.dart --update-goldens --tags screenshot --run-skipped
@Tags(['screenshot'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_auth.dart';
import '../rider_profile_test.dart' as p;

void main() {
  setUpAll(loadFonts);

  for (final (lang, dark) in [('fr', false), ('ar', false), ('fr', true)]) {
    final tag = '$lang${dark ? '_dark' : ''}';
    Future<void> shot(String name) => expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('rp_${name}_$tag.png'),
    );

    testWidgets('profile $tag', (t) async {
      await p.app(t, lang: lang, dark: dark, size: const Size(390, 1500));
      await shot('profile');
    });

    testWidgets('rating $tag', (t) async {
      await p.app(t, lang: lang, dark: dark, size: const Size(390, 1400));
      await p.go(t, '/driver/account/rating');
      await shot('rating');
    });

    testWidgets('edit $tag', (t) async {
      await p.app(t, lang: lang, dark: dark, size: const Size(390, 844));
      await p.go(t, '/driver/account/edit');
      await shot('edit');
    });

    testWidgets('delete $tag', (t) async {
      await p.app(t, lang: lang, dark: dark, size: const Size(390, 844));
      await p.tap(t, find.byIcon(Icons.delete_forever_rounded));
      await shot('delete');
    });
  }
}
