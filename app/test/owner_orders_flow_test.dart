import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_app/features/restaurant_owner/data/owner_orders_repository.dart';
import 'package:food_app/features/restaurant_owner/data/owner_repository.dart';
import 'package:food_app/features/restaurant_owner/pages/owner_dashboard_page.dart';
import 'package:food_app/features/restaurant_owner/pages/owner_orders_page.dart';

import 'helpers/fake_auth.dart';

class OwnerSetup {
  final orders = FakeOwnerOrdersRepository();
  final sound = FakeAlertSound();
}

Future<OwnerSetup> ownerApp(WidgetTester t, {OwnerSetup? setup}) async {
  final s = setup ?? OwnerSetup();
  final auth = FakeAuthRepository()
    ..seedUser('o@mail.dz', 'secret123', name: 'Omar')
    ..roles['o@mail.dz'] = 'restaurant'
    ..signInDirect('o@mail.dz');
  final owner = FakeOwnerRepository()
    ..restaurant = const OwnedRestaurant(
      id: 'own1',
      slug: 'chez-omar',
      name: 'Chez Omar',
      area: 'Kouba',
      isActive: true,
      isOpen: true,
    );
  await pumpFoodApp(
    t,
    repo: auth,
    owner: owner,
    ownerOrders: s.orders,
    sound: s.sound,
  );
  return s;
}

Future<void> tap(WidgetTester t, Finder f) async {
  await t.ensureVisible(f);
  await t.pumpAndSettle();
  await t.tap(f);
  await t.pumpAndSettle();
}

Future<void> openOrders(WidgetTester t) async {
  await tap(t, find.bySemanticsLabel(RegExp('^Orders')).last);
  expect(find.byType(OwnerOrdersPage), findsOneWidget);
}

void main() {
  setUpAll(loadFonts);

  testWidgets('waiting order: dashboard counter, badge and a chime', (t) async {
    final s = OwnerSetup();
    s.orders.addIncoming();
    await ownerApp(t, setup: s);
    expect(find.byType(OwnerDashboardPage), findsOneWidget);
    // ORDER REQUEST = 01, RUNNING ORDERS = 00.
    expect(find.text('01'), findsOneWidget);
    expect(find.text('00'), findsOneWidget);
    expect(find.text('1'), findsOneWidget); // badge on the orders icon
    expect(s.sound.plays, 1);

    // Rings again every 20 s while nobody handles it.
    await t.pump(const Duration(seconds: 20));
    await t.pumpAndSettle();
    expect(s.sound.plays, 2);

    // The counter opens the New tab.
    await tap(t, find.text('01'));
    expect(find.byType(OwnerOrdersPage), findsOneWidget);
    expect(find.text('New (1)'), findsOneWidget);
    expect(find.text('#K7P2Q1'), findsOneWidget);
    expect(find.text('2× Pizza Margherita'), findsOneWidget);
    expect(find.text('Amina · Alger Centre'), findsOneWidget);
  });

  testWidgets('accept → in progress → ready, then the chime stops', (t) async {
    final s = OwnerSetup();
    s.orders.addIncoming();
    await ownerApp(t, setup: s);
    await openOrders(t);

    await tap(t, find.text('Accept'));
    expect(s.orders.calls, ['oo1:accepted:']);
    expect(find.text('Order accepted'), findsOneWidget);
    expect(find.text('New (0)'), findsOneWidget);
    expect(find.text('In progress (1)'), findsOneWidget);

    await tap(t, find.text('In progress (1)'));
    await tap(t, find.text('Ready'));
    expect(s.orders.calls.last, 'oo1:ready:');
    expect(find.text('Waiting for driver'), findsOneWidget);

    final before = s.sound.plays;
    await t.pump(const Duration(seconds: 20));
    await t.pumpAndSettle();
    expect(s.sound.plays, before); // nothing waiting any more
  });

  testWidgets('new order arrives live while the page is open', (t) async {
    final s = await ownerApp(t);
    await openOrders(t);
    expect(find.text('No new orders'), findsOneWidget);
    expect(s.sound.plays, 0);

    s.orders.addIncoming(customer: 'Yacine', notes: 'Sans oignons');
    await t.pumpAndSettle();
    expect(find.text('New (1)'), findsOneWidget);
    expect(find.text('Yacine · Alger Centre'), findsOneWidget);
    expect(find.text('“Sans oignons”'), findsOneWidget);
    expect(s.sound.plays, 1);

    // The customer cancels before we accept: it leaves the list.
    s.orders.customerCancels('oo1');
    await t.pumpAndSettle();
    expect(find.text('New (0)'), findsOneWidget);
    expect(find.text('No new orders'), findsOneWidget);
  });

  testWidgets('reject needs a reason; it goes to history', (t) async {
    final s = OwnerSetup();
    s.orders.addIncoming();
    await ownerApp(t, setup: s);
    await openOrders(t);

    await tap(t, find.text('Reject'));
    expect(find.text('Reject order'), findsWidgets);
    await tap(t, find.text('Reject order').last); // confirm, empty
    expect(find.text('Please give a reason.'), findsOneWidget);
    expect(s.orders.calls, isEmpty);

    await tap(t, find.text('Too busy right now'));
    await tap(t, find.text('Reject order').last);
    expect(s.orders.calls, ['oo1:rejected:Too busy right now']);
    expect(find.text('Order rejected'), findsOneWidget);

    await tap(t, find.text('History'));
    expect(find.text('Rejected'), findsOneWidget);
  });

  testWidgets('order sheet: customer phone, address, notes, dishes', (t) async {
    final s = OwnerSetup();
    s.orders.addIncoming(notes: '2e étage');
    await ownerApp(t, setup: s);
    await openOrders(t);
    await tap(t, find.text('#K7P2Q1'));
    expect(find.text('Order #K7P2Q1'), findsOneWidget);
    expect(find.text('0550123456'), findsOneWidget);
    expect(find.text('Rue Didouche 12, Alger Centre'), findsOneWidget);
    expect(find.text('2e étage'), findsOneWidget);
    expect(find.text('2× Pizza Margherita'), findsWidgets);
    // Accept from the sheet works too, and the sheet follows the change.
    await tap(t, find.text('Accept').last);
    expect(s.orders.calls, ['oo1:accepted:']);
    expect(
      find.text('Ready'),
      findsOneWidget,
    ); // sheet now offers the next step
  });

  testWidgets('mute: no chime for new orders', (t) async {
    final s = await ownerApp(t);
    await openOrders(t);
    await tap(t, find.byIcon(Icons.volume_up_rounded));
    expect(find.byIcon(Icons.volume_off_rounded), findsOneWidget);
    s.orders.addIncoming();
    await t.pumpAndSettle();
    expect(find.text('New (1)'), findsOneWidget);
    expect(s.sound.plays, 0);
  });

  testWidgets('dashboard: confirm the money the driver brought', (t) async {
    final s = OwnerSetup();
    s.orders.cash.add(
      CashToReceive(
        orderId: 'oo9',
        code: 'CASH99',
        amount: 1400,
        deliveredAt: DateTime(2026, 11, 9, 13, 5),
        driverName: 'Rachid',
        driverPhone: '0661000001',
        handedAt: DateTime(2026, 11, 9, 13, 30),
      ),
    );
    await ownerApp(t, setup: s);
    expect(find.text('Money to receive from drivers'), findsOneWidget);
    expect(find.text('Rachid · 0661000001'), findsOneWidget);
    expect(find.text('The driver says it was handed over'), findsOneWidget);
    await tap(t, find.text('Received'));
    expect(find.textContaining('Confirm you received'), findsOneWidget);
    await tap(t, find.text('Received').last);
    expect(s.orders.calls, ['cash:oo9']);
    expect(find.text('Receipt confirmed'), findsOneWidget);
    expect(find.text('Money to receive from drivers'), findsNothing);
  });

  testWidgets('Arabic orders page renders without overflow', (t) async {
    final s = OwnerSetup();
    s.orders.addIncoming(notes: 'بدون بصل');
    final auth = FakeAuthRepository()
      ..seedUser('o@mail.dz', 'secret123', name: 'Omar')
      ..roles['o@mail.dz'] = 'restaurant'
      ..signInDirect('o@mail.dz');
    final owner = FakeOwnerRepository()
      ..restaurant = const OwnedRestaurant(
        id: 'own1',
        slug: 'chez-omar',
        name: 'Chez Omar',
        isActive: true,
        isOpen: true,
      );
    await pumpFoodApp(
      t,
      lang: 'ar',
      repo: auth,
      owner: owner,
      ownerOrders: s.orders,
      sound: s.sound,
    );
    await tap(t, find.bySemanticsLabel(RegExp('^الطلبات')).last);
    expect(find.byType(OwnerOrdersPage), findsOneWidget);
    expect(find.text('جديدة (1)'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
