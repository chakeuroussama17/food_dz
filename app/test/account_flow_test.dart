import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
  await t.tap(find.byIcon(Icons.notes_rounded));
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
    expect(find.text('k@mail.dz'), findsOneWidget);
  });

  testWidgets('edit profile: invalid phone refused, valid one saved', (
    t,
  ) async {
    final account = await openAccount(t);
    await tap(t, find.text('Personal info'));
    await tap(t, find.text('EDIT'));
    await t.enterText(input('Phone'), '021 12 34 56');
    await tap(t, find.text('SAVE'));
    expect(find.textContaining('Invalid number'), findsOneWidget);

    await t.enterText(input('Phone'), '+213 661 12 34 56');
    await t.enterText(input('Full name'), 'Karim B.');
    await tap(t, find.text('SAVE'));
    expect(account.profile.phone, '0661123456'); // normalised
    expect(account.profile.fullName, 'Karim B.');
    expect(find.text('0661123456'), findsOneWidget); // back on Personal info
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
