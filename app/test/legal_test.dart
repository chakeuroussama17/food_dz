import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_app/features/legal/legal_texts.dart';
import 'package:go_router/go_router.dart';

import 'helpers/fake_auth.dart';

Future<void> go(WidgetTester t, String path) async {
  GoRouter.of(t.element(find.byType(Scaffold).first)).go(path);
  await t.pumpAndSettle();
}

Future<void> tap(WidgetTester t, Finder f) async {
  await t.ensureVisible(f);
  await t.pumpAndSettle();
  await t.tap(f);
  await t.pumpAndSettle();
}

void main() {
  setUpAll(loadFonts);

  test('every document exists in the three languages, same sections', () {
    for (final id in legalDocIds) {
      final fr = legalDoc(id, 'fr');
      for (final lang in ['ar', 'en']) {
        final d = legalDoc(id, lang);
        expect(d.id, id);
        expect(d.sections.length, fr.sections.length, reason: '$id $lang');
      }
    }
    expect(requiredDocs('customer'), ['terms', 'privacy']);
    expect(requiredDocs('driver'), contains('rider'));
    expect(requiredDocs('restaurant'), contains('partner'));
  });

  testWidgets('legal pages are public (no account)', (t) async {
    await pumpFoodApp(t);
    await go(t, '/legal/privacy');
    expect(find.text('Privacy policy'), findsOneWidget);
    expect(find.textContaining('Law No. 18-07'), findsOneWidget);
    await go(t, '/terms');
    expect(find.text('Rider terms'), findsOneWidget);
    await tap(t, find.byKey(const Key('legal:terms')));
    expect(find.textContaining('Limitation of liability'), findsNothing);
    await t.scrollUntilVisible(
      find.text('7. Limitation of liability'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('7. Limitation of liability'), findsOneWidget);
  });

  testWidgets('a rider who never accepted must accept the three texts', (
    t,
  ) async {
    final consent = FakeConsentRepository()..acceptedDocs = {};
    final auth = FakeAuthRepository()
      ..seedUser('d@mail.dz', 'secret123', name: 'Rachid')
      ..roles['d@mail.dz'] = 'driver'
      ..signInDirect('d@mail.dz');
    await pumpFoodApp(
      t,
      repo: auth,
      consent: consent,
      driver: FakeDriverRepository()..seedDriver(),
    );
    expect(find.byKey(const Key('accept-terms')), findsOneWidget);
    expect(find.text('I accept: Rider terms'), findsOneWidget);

    // Read one, come back.
    await tap(t, find.text('Read').last);
    expect(find.text('1. Status'), findsOneWidget);
    await tap(t, find.byType(BackButtonIcon));

    // All three boxes before the button works.
    await tap(t, find.byKey(const Key('accept:terms')));
    await tap(t, find.text('ACCEPT AND CONTINUE'));
    expect(consent.calls, isEmpty);
    await tap(t, find.byKey(const Key('accept:privacy')));
    await tap(t, find.byKey(const Key('accept:rider')));
    await tap(t, find.text('ACCEPT AND CONTINUE'));
    expect(consent.calls, ['terms,privacy,rider@$kLegalVersion']);
    expect(find.byKey(const Key('accept-terms')), findsNothing);
    expect(find.text('Ready to ride?'), findsOneWidget);
  });

  testWidgets('Continue with Google: signed in, terms asked, then home', (
    t,
  ) async {
    final consent = FakeConsentRepository()..acceptedDocs = {};
    final auth = FakeAuthRepository();
    await pumpFoodApp(t, repo: auth, consent: consent);
    expect(find.byKey(const Key('social:facebook')), findsNothing); // off for now
    expect(find.byKey(const Key('social:apple')), findsNothing); // iPhone only
    await tap(t, find.byKey(const Key('social:google')));
    expect(auth.calls, contains('social:google'));
    expect(find.byKey(const Key('accept-terms')), findsOneWidget);
    await tap(t, find.byKey(const Key('accept:terms')));
    await tap(t, find.byKey(const Key('accept:privacy')));
    await tap(t, find.text('ACCEPT AND CONTINUE'));
    expect(consent.calls.single, 'terms,privacy@$kLegalVersion');
    expect(find.text('Pizzeria El Bahdja'), findsWidgets); // home
  });

  testWidgets('a failed social login shows a message', (t) async {
    final auth = FakeAuthRepository()..socialFails = true;
    await pumpFoodApp(t, repo: auth);
    await tap(t, find.byKey(const Key('social:google')));
    expect(find.textContaining('Couldn’t sign in'), findsOneWidget);
  });
}
