import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_app/features/catalog/pages/item_page.dart';
import 'package:food_app/features/catalog/pages/restaurant_page.dart';
import 'package:food_app/features/catalog/pages/search_page.dart';
import 'package:food_app/features/onboarding/location_access_page.dart';

import 'helpers/fake_auth.dart';

Future<FakeAuthRepository> signedInApp(
  WidgetTester t, {
  String lang = 'en',
  bool locationAsked = true,
}) async {
  final repo = FakeAuthRepository()
    ..seedUser('k@mail.dz', 'secret123', name: 'Karim');
  await pumpFoodApp(t, repo: repo, lang: lang, locationAsked: locationAsked);
  await t.enterText(find.byType(TextFormField).at(0), 'k@mail.dz');
  await t.enterText(find.byType(TextFormField).at(1), 'secret123');
  await t.tap(find.text(lang == 'en' ? 'LOG IN' : 'تسجيل الدخول').last);
  await t.pumpAndSettle();
  return repo;
}

/// The main vertical list (pages also contain horizontal lists).
final mainScroll = find.byWidgetPredicate(
  (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
);

Future<void> tap(WidgetTester t, Finder f) async {
  await t.ensureVisible(f);
  await t.pumpAndSettle(); // let the scroll land before tapping
  await t.tap(f);
  await t.pumpAndSettle();
}

/// Badge number on the cart button.
Finder cartBadge(String n) =>
    find.descendant(of: find.byType(Stack), matching: find.text(n));

void main() {
  setUpAll(loadFonts);

  testWidgets('home lists categories and restaurants, greets by name', (
    t,
  ) async {
    await signedInApp(t);
    expect(find.textContaining('Hey Karim'), findsOneWidget);
    expect(find.text('Pizza'), findsWidgets);
    expect(find.text('Pizzeria El Bahdja'), findsOneWidget);
    expect(find.text('Burger House'), findsOneWidget);
    await t.scrollUntilVisible(
      find.text('Dar Lgharbi'),
      300,
      scrollable: mainScroll.first,
    );
    expect(find.text('Closed'), findsOneWidget); // Dar Lgharbi
    expect(find.text('200 DA'.replaceAll(' ', ' ')), findsWidgets);
    expect(t.takeException(), isNull);
  });

  testWidgets('location screen is offered once after login', (t) async {
    await signedInApp(t, locationAsked: false);
    expect(find.byType(LocationAccessPage), findsOneWidget);
    await tap(t, find.text('Not now'));
    expect(find.byType(LocationAccessPage), findsNothing);
    expect(find.text('Pizzeria El Bahdja'), findsOneWidget);
  });

  testWidgets('restaurant page: chips filter dishes, unavailable is greyed', (
    t,
  ) async {
    await signedInApp(t);
    await tap(t, find.text('Burger House'));
    expect(find.byType(RestaurantPage), findsOneWidget);
    expect(find.text('All (2)'), findsOneWidget);
    expect(find.text('Smash Burger'), findsOneWidget);
    expect(find.text('Unavailable'), findsOneWidget); // Burger Royal
    await tap(t, find.text('Burger').first);
    expect(find.text('Burger (2)'), findsOneWidget);
  });

  testWidgets('add to cart from the grid updates the badge', (t) async {
    await signedInApp(t);
    await tap(t, find.text('Pizzeria El Bahdja'));
    await tap(t, find.byIcon(Icons.add_rounded).first);
    expect(find.text('Added to cart'), findsOneWidget);
    expect(cartBadge('1'), findsOneWidget);
  });

  testWidgets('dish page: quantity 3 → cart shows 3 and the subtotal', (
    t,
  ) async {
    await signedInApp(t);
    await tap(t, find.text('Pizzeria El Bahdja'));
    await tap(t, find.text('Pizza Thon'));
    expect(find.byType(ItemPage), findsOneWidget);
    await tap(t, find.bySemanticsLabel('+'));
    await tap(t, find.bySemanticsLabel('+'));
    await tap(t, find.text('ADD TO CART'));
    expect(cartBadge('3'), findsOneWidget);
    await tap(t, find.byIcon(Icons.shopping_bag_outlined).first);
    // Line total, and the total with the 200 DA delivery fee.
    expect(find.text('2 700 DA'), findsOneWidget);
    expect(find.text('2 900 DA'), findsOneWidget);
  });

  testWidgets('dishes from another restaurant ask before a new cart', (
    t,
  ) async {
    await signedInApp(t);
    await tap(t, find.text('Pizzeria El Bahdja'));
    await tap(t, find.byIcon(Icons.add_rounded).first);
    await t.pageBack();
    await t.pumpAndSettle();
    await tap(t, find.text('Burger House'));
    await tap(t, find.byIcon(Icons.add_rounded).first);
    expect(find.textContaining('Start a new cart?'), findsOneWidget);
    await tap(t, find.text('Cancel'));
    expect(cartBadge('1'), findsOneWidget);
  });

  testWidgets('closed restaurant shows Closed on its page', (t) async {
    final catalog = FakeCatalogRepository();
    final repo = FakeAuthRepository()..seedUser('k@mail.dz', 'secret123');
    await pumpFoodApp(t, repo: repo, catalog: catalog);
    await t.enterText(find.byType(TextFormField).at(0), 'k@mail.dz');
    await t.enterText(find.byType(TextFormField).at(1), 'secret123');
    await tap(t, find.text('LOG IN').last);
    await t.scrollUntilVisible(
      find.text('Dar Lgharbi'),
      300,
      scrollable: mainScroll.first,
    );
    await tap(t, find.text('Dar Lgharbi'));
    expect(find.text('Closed'), findsOneWidget);
  });

  testWidgets('search finds dishes and opens them', (t) async {
    await signedInApp(t);
    await tap(t, find.text('Search dishes, restaurants'));
    expect(find.byType(SearchPage), findsOneWidget);
    await t.enterText(find.byType(TextField), 'thon');
    await t.pump(const Duration(milliseconds: 400));
    await t.pumpAndSettle();
    expect(find.text('Dishes'), findsOneWidget);
    await tap(t, find.text('Pizza Thon'));
    expect(find.byType(ItemPage), findsOneWidget);
  });

  testWidgets('category page shows popular dishes and its restaurants', (
    t,
  ) async {
    await signedInApp(t);
    await tap(t, find.text('Burger').first);
    expect(find.text('Popular Burger'), findsOneWidget);
    expect(find.text('Smash Burger'), findsOneWidget);
    expect(find.text('Burger Royal'), findsNothing); // unavailable
    expect(find.text('Pizzeria El Bahdja'), findsNothing);
  });

  testWidgets('home renders in Arabic, right-to-left', (t) async {
    await signedInApp(t, lang: 'ar');
    expect(find.text('كل الأصناف'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
