import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_app/features/auth/pages/login_page.dart';
import 'package:food_app/features/auth/pages/reset_password_page.dart';
import 'package:food_app/features/auth/pages/verify_page.dart';
import 'package:food_app/features/home/home_page.dart';
import 'package:food_app/features/onboarding/onboarding_page.dart';

import 'helpers/fake_auth.dart';

/// The TextFormField under the uppercase label [label].
Finder input(String label) => find.descendant(
  of: find
      .ancestor(
        of: find.text(label.toUpperCase()),
        matching: find.byType(Column),
      )
      .first,
  matching: find.byType(TextFormField),
);

Future<void> type(WidgetTester t, String label, String text) =>
    t.enterText(input(label), text);

Future<void> tapText(WidgetTester t, String text) async {
  await t.ensureVisible(find.text(text).last);
  await t.tap(find.text(text).last);
  await t.pumpAndSettle();
}

void main() {
  setUpAll(loadFonts);

  testWidgets('first launch shows onboarding, Skip goes to login', (
    tester,
  ) async {
    await pumpFoodApp(tester, onboardingDone: false);
    expect(find.byType(OnboardingPage), findsOneWidget);
    expect(find.text('All your favorites'), findsOneWidget);
    await tapText(tester, 'NEXT');
    expect(find.text('The best restaurants'), findsOneWidget);
    await tapText(tester, 'Skip');
    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('onboarding last page shows GET STARTED', (tester) async {
    await pumpFoodApp(tester, onboardingDone: false);
    await tapText(tester, 'NEXT');
    await tapText(tester, 'NEXT');
    expect(find.text('GET STARTED'), findsOneWidget);
    expect(find.text('Skip'), findsNothing);
    await tapText(tester, 'GET STARTED');
    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('login validates fields before calling the backend', (
    tester,
  ) async {
    final repo = await pumpFoodApp(tester);
    await tapText(tester, 'LOG IN');
    expect(find.text('Invalid email address'), findsOneWidget);
    expect(repo.calls, isEmpty);
  });

  testWidgets('wrong password shows an error, right one goes home', (
    tester,
  ) async {
    final repo = FakeAuthRepository()..seedUser('k@mail.dz', 'secret123');
    await pumpFoodApp(tester, repo: repo);
    await type(tester, 'Email', 'k@mail.dz');
    await type(tester, 'Password', 'wrongpass');
    await tapText(tester, 'LOG IN');
    expect(find.text('Wrong email or password'), findsOneWidget);

    await type(tester, 'Password', 'secret123');
    await tapText(tester, 'LOG IN');
    expect(find.byType(HomePage), findsOneWidget);
    expect(find.text('Pizzeria El Bahdja'), findsOneWidget);
  });

  testWidgets('unconfirmed account at login is sent to the code page', (
    tester,
  ) async {
    final repo = FakeAuthRepository()
      ..seedUser('new@mail.dz', 'secret123', confirmed: false);
    await pumpFoodApp(tester, repo: repo);
    await type(tester, 'Email', 'new@mail.dz');
    await type(tester, 'Password', 'secret123');
    await tapText(tester, 'LOG IN');
    expect(find.byType(VerifyPage), findsOneWidget);
    expect(repo.calls, contains('resend:new@mail.dz'));
  });

  testWidgets('sign up, then code, then home', (tester) async {
    final repo = await pumpFoodApp(tester);
    await tapText(tester, 'SIGN UP');

    await type(tester, 'Name', 'Amina');
    await type(tester, 'Email', 'amina@mail.dz');
    await type(tester, 'Password', 'password1');
    await type(tester, 'Re-type password', 'password2');
    await tapText(tester, 'SIGN UP');
    expect(find.text("Passwords don't match"), findsOneWidget);

    await type(tester, 'Re-type password', 'password1');
    await tapText(tester, 'SIGN UP');
    expect(find.byType(VerifyPage), findsOneWidget);
    expect(find.text('amina@mail.dz'), findsOneWidget);

    // Wrong code
    await tester.enterText(find.byType(TextField).first, '000000');
    await tester.pumpAndSettle();
    expect(find.text('Wrong or expired code'), findsOneWidget);

    // Right code: signed in, router goes home
    await tester.enterText(find.byType(TextField).first, '123456');
    await tester.pumpAndSettle();
    expect(find.byType(HomePage), findsOneWidget);
    expect(find.text('Pizzeria El Bahdja'), findsOneWidget);
    expect(repo.calls, contains('verifySignup:amina@mail.dz:123456'));
  });

  testWidgets('sign up without email confirmation goes straight home', (
    tester,
  ) async {
    final repo = FakeAuthRepository()..requireEmailConfirmation = false;
    await pumpFoodApp(tester, repo: repo);
    await tapText(tester, 'SIGN UP');
    await type(tester, 'Name', 'Oussama');
    await type(tester, 'Email', 'oussama@mail.dz');
    await type(tester, 'Password', 'password1');
    await type(tester, 'Re-type password', 'password1');
    await tapText(tester, 'SIGN UP');
    expect(find.byType(VerifyPage), findsNothing);
    expect(find.byType(HomePage), findsOneWidget);
    expect(find.text('Pizzeria El Bahdja'), findsOneWidget);
  });

  testWidgets('sign up with an existing email shows an error', (tester) async {
    final repo = FakeAuthRepository()..seedUser('k@mail.dz', 'secret123');
    await pumpFoodApp(tester, repo: repo);
    await tapText(tester, 'SIGN UP');
    await type(tester, 'Name', 'Karim');
    await type(tester, 'Email', 'k@mail.dz');
    await type(tester, 'Password', 'password1');
    await type(tester, 'Re-type password', 'password1');
    await tapText(tester, 'SIGN UP');
    expect(
      find.text('An account with this email already exists'),
      findsOneWidget,
    );
  });

  testWidgets('forgot password, code, new password, home', (tester) async {
    final repo = FakeAuthRepository()..seedUser('k@mail.dz', 'oldpass12');
    await pumpFoodApp(tester, repo: repo);
    await tapText(tester, 'Forgot password');
    await type(tester, 'Email', 'k@mail.dz');
    await tapText(tester, 'SEND CODE');
    expect(find.byType(VerifyPage), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '123456');
    await tester.pumpAndSettle();
    expect(find.byType(ResetPasswordPage), findsOneWidget);

    await type(tester, 'New password', 'newpass12');
    await type(tester, 'Re-type password', 'newpass12');
    await tapText(tester, 'SAVE');
    expect(find.byType(HomePage), findsOneWidget);
    expect(repo.calls, contains('updatePassword'));
  });

  testWidgets('log out returns to login', (tester) async {
    final repo = FakeAuthRepository()..seedUser('k@mail.dz', 'secret123');
    await pumpFoodApp(tester, repo: repo);
    await type(tester, 'Email', 'k@mail.dz');
    await type(tester, 'Password', 'secret123');
    await tapText(tester, 'LOG IN');
    await tester.tap(find.byIcon(Icons.notes_rounded)); // profile menu
    await tester.pumpAndSettle();
    await tapText(tester, 'Log out');
    expect(find.byType(LoginPage), findsOneWidget);
  });

  for (final lang in ['ar', 'fr']) {
    testWidgets('onboarding uses the right direction in $lang', (tester) async {
      await pumpFoodApp(tester, lang: lang, onboardingDone: false);
      expect(tester.takeException(), isNull);
      final ctx = tester.element(find.byType(OnboardingPage));
      expect(
        Directionality.of(ctx),
        lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      );
    });
  }
}
