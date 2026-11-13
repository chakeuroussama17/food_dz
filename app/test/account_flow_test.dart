import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_app/features/auth/pages/login_page.dart';
import 'package:food_app/features/account/data/account_repository.dart';
import 'package:food_app/features/account/pages/account_page.dart';
import 'package:food_app/features/account/pages/addresses_page.dart';

import 'helpers/fake_auth.dart';

Future<FakeAccountRepository> openAccount(
  WidgetTester t, {
  Future<void> Function(FakeAccountRepository)? seed,
}) async {
  final account = FakeAccountRepository(name: 'Karim Benali');
  if (seed != null) await seed(account);
  final repo = FakeAuthRepository()..seedUser('k@mail.dz', 'secret123');
  await pumpFoodApp(t, repo: repo, account: account);
  await t.enterText(find.byType(TextFormField).at(0), 'k@mail.dz');
  await t.enterText(find.byType(TextFormField).at(1), 'secret123');
  await t.tap(find.text('LOG IN').last);
  await t.pumpAndSettle();
  await t.tap(find.text('Account').last); // bottom bar
  await t.pumpAndSettle();
  return account;
}

final _vertical = find.byWidgetPredicate(
  (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
);

/// Scrolls [f] fully on screen (long forms), then taps it.
Future<void> tap(WidgetTester t, Finder f) async {
  await t.ensureVisible(f);
  await t.pumpAndSettle();
  final size = t.view.physicalSize / t.view.devicePixelRatio;
  if (t.getRect(f).bottom > size.height && _vertical.evaluate().isNotEmpty) {
    await t.drag(_vertical.first, const Offset(0, -300));
    await t.pumpAndSettle();
  }
  await t.tap(f);
  await t.pumpAndSettle();
}

Finder input(String label) => find.descendant(
  of: find
      .ancestor(
        // Labels may carry "(optional)" in the same text.
        of: find.textContaining(label.toUpperCase()),
        matching: find.byType(Column),
      )
      .first,
  matching: find.byType(TextFormField),
);

void main() {
  setUpAll(loadFonts);

  testWidgets('profile shows name and email', (t) async {
    await openAccount(t);
    expect(find.byType(AccountPage), findsOneWidget);
    expect(find.text('Karim Benali'), findsOneWidget);
    expect(find.text('View profile'), findsOneWidget);
    // Shortcut cards and the general links.
    for (final x in ['Orders', 'Addresses', 'Help center', 'Log out']) {
      expect(find.text(x), findsWidgets, reason: x);
    }
  });

  testWidgets('delete account: asks first, then logs out', (t) async {
    final account = await openAccount(t);
    await tap(t, find.text('Delete my account'));
    expect(find.textContaining('Permanently delete'), findsOneWidget);
    await tap(t, find.text('Back'));
    expect(account.deleted, 0);

    await tap(t, find.text('Delete my account'));
    await tap(t, find.text('Delete my account').last);
    expect(account.deleted, 1);
    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('delete account refused while an order is in progress', (
    t,
  ) async {
    final account = await openAccount(t);
    account.deleteFails = DeleteAccountFailure.activeOrders;
    await tap(t, find.text('Delete my account'));
    await tap(t, find.text('Delete my account').last);
    expect(find.textContaining('order in progress'), findsOneWidget);
    expect(find.byType(AccountPage), findsOneWidget);
  });

  testWidgets('edit profile: invalid phone refused, valid one saved', (
    t,
  ) async {
    final account = await openAccount(t);
    await tap(t, find.text('View profile'));
    await tap(t, find.text('EDIT'));
    Future<void> save() async {
      await t.scrollUntilVisible(
        find.text('SAVE'),
        300,
        scrollable: _vertical.first,
      );
      await tap(t, find.text('SAVE'));
    }

    await t.enterText(input('Phone'), '021 12 34 56');
    await save();
    await t.drag(_vertical.first, const Offset(0, 3000)); // back to the top
    await t.pumpAndSettle();
    expect(find.textContaining('Invalid number'), findsOneWidget);

    await t.enterText(input('Phone'), '+213 661 12 34 56');
    await t.enterText(input('Full name'), 'Karim B.');
    // Gender and commune (wilaya, birth date: optional).
    await t.scrollUntilVisible(
      find.byKey(const Key('choice:male')),
      300,
      scrollable: _vertical.first,
    );
    await t.enterText(input('Commune'), 'Kouba');
    await tap(t, find.byKey(const Key('choice:male')));
    await save();
    expect(account.profile.phone, '0661123456'); // normalised
    expect(account.profile.fullName, 'Karim B.');
    expect(account.profile.gender, 'male');
    expect(account.profile.commune, 'Kouba');
    expect(find.text('0661123456'), findsOneWidget); // back on Personal info
  });

  testWidgets('map search fills the address and the area', (t) async {
    final account = await openAccount(t);
    await tap(t, find.text('Addresses'));
    await tap(t, find.text('ADD NEW ADDRESS'));
    await t.enterText(find.byType(TextField).first, 'didouche');
    await t.pump(const Duration(milliseconds: 700)); // debounce
    await t.pumpAndSettle();
    await tap(t, find.textContaining('Rue Didouche Mourad'));
    expect(
      (t.widget(input('Address')) as TextFormField).controller!.text,
      '12, Rue Didouche Mourad',
    );
    await tap(t, find.text('SAVE LOCATION'));
    final a = account.addressList.single;
    expect(a.area, 'Alger Centre');
    expect(a.lat, closeTo(36.7703, 1e-6));
    expect(a.lng, closeTo(3.0560, 1e-6));
  });

  testWidgets('add an address: first one becomes the default', (t) async {
    final account = await openAccount(t);
    await tap(t, find.text('Addresses'));
    expect(find.text('No saved address yet'), findsOneWidget);
    await tap(t, find.text('ADD NEW ADDRESS'));

    await tap(t, find.text('SAVE LOCATION'));
    expect(find.textContaining('Enter the address'), findsOneWidget);

    await t.enterText(input('Address'), 'Cité 200 logements, bât. 4');
    await t.enterText(input('Neighbourhood / commune'), 'Kouba');
    await tap(t, find.text('Work'));
    await tap(t, find.text('SAVE LOCATION'));

    expect(find.byType(AddressesPage), findsOneWidget);
    expect(find.text('WORK'), findsOneWidget);
    expect(find.text('Default'), findsOneWidget);
    final a = account.addressList.single;
    expect(a.isDefault, isTrue);
    expect(a.label, AddressLabel.work);
    expect(a.lat, isNotNull); // map pin saved
  });

  testWidgets('tap a card to make it default; delete asks first', (t) async {
    final account = await openAccount(
      t,
      seed: (a) async {
        await a.addAddress(
          const AddressInput(label: AddressLabel.home, addressText: 'Maison'),
          makeDefault: true,
        );
        await a.addAddress(
          const AddressInput(label: AddressLabel.work, addressText: 'Bureau'),
        );
      },
    );
    await tap(t, find.text('Addresses'));
    await tap(t, find.text('Bureau'));
    expect(
      account.addressList.firstWhere((a) => a.isDefault).addressText,
      'Bureau',
    );

    await tap(t, find.byTooltip('Delete').last);
    expect(find.text('Delete this address?'), findsOneWidget);
    await tap(t, find.text('Delete').last);
    expect(account.addressList.length, 1);
  });
}
