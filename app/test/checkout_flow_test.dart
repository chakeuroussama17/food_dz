import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_app/features/account/data/account_repository.dart';
import 'package:food_app/features/account/pages/address_form_page.dart';
import 'package:food_app/features/cart/cart_page.dart';
import 'package:food_app/features/orders/data/orders_repository.dart';
import 'package:food_app/features/orders/pages/my_orders_page.dart';
import 'package:food_app/features/orders/pages/order_page.dart';
import 'package:food_app/features/orders/pages/order_placed_page.dart';

import 'helpers/fake_auth.dart';

/// formatDzd output: narrow no-break space between thousands, no-break
/// space before the unit. da('2 500 DA') -> '2 500 DA'.
String da(String s) {
  final i = s.lastIndexOf(' ');
  return '${s.substring(0, i).replaceAll(' ', ' ')} ${s.substring(i + 1)}';
}

class Setup {
  Setup({bool withAddress = true, String? phone = '0550123456'}) {
    account = FakeAccountRepository();
    account.profile = Profile(
      id: 'u1',
      fullName: 'Karim Benali',
      email: 'k@mail.dz',
      phone: phone,
    );
    if (withAddress) {
      account.addressList.add(
        const Address(
          id: 'a1',
          label: AddressLabel.home,
          addressText: 'Rue Didouche 12',
          area: 'Alger Centre',
          isDefault: true,
        ),
      );
    }
    orders = FakeOrdersRepository(
      menu: catalog.items,
      restaurantNames: {'r1': 'Pizzeria El Bahdja'},
    );
  }

  final catalog = FakeCatalogRepository();
  late final FakeAccountRepository account;
  late final FakeOrdersRepository orders;
}

Future<Setup> signedIn(WidgetTester t, Setup s, {String lang = 'en'}) async {
  final repo = FakeAuthRepository()..seedUser('k@mail.dz', 'secret123');
  await pumpFoodApp(
    t,
    repo: repo,
    lang: lang,
    catalog: s.catalog,
    account: s.account,
    orders: s.orders,
  );
  await t.enterText(find.byType(TextFormField).at(0), 'k@mail.dz');
  await t.enterText(find.byType(TextFormField).at(1), 'secret123');
  await t.tap(find.text(lang == 'en' ? 'LOG IN' : 'تسجيل الدخول').last);
  await t.pumpAndSettle();
  return s;
}

Future<void> tap(WidgetTester t, Finder f) async {
  await t.ensureVisible(f);
  await t.pumpAndSettle();
  await t.tap(f);
  await t.pumpAndSettle();
}

/// Home → pizzeria → 2 × Margherita (700) + 1 × Thon (900) → cart.
Future<void> fillCartAndOpen(WidgetTester t) async {
  await tap(t, find.text('Pizzeria El Bahdja').last);
  await tap(t, find.byIcon(Icons.add_rounded).at(0));
  await tap(t, find.byIcon(Icons.add_rounded).at(0));
  await tap(t, find.byIcon(Icons.add_rounded).at(1));
  await tap(t, find.byIcon(Icons.shopping_bag_outlined).first);
  expect(find.byType(CartPage), findsOneWidget);
}

void main() {
  setUpAll(loadFonts);

  testWidgets('place an order: server prices, success page, live tracking', (
    t,
  ) async {
    final s = await signedIn(t, Setup());
    await fillCartAndOpen(t);

    // Design panel: address, phone, cash, total with the 200 DA fee.
    expect(find.text('DELIVERY ADDRESS'), findsOneWidget);
    expect(find.text('Rue Didouche 12, Alger Centre'), findsOneWidget);
    expect(find.text('0550123456'), findsOneWidget);
    expect(find.text(da('2 500 DA')), findsOneWidget); // 1400 + 900 + 200

    await tap(t, find.text('Breakdown'));
    expect(find.text(da('2 300 DA')), findsOneWidget); // subtotal
    expect(find.text(da('200 DA')), findsOneWidget);
    await t.tapAt(const Offset(20, 20)); // close the sheet
    await t.pumpAndSettle();

    await tap(t, find.text('PLACE ORDER'));
    expect(t.takeException(), isNull);

    // Only ids and quantities are sent; the total is a guard, not a price.
    final r = s.orders.requests.single;
    expect(r.restaurantId, 'r1');
    expect(r.items.map((i) => '${i.id}x${i.qty}'), ['i1x2', 'i2x1']);
    expect(r.addressId, 'a1');
    expect(r.phone, '0550123456');
    expect(r.expectedTotal, 2500);

    expect(find.byType(OrderPlacedPage), findsOneWidget);
    expect(find.text('Order placed!'), findsOneWidget);
    expect(find.text('Order #ABC231'), findsOneWidget);
    expect(find.textContaining(da('2 500 DA')), findsOneWidget);

    await tap(t, find.text('TRACK ORDER'));
    expect(find.byType(OrderPage), findsOneWidget);
    expect(find.text('Order sent'), findsOneWidget);
    expect(find.text('2×'), findsOneWidget);
    expect(find.text('Pizza Margherita'), findsOneWidget);
    await t.scrollUntilVisible(find.text('Cancel order'), 200);
    expect(find.text('Cancel order'), findsOneWidget);

    // The restaurant accepts: the page updates by itself.
    s.orders.setStatus('o1', 'accepted');
    await t.pumpAndSettle();
    expect(find.text('12:40'), findsOneWidget); // accepted time
    expect(find.text('Cancel order'), findsNothing);

    // Cart is empty after ordering.
    await t.pageBack();
    await t.pumpAndSettle();
    expect(find.byType(CartPage), findsNothing);
  });

  testWidgets('double tap after a lost response: same order, not two', (
    t,
  ) async {
    final s = await signedIn(t, Setup());
    await fillCartAndOpen(t);
    s.orders.failNext = CheckoutFailure.network;
    await tap(t, find.text('PLACE ORDER'));
    expect(find.text('No connection. Check your network.'), findsOneWidget);
    expect(find.byType(CartPage), findsOneWidget);
    await tap(t, find.text('PLACE ORDER'));
    expect(find.byType(OrderPlacedPage), findsOneWidget);
    expect(s.orders.requests.length, 2);
    expect(s.orders.requests[0].clientRef, s.orders.requests[1].clientRef);
    expect(s.orders.orders.length, 1);
  });

  testWidgets('price changed: cart refreshed, customer sees the new total', (
    t,
  ) async {
    final s = await signedIn(t, Setup());
    await fillCartAndOpen(t);
    // The restaurant raised the Thon price after it was added.
    s.catalog.priceChanges['i2'] = 1000;
    s.orders.menu = await s.catalog.itemsByIds(['i1', 'i2', 'i3']);
    await tap(t, find.text('PLACE ORDER'));
    expect(find.textContaining('Prices changed'), findsOneWidget);
    expect(find.byType(CartPage), findsOneWidget);
    expect(find.text(da('2 600 DA')), findsOneWidget);
    // Second tap with the new total goes through.
    await tap(t, find.text('PLACE ORDER'));
    expect(find.byType(OrderPlacedPage), findsOneWidget);
    expect(s.orders.orders.single.total, 2600);
  });

  testWidgets('no address yet: asked to add one first', (t) async {
    final s = await signedIn(t, Setup(withAddress: false));
    await fillCartAndOpen(t);
    expect(find.text('Add a delivery address'), findsOneWidget);
    await tap(t, find.text('PLACE ORDER'));
    expect(find.byType(AddressFormPage), findsOneWidget);
    expect(s.orders.requests, isEmpty);
  });

  testWidgets('no phone: details sheet asks for it, then the order goes', (
    t,
  ) async {
    final s = await signedIn(t, Setup(phone: null));
    await fillCartAndOpen(t);
    await tap(t, find.text('PLACE ORDER'));
    expect(find.text('Delivery details'), findsOneWidget);
    final phoneField = find.byType(TextFormField).first;
    await t.enterText(phoneField, '0661 23 45 67');
    await tap(t, find.text('SAVE'));
    expect(find.byType(OrderPlacedPage), findsOneWidget);
    expect(s.orders.requests.single.phone, '0661234567');
  });

  testWidgets('edit mode removes a dish; empty cart shows the message', (
    t,
  ) async {
    await signedIn(t, Setup());
    await fillCartAndOpen(t);
    await tap(t, find.text('EDIT').first);
    await tap(t, find.bySemanticsLabel('Delete').first);
    await tap(t, find.bySemanticsLabel('Delete').first);
    expect(find.text('Your cart is empty'), findsOneWidget);
  });

  testWidgets('my orders: ongoing / history, cancel before acceptance', (
    t,
  ) async {
    final s = await signedIn(t, Setup());
    await fillCartAndOpen(t);
    await tap(t, find.text('PLACE ORDER'));
    await tap(t, find.text('Back to home'));

    // Bottom bar → Orders.
    await tap(t, find.text('Orders').last);
    expect(find.byType(MyOrdersPage), findsOneWidget);
    expect(find.text('Pizzeria El Bahdja'), findsOneWidget);
    expect(find.text('Order sent'), findsOneWidget);

    await tap(t, find.text('Cancel'));
    await tap(t, find.text('Cancel order'));
    expect(find.text('Order cancelled'), findsOneWidget);
    expect(s.orders.orders.single.status, 'cancelled');
    expect(find.text('No ongoing orders'), findsOneWidget);
    await tap(t, find.text('History'));
    expect(find.text('Cancelled'), findsOneWidget);
  });

  testWidgets('rejected order shows the reason in red', (t) async {
    final s = await signedIn(t, Setup());
    await fillCartAndOpen(t);
    await tap(t, find.text('PLACE ORDER'));
    await tap(t, find.text('TRACK ORDER'));
    s.orders.setStatus('o1', 'rejected', reason: 'Plus de pâte à pizza');
    await t.pumpAndSettle();
    expect(find.text('Rejected'), findsOneWidget);
    expect(find.text('Reason: Plus de pâte à pizza'), findsOneWidget);
    expect(find.text('Ready'), findsNothing); // future steps hidden
  });

  testWidgets('Arabic checkout renders without overflow', (t) async {
    await signedIn(t, Setup(), lang: 'ar');
    await fillCartAndOpen(t);
    expect(find.text('عنوان التوصيل'), findsOneWidget);
    await tap(t, find.text('أرسل الطلب'));
    expect(find.byType(OrderPlacedPage), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
