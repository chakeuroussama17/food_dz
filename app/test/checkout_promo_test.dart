import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_app/features/orders/data/orders_repository.dart';
import 'package:go_router/go_router.dart';

import 'checkout_flow_test.dart'
    show Setup, da, fillCartAndOpen, placeOrder, signedIn, tap;
import 'helpers/fake_auth.dart';

Future<void> reveal(WidgetTester t, Finder f) async {
  if (f.evaluate().isEmpty) {
    await t.scrollUntilVisible(
      f,
      200,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await t.ensureVisible(f);
  await t.pumpAndSettle();
}

void main() {
  setUpAll(loadFonts);

  test('price: 1% tax after discount, rounded like the database', () {
    final p = OrderPrice(food: 1400, fee: 200, taxRate: 0.01, discount: 250);
    expect(p.tax, 12); // 11.5 → 12
    expect(p.total, 1400 - 250 + 12 + 200);
    expect(OrderPrice(food: 2300, fee: 200, taxRate: 0.01).tax, 23);
    // A discount can't go below zero food.
    expect(
      OrderPrice(food: 300, fee: 200, taxRate: 0, discount: 500).total,
      200,
    );
  });

  testWidgets('checkout: tax, a promo code, cash only, the total sent', (
    t,
  ) async {
    final s = Setup();
    s.catalog.taxRateValue = 0.01;
    s.orders
      ..taxRate = 0.01
      ..promos['BIENVENUE'] = ('percent', 10, 0)
      ..promos['GROS'] = ('amount', 500, 5000);
    await signedIn(t, s);
    await fillCartAndOpen(t); // food 2300, fee 200

    // Tax shown, in the total: 2300 + 23 + 200.
    await reveal(t, find.text('Tax (1 %)'));
    expect(find.text(da('23 DA')), findsOneWidget);
    expect(find.text('PLACE ORDER · ${da('2 523 DA')}'), findsOneWidget);

    // Card and CCP are announced but can't be chosen.
    await reveal(t, find.text('CCP / BaridiMob'));
    expect(find.text('Coming soon'), findsNWidgets(2));
    await t.tap(find.text('CIB / Edahabia card'));
    await t.pumpAndSettle();

    // A code with a minimum not reached, then a good one.
    await reveal(t, find.byType(TextField).first);
    await t.enterText(find.byType(TextField).first, 'gros');
    await tap(t, find.text('Apply'));
    expect(find.text('Minimum order amount not reached'), findsOneWidget);
    await t.enterText(find.byType(TextField).first, 'bienvenue');
    await tap(t, find.text('Apply'));
    expect(find.text('Code BIENVENUE applied'), findsOneWidget);
    // −230, tax on 2070 = 21 (20.7), total 2070 + 21 + 200 = 2291.
    await reveal(t, find.text('You save ${da('230 DA')}'));
    expect(find.text('PLACE ORDER · ${da('2 291 DA')}'), findsOneWidget);

    await tap(t, placeOrder);
    final r = s.orders.requests.single;
    expect(r.promoCode, 'BIENVENUE');
    expect(r.paymentMethod, 'cash');
    expect(r.expectedTotal, 2291);
    final o = s.orders.orders.single;
    expect(o.discountAmount, 230);
    expect(o.taxAmount, 21);

    // The order page shows the discount and the tax.
    await tap(t, find.text('TRACK ORDER'));
    await reveal(t, find.text('Discount (BIENVENUE)'));
    expect(find.text('−${da('230 DA')}'), findsOneWidget);
    expect(find.text('Tax'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('removing a code puts the full price back', (t) async {
    final s = Setup();
    s.orders.promos['MOINS100'] = ('amount', 100, 0);
    await signedIn(t, s);
    await fillCartAndOpen(t);
    await reveal(t, find.byType(TextField).first);
    await t.enterText(find.byType(TextField).first, 'moins100');
    await tap(t, find.text('Apply'));
    expect(find.text('PLACE ORDER · ${da('2 400 DA')}'), findsOneWidget);
    await tap(t, find.text('Remove'));
    expect(find.text('PLACE ORDER · ${da('2 500 DA')}'), findsOneWidget);
    await tap(t, find.text('Apply')); // empty: nothing happens
    expect(s.orders.requests, isEmpty);
  });

  testWidgets('admin creates, edits and turns off a code', (t) async {
    final promos = FakePromoRepository();
    final auth = FakeAuthRepository()
      ..seedUser('a@mail.dz', 'secret123', name: 'Admin')
      ..roles['a@mail.dz'] = 'admin'
      ..signInDirect('a@mail.dz');
    await pumpFoodApp(
      t,
      repo: auth,
      promos: promos,
      size: const Size(1100, 900),
    );
    GoRouter.of(t.element(find.byType(Scaffold).first)).go('/admin/promos');
    await t.pumpAndSettle();
    expect(find.text('No codes yet'), findsOneWidget);

    await tap(t, find.text('New code'));
    final fields = find.byType(TextField);
    await t.enterText(fields.at(0), 'ete25');
    await t.enterText(fields.at(1), '95'); // too much
    await tap(t, find.text('SAVE'));
    expect(find.text('Check the values (percentage 1–90)'), findsOneWidget);
    await t.enterText(fields.at(1), '25');
    await t.enterText(fields.at(2), '400'); // cap
    await tap(t, find.text('SAVE'));
    expect(promos.calls.last, 'save:ETE25:percent:25:platform');
    expect(find.text('ETE25'), findsOneWidget);
    expect(find.text('−25%'), findsOneWidget);

    await t.tap(find.byType(Switch).first);
    await t.pumpAndSettle();
    expect(promos.calls.last, 'active:p1:false');
    expect(find.textContaining('Off'), findsOneWidget);

    // Fixed amount, paid by the restaurant.
    await tap(t, find.text('ETE25'));
    await tap(t, find.text('Fixed amount'));
    await tap(t, find.text('The restaurant'));
    await t.enterText(find.byType(TextField).at(1), '300');
    await tap(t, find.text('SAVE'));
    expect(promos.calls.last, 'save:ETE25:amount:300:restaurant');
    expect(t.takeException(), isNull);
  });
}
