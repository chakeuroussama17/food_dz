import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_app/core/data/wilayas.dart';
import 'package:go_router/go_router.dart';

import 'helpers/fake_auth.dart';

void main() {
  setUpAll(loadFonts);

  test('58 wilayas, in order, with both names', () {
    expect(wilayas.length, 58);
    for (var i = 0; i < 58; i++) {
      expect(wilayas[i].$1, i + 1);
    }
    expect(wilayaLabel(16, 'fr'), '16 - Alger');
    expect(wilayaLabel(31, 'ar'), '31 - وهران');
  });

  Future<(FakeAccountRepository, FakeSessionRepository)> home(
    WidgetTester t,
  ) async {
    final account = FakeAccountRepository();
    account.profile = account.profile.copyWith(promptAnswered: false);
    final session = FakeSessionRepository();
    final auth = FakeAuthRepository()
      ..seedUser('k@mail.dz', 'secret123', name: 'Karim')
      ..signInDirect('k@mail.dz');
    await pumpFoodApp(t, repo: auth, account: account, session: session);
    GoRouter.of(t.element(find.byType(Scaffold).first)).go('/home');
    await t.pumpAndSettle();
    return (account, session);
  }

  testWidgets('the app reports itself once when signed in', (t) async {
    final (_, session) = await home(t);
    expect(session.touches, ['android:0.3.0+12:Samsung SM-A155F:en']);
  });

  testWidgets('complete-profile card: Later hides it for good', (t) async {
    final (account, _) = await home(t);
    expect(find.byKey(const Key('complete-profile')), findsOneWidget);
    await t.tap(find.text('Later'));
    await t.pumpAndSettle();
    expect(account.detailCalls, ['skip']);
    expect(find.byKey(const Key('complete-profile')), findsNothing);
  });

  testWidgets('complete-profile: gender, place, how they heard', (t) async {
    final (account, _) = await home(t);
    await t.tap(find.text('Complete'));
    await t.pumpAndSettle();
    expect(
      find.text('This stays private: it helps us improve foodfennec.'),
      findsOneWidget,
    );
    await t.tap(find.byKey(const Key('choice:female')));
    await t.pumpAndSettle();
    final sheet = find.byType(BottomSheet);
    final commune = find.descendant(
      of: sheet,
      matching: find.byType(TextFormField),
    );
    await t.ensureVisible(commune);
    await t.enterText(commune, 'Oran');
    final social = find.byKey(const Key('choice:social'));
    await t.ensureVisible(social);
    await t.pumpAndSettle();
    await t.tap(social);
    await t.pumpAndSettle();
    await t.ensureVisible(find.text('SAVE'));
    await t.pumpAndSettle();
    await t.tap(find.text('SAVE'));
    await t.pumpAndSettle();
    expect(account.detailCalls, ['details:null:female:null:Oran:social:true']);
    expect(find.text('Thanks! Profile updated.'), findsOneWidget);
    expect(find.byKey(const Key('complete-profile')), findsNothing);
    expect(t.takeException(), isNull);
  });
}
