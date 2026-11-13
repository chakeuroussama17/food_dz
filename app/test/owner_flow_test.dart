import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_app/features/home/home_page.dart';
import 'package:food_app/features/restaurant_owner/data/owner_repository.dart';
import 'package:food_app/features/restaurant_owner/pages/owner_dashboard_page.dart';
import 'package:food_app/features/restaurant_owner/pages/owner_item_form_page.dart';
import 'package:food_app/features/restaurant_owner/pages/owner_menu_page.dart';
import 'package:go_router/go_router.dart';

import 'helpers/fake_auth.dart';

final _vertical = find.byWidgetPredicate(
  (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
);

/// Scrolls [f] fully on screen, then taps it.
Future<void> tap(WidgetTester t, Finder f) async {
  await t.ensureVisible(f);
  await t.pumpAndSettle();
  final h = (t.view.physicalSize / t.view.devicePixelRatio).height;
  if (t.getRect(f).bottom > h - 70 && _vertical.evaluate().isNotEmpty) {
    await t.drag(_vertical.first, const Offset(0, -250));
    await t.pumpAndSettle();
  }
  await t.tap(f);
  await t.pumpAndSettle();
}

Finder input(String label) => find.descendant(
  of: find
      .ancestor(
        of: find.textContaining(label.toUpperCase()),
        matching: find.byType(Column),
      )
      .first,
  matching: find.byType(TextFormField),
);

/// Signed-in owner whose restaurant already exists.
Future<FakeOwnerRepository> ownerApp(
  WidgetTester t, {
  bool active = false,
  bool open = false,
}) async {
  final auth = FakeAuthRepository()
    ..seedUser('o@mail.dz', 'secret123', name: 'Omar')
    ..roles['o@mail.dz'] = 'restaurant'
    ..signInDirect('o@mail.dz');
  final owner = FakeOwnerRepository()
    ..restaurant = OwnedRestaurant(
      id: 'own1',
      slug: 'chez-omar',
      name: 'Chez Omar',
      area: 'Kouba',
      phone: '0550111222',
      address: 'Rue 1',
      isActive: active,
      isOpen: open,
    );
  await pumpFoodApp(t, repo: auth, owner: owner);
  return owner;
}

void main() {
  setUpAll(loadFonts);

  testWidgets('register a restaurant from the login page', (t) async {
    final auth = FakeAuthRepository()..requireEmailConfirmation = false;
    final owner = FakeOwnerRepository();
    owner.onRegistered = () => auth.roles['omar@mail.dz'] = 'restaurant';
    await pumpFoodApp(t, repo: auth, owner: owner);

    await tap(t, find.text('REGISTER IT'));
    expect(find.text('Your restaurant'), findsOneWidget);

    await t.enterText(input('Name'), 'Omar');
    await t.enterText(input('Email'), 'omar@mail.dz');
    await t.enterText(input('Password'), 'password1');
    await t.enterText(input('Restaurant name'), 'Chez Omar');
    await t.enterText(input('Restaurant phone'), '021 23 45 67');
    await t.enterText(input('Address'), 'Rue Didouche Mourad');
    await t.enterText(input('Neighbourhood'), 'Alger Centre');
    await tap(t, find.text('SIGN UP'));

    expect(find.byType(OwnerDashboardPage), findsOneWidget);
    expect(find.text('Waiting for approval'), findsOneWidget);
    expect(owner.lastRegistration!.phone, '021234567'); // normalised
    expect(owner.lastRegistration!.prepMinutes, 20);
  });

  testWidgets('registration form validates the restaurant phone', (t) async {
    final auth = FakeAuthRepository()..requireEmailConfirmation = false;
    final owner = FakeOwnerRepository();
    await pumpFoodApp(t, repo: auth, owner: owner);
    await tap(t, find.text('REGISTER IT'));
    await t.enterText(input('Restaurant phone'), '12345');
    await tap(t, find.text('SIGN UP'));
    expect(find.textContaining('Invalid number (e.g.'), findsOneWidget);
    expect(owner.lastRegistration, isNull);
    expect(auth.calls, isEmpty); // no account created
  });

  testWidgets('owners land on the dashboard and cannot open customer pages', (
    t,
  ) async {
    await ownerApp(t);
    expect(find.byType(OwnerDashboardPage), findsOneWidget);
    expect(find.text('Chez Omar'), findsOneWidget);
    GoRouter.of(t.element(find.byType(Scaffold).first)).go('/home');
    await t.pumpAndSettle();
    expect(find.byType(HomePage), findsNothing);
    expect(find.byType(OwnerDashboardPage), findsOneWidget);
  });

  testWidgets('before approval the open switch is disabled', (t) async {
    await ownerApp(t);
    final sw = t.widget<Switch>(find.byType(Switch));
    expect(sw.onChanged, isNull);
    expect(
      find.text('You can open once your restaurant is approved'),
      findsOneWidget,
    );
  });

  testWidgets('approved restaurant can open for orders', (t) async {
    final owner = await ownerApp(t, active: true);
    expect(find.text('Waiting for approval'), findsNothing);
    await tap(t, find.byType(Switch));
    expect(owner.restaurant!.isOpen, isTrue);
    expect(find.text('Open for orders'), findsOneWidget);
  });

  testWidgets('add, edit, hide and delete a dish', (t) async {
    final owner = await ownerApp(t);
    await tap(t, find.bySemanticsLabel('My menu'));
    await tap(t, find.byTooltip('Add new item'));
    expect(find.byType(OwnerItemFormPage), findsOneWidget);

    await tap(t, find.text('SAVE CHANGES'));
    expect(find.text('Price between 10 and 100,000 DA'), findsOneWidget);

    await t.enterText(input('Item name'), 'Burger maison');
    await t.enterText(input('Price'), '850');
    await tap(t, find.text('Burger').first);
    await tap(t, find.text('SAVE CHANGES'));
    expect(owner.dishes.single.name, 'Burger maison');
    expect(owner.dishes.single.categoryId, 'c-burger');

    // Back on the menu, which lists it; the switch hides it.
    expect(find.byType(OwnerMenuPage), findsOneWidget);
    expect(find.text('Burger maison'), findsOneWidget);
    await tap(t, find.byType(Switch).first);
    expect(owner.dishes.single.isAvailable, isFalse);

    // Edit price.
    await tap(t, find.text('Burger maison'));
    await t.enterText(input('Price'), '900');
    await tap(t, find.text('SAVE CHANGES'));
    expect(owner.dishes.single.price, 900);

    // Delete (after the "Saved" snackbar has gone; it covers the button).
    await t.pump(const Duration(seconds: 5));
    await t.pumpAndSettle();
    await tap(t, find.text('Burger maison'));
    await tap(t, find.text('Delete'));
    await tap(t, find.text('Delete').last);
    expect(owner.dishes, isEmpty);
    expect(
      find.text('Your menu is empty. Add your first dish.'),
      findsOneWidget,
    );
  });

  testWidgets('profile edits are saved', (t) async {
    final owner = await ownerApp(t);
    await tap(t, find.bySemanticsLabel('Account'));
    await tap(t, find.text('Restaurant profile'));
    await t.enterText(input('Description'), 'Cuisine maison');
    await t.enterText(input('Preparation time'), '35');
    await tap(t, find.text('SAVE CHANGES'));
    expect(owner.restaurant!.description, 'Cuisine maison');
    expect(owner.restaurant!.prepMinutes, 35);
  });

  testWidgets('owner dashboard renders in Arabic without overflow', (t) async {
    final auth = FakeAuthRepository()
      ..seedUser('o@mail.dz', 'secret123')
      ..roles['o@mail.dz'] = 'restaurant'
      ..signInDirect('o@mail.dz');
    final owner = FakeOwnerRepository()
      ..restaurant = const OwnedRestaurant(
        id: 'own1',
        slug: 'x',
        name: 'مطعم الأمير',
      );
    await pumpFoodApp(t, repo: auth, owner: owner, lang: 'ar');
    expect(find.text('في انتظار الموافقة'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
