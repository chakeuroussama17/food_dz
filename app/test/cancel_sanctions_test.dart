import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_app/features/admin/data/admin_models.dart';
import 'package:food_app/features/admin/pages/admin_customers_page.dart';
import 'package:food_app/features/sanctions/sanctions_repository.dart';
import 'package:go_router/go_router.dart';

import 'checkout_flow_test.dart'
    show Setup, fillCartAndOpen, placeOrder, signedIn;
import 'helpers/fake_auth.dart';
import 'owner_orders_flow_test.dart' show OwnerSetup, ownerApp, openOrders;

Future<void> tap(WidgetTester t, Finder f) async {
  await t.ensureVisible(f);
  await t.pumpAndSettle();
  await t.tap(f);
  await t.pumpAndSettle();
}

Future<void> go(WidgetTester t, String path) async {
  GoRouter.of(t.element(find.byType(Scaffold).first)).go(path);
  await t.pumpAndSettle();
}

void main() {
  setUpAll(loadFonts);

  testWidgets('customer: after acceptance, a request with a reason', (t) async {
    final s = await signedIn(t, Setup());
    await fillCartAndOpen(t);
    await tap(t, placeOrder);
    await tap(t, find.text('TRACK ORDER'));
    s.orders.setStatus('o1', 'accepted');
    await t.pumpAndSettle();

    await t.scrollUntilVisible(find.text('Cancel order'), 200);
    await tap(t, find.text('Cancel order'));
    expect(find.text('Ask to cancel'), findsOneWidget);
    // No reason yet: the button waits.
    await tap(t, find.byKey(const Key('confirm-cancel')));
    expect(find.text('Ask to cancel'), findsOneWidget);
    await tap(t, find.text('Wrong address'));
    await t.enterText(find.byType(TextField).last, 'Wrong building');
    await tap(t, find.byKey(const Key('confirm-cancel')));
    expect(
      find.text('Request sent: the restaurant will answer.'),
      findsOneWidget,
    );
    expect(s.orders.cancelCalls.single, 'o1:wrong_address:Wrong building');
    expect(s.orders.orders.single.status, 'accepted');

    await t.pump(const Duration(seconds: 5));
    await t.pumpAndSettle();
    await t.scrollUntilVisible(find.byKey(const Key('cancel-note')), -200);
    expect(
      find.text('Cancellation requested. The restaurant will answer.'),
      findsOneWidget,
    );
    expect(find.text('Cancel order'), findsNothing); // one request only

    // The restaurant refuses: the customer sees it, the order goes on.
    s.orders.setStatus('o1', 'accepted', request: 'refused');
    await t.pumpAndSettle();
    expect(find.textContaining('The restaurant refused'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('restaurant: sees the request, accepts it', (t) async {
    final s = OwnerSetup();
    final o = s.orders.addIncoming();
    await ownerApp(t, setup: s);
    await openOrders(t);
    s.orders.setStatus(o.id, 'accepted');
    s.orders.customerAsksCancel(o.id, reason: 'too_long', note: 'Sorry');
    await t.pumpAndSettle();
    await tap(t, find.text('In progress (1)'));
    expect(find.byKey(const Key('cancel-request')), findsOneWidget);
    expect(find.text('The customer asks to cancel'), findsOneWidget);
    expect(find.textContaining('It’s taking too long'), findsOneWidget);
    expect(find.textContaining('“Sorry”'), findsOneWidget);

    await tap(t, find.byKey(const Key('accept-cancel')));
    expect(s.orders.calls.last, 'cancelRequest:${o.id}:true');
    expect(
      find.text('Order cancelled at the customer’s request'),
      findsOneWidget,
    );
    expect(s.orders.orders.single.status, 'cancelled');
    expect(t.takeException(), isNull);
  });

  testWidgets('suspended: only the reason, the date and log out', (t) async {
    final sanctions = FakeSanctionsRepository()
      ..current = Sanction(
        id: 3,
        kind: 'suspension',
        reason: 'fake_orders',
        message: 'Three fake orders this week.',
        endsAt: DateTime(2026, 12, 1, 18, 30),
      );
    final auth = FakeAuthRepository()
      ..seedUser('k@mail.dz', 'secret123', name: 'Karim')
      ..signInDirect('k@mail.dz');
    await pumpFoodApp(t, repo: auth, sanctions: sanctions);
    expect(find.byKey(const Key('restricted')), findsOneWidget);
    expect(find.text('Account suspended'), findsOneWidget);
    expect(find.text('Fake orders'), findsOneWidget);
    expect(find.text('Three fake orders this week.'), findsOneWidget);
    expect(find.textContaining('1 December 2026'), findsOneWidget);
    await tap(t, find.text('Log out'));
    expect(auth.currentUser, isNull);
  });

  testWidgets('warning: shown once over the app', (t) async {
    final sanctions = FakeSanctionsRepository()
      ..current = const Sanction(
        id: 9,
        kind: 'warning',
        reason: 'too_many_cancellations',
      );
    final auth = FakeAuthRepository()
      ..seedUser('k@mail.dz', 'secret123', name: 'Karim')
      ..signInDirect('k@mail.dz');
    await pumpFoodApp(t, repo: auth, sanctions: sanctions);
    await go(t, '/home');
    expect(find.byKey(const Key('warning')), findsOneWidget);
    expect(find.text('Too many cancellations'), findsOneWidget);
    await tap(t, find.text('I understand'));
    expect(sanctions.acknowledged, [9]);
    expect(find.byKey(const Key('warning')), findsNothing);
  });

  testWidgets('admin: watchlist, customer sheet, suspend, lift, CSV', (
    t,
  ) async {
    final sanctions = FakeSanctionsRepository()
      ..watch = const [
        WatchlistEntry(
          userId: 'c2',
          fullName: 'Yacine',
          email: 'y@mail.dz',
          cancels30d: 4,
          openReports: 1,
        ),
      ];
    final admin = FakeAdminRepository()
      ..customerList = [
        AdminCustomer(
          id: 'c1',
          fullName: 'Amina Benali',
          email: 'a@mail.dz',
          phone: '0661000001',
          wilaya: 16,
          commune: 'Kouba',
          gender: 'female',
          birthDate: DateTime(1998, 5, 2),
          lastDevice: 'Samsung SM-A155F',
          ordersCount: 7,
          deliveredCount: 6,
          cancelledCount: 1,
          spent: 12400,
        ),
      ]
      ..insights = const CustomerInsights(
        customers: 120,
        new7d: 14,
        active7d: 61,
        active1d: 22,
        ordered: 80,
        profileDone: 45,
        wilaya: {'16': 70, '31': 20, 'unknown': 30},
        gender: {'female': 40, 'male': 50, 'unknown': 30},
      );
    final files = FakeFileOutput();
    final auth = FakeAuthRepository()
      ..seedUser('a@mail.dz', 'secret123', name: 'Admin')
      ..roles['a@mail.dz'] = 'admin'
      ..signInDirect('a@mail.dz');
    await pumpFoodApp(
      t,
      repo: auth,
      admin: admin,
      sanctions: sanctions,
      files: files,
      size: const Size(1200, 1000),
    );
    await go(t, '/admin/customers');
    expect(find.text('120'), findsOneWidget);
    expect(find.text('+14'), findsOneWidget);
    expect(find.text('16 - Alger'), findsOneWidget);

    // Watchlist.
    await tap(t, find.text('Watchlist (1)'));
    expect(find.text('Yacine'), findsOneWidget);
    expect(find.textContaining('4 cancellations in 30 days'), findsOneWidget);

    // Customer sheet: data, then a 7-day suspension.
    await tap(t, find.text('All'));
    await tap(t, find.byKey(const Key('customer:c1')));
    expect(find.text('Samsung SM-A155F'), findsOneWidget);
    expect(find.text('Kouba'), findsOneWidget);
    await tap(t, find.byKey(const Key('sanction:suspension')));
    await tap(t, find.byKey(const Key('sanction-reason')));
    await tap(t, find.text('Fake orders').last);
    await tap(t, find.byKey(const Key('days:7')));
    await t.enterText(
      find.byKey(const Key('sanction-message')),
      'Fake orders again',
    );
    await tap(t, find.byKey(const Key('sanction-save')));
    expect(
      sanctions.calls.last,
      'suspension:c1:fake_orders:7:Fake orders again',
    );
    expect(find.text('Suspension'), findsOneWidget); // in the history
    await tap(t, find.byKey(const Key('lift:1')));
    expect(sanctions.calls.last, 'lift:1');

    // CSV with everything, English column names.
    Navigator.of(t.element(find.byType(ListView).last)).pop();
    await t.pumpAndSettle();
    await tap(t, find.byKey(const Key('export-customers')));
    final csv = String.fromCharCodes(files.saved.values.single.skip(3));
    expect(
      csv,
      startsWith('id;name;email;phone;signed_up;birth_date;age;gender;wilaya'),
    );
    expect(csv, contains('c1;Amina Benali;a@mail.dz;0661000001'));
    expect(csv, contains(';female;16;Kouba;'));
    expect(t.takeException(), isNull);
  });

  test('customers CSV escapes formulas and separators', () {
    final csv = customersCsv([
      const AdminCustomer(id: 'x', fullName: '=HYPERLINK("a")', email: 'a;b'),
    ]);
    expect(csv.split('\r\n')[1], startsWith('x;"\'=HYPERLINK(""a"")";"a;b"'));
  });
}
