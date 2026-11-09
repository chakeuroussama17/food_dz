// Renders the browsing and account pages (real fonts) for visual review.
// Run: flutter test test/screenshots --update-goldens --tags screenshot --run-skipped
@Tags(['screenshot'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:food_app/features/account/data/account_repository.dart';

import '../helpers/fake_auth.dart';

void main() {
  setUpAll(loadFonts);

  const pages = {
    'home': '/home',
    'restaurant': '/r/burger-house-hydra',
    'item': '/r/pizzeria-el-bahdja/item/i2',
    'category': '/category/pizza',
    'search': '/search',
    'account': '/account',
    'personal': '/account/personal',
    'edit_profile': '/account/edit',
    'addresses': '/account/addresses',
    'address_new': '/account/addresses/new',
  };

  for (final lang in ['fr', 'ar']) {
    for (final e in pages.entries) {
      testWidgets('${e.key} $lang', (t) async {
        final repo = FakeAuthRepository()
          ..seedUser('k@mail.dz', 'secret123', name: 'Karim')
          ..signInDirect('k@mail.dz');
        final account = FakeAccountRepository();
        await account.addAddress(
          const AddressInput(
            label: AddressLabel.home,
            addressText: 'Cité 200 logements, bât. 4',
            area: 'Kouba',
          ),
          makeDefault: true,
        );
        await pumpFoodApp(t, repo: repo, lang: lang, account: account);
        GoRouter.of(t.element(find.byType(Scaffold).first)).go(e.value);
        await t.pump(const Duration(milliseconds: 500));
        await t.pump(const Duration(milliseconds: 500));
        expect(t.takeException(), isNull);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('b_${e.key}_$lang.png'),
        );
      });
    }
  }
}
