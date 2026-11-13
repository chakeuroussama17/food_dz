import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_app/features/restaurant_owner/data/owner_orders_repository.dart';
import 'package:food_app/features/restaurant_owner/data/owner_repository.dart';
import 'package:food_app/portal/pages/portal_dashboard_page.dart';
import 'package:food_app/portal/pages/portal_login_page.dart';
import 'package:food_app/portal/pages/portal_orders_page.dart';
import 'package:food_app/portal/pages/portal_reports_page.dart';
import 'package:food_app/portal/portal_app.dart';
import 'package:food_app/portal/report_math.dart';
import 'package:go_router/go_router.dart';

import 'helpers/fake_auth.dart';

const _desk = Size(1440, 1000);
var _n = 0;

OwnerOrder order({
  required DateTime at,
  String status = 'delivered',
  String outlet = 'own1',
  String customer = 'Amina',
  String key = 'c1',
  String area = 'Kouba',
  int food = 1400,
  String? reason,
}) {
  _n++;
  final accepted = status == 'placed' || status == 'rejected'
      ? null
      : at.add(const Duration(seconds: 40));
  return OwnerOrder(
    id: 'p$_n',
    code: 'PX$_n',
    status: status,
    customerName: customer,
    customerPhone: '0550123456',
    addressText: 'Rue Didouche 12',
    area: area,
    foodTotal: food,
    deliveryFee: 200,
    total: food + 200,
    placedAt: at,
    acceptedAt: accepted,
    readyAt: accepted?.add(const Duration(minutes: 18)),
    deliveredAt: status == 'delivered'
        ? at.add(const Duration(hours: 1))
        : null,
    commissionAmount: status == 'delivered' ? (food * .08).round() : null,
    rejectReason: reason,
    restaurantId: outlet,
    restaurantName: outlet == 'own1' ? 'Chez Omar' : 'Chez Omar Hydra',
    customerKey: key,
    items: [
      OrderLine(
        name: 'Pizza Margherita',
        unitPrice: food ~/ 2,
        quantity: 2,
        lineTotal: food,
      ),
    ],
  );
}

DateTime ago(int days, int hour) {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day - days, hour);
}

class Portal {
  Portal(this.auth, this.owner, this.orders, this.files);
  final FakeAuthRepository auth;
  final FakeOwnerRepository owner;
  final FakeOwnerOrdersRepository orders;
  final FakeFileOutput files;
}

Future<Portal> portal(
  WidgetTester t, {
  bool signedIn = true,
  String role = 'owner',
  List<OwnerOrder> past = const [],
  String lang = 'en',
  bool dark = false,
}) async {
  final auth = FakeAuthRepository()
    ..seedUser('o@mail.dz', 'secret123', name: 'Omar')
    ..roles['o@mail.dz'] = 'restaurant';
  if (signedIn) auth.signInDirect('o@mail.dz');
  final owner = FakeOwnerRepository()
    ..restaurant = OwnedRestaurant(
      id: 'own1',
      slug: 'chez-omar',
      name: 'Chez Omar',
      area: 'Kouba',
      isActive: true,
      isOpen: true,
      role: role,
    )
    ..otherOutlets.add(
      OwnedRestaurant(
        id: 'own2',
        slug: 'chez-omar-hydra',
        name: 'Chez Omar Hydra',
        area: 'Hydra',
        isActive: true,
        role: role,
      ),
    )
    ..teams['own1'] = [
      const TeamMember(
        userId: 'u-o',
        name: 'Omar',
        email: 'o@mail.dz',
        role: 'owner',
      ),
    ]
    ..knownEmails['samia@mail.dz'] = 'Samia';
  final orders = FakeOwnerOrdersRepository()..reportOrders.addAll(past);
  final files = FakeFileOutput();
  await pumpFoodApp(
    t,
    repo: auth,
    owner: owner,
    ownerOrders: orders,
    files: files,
    portal: true,
    size: _desk,
    lang: lang,
    dark: dark,
  );
  return Portal(auth, owner, orders, files);
}

Future<void> go(WidgetTester t, String path) async {
  GoRouter.of(t.element(find.byType(Scaffold).first)).go(path);
  await t.pumpAndSettle();
}

void main() {
  setUpAll(loadFonts);

  group('portalRedirect', () {
    test('login, loading, partners only', () {
      expect(portalRedirect(path: '/', signedIn: false), '/login');
      expect(portalRedirect(path: '/login', signedIn: false), isNull);
      expect(portalRedirect(path: '/orders', signedIn: true), '/loading');
      expect(
        portalRedirect(path: '/', signedIn: true, role: 'customer'),
        '/not-partner',
      );
      expect(
        portalRedirect(path: '/login', signedIn: true, role: 'restaurant'),
        '/',
      );
      expect(
        portalRedirect(path: '/reports', signedIn: true, role: 'restaurant'),
        isNull,
      );
    });
  });

  group('report maths', () {
    final from = DateTime(2026, 11, 2);
    final to = DateTime(2026, 11, 9);

    test('new vs returning uses the look-back', () {
      final rows = [
        order(at: DateTime(2026, 10, 20, 12), key: 'a'), // before
        order(at: DateTime(2026, 11, 3, 12), key: 'a'), // returning
        order(at: DateTime(2026, 11, 3, 13), key: 'b'), // new
        order(at: DateTime(2026, 11, 5, 13), key: 'b'), // returning
        order(at: DateTime(2026, 11, 6, 13), key: 'c'), // new
      ];
      final s = customerSplit(rows, from, to);
      expect(s.newOrders, 2);
      expect(s.returningOrders, 2);
      expect(s.customers, 3);
    });

    test('hour x day grid averages per weekday', () {
      // Two Mondays in a 14-day period, 1000 DA on one of them at 13h.
      final g = salesByHourAndDay(
        [order(at: DateTime(2026, 11, 2, 13), food: 1000)],
        DateTime(2026, 11, 2),
        DateTime(2026, 11, 16),
      );
      expect(g[13][2], 500); // Monday = column 2 (Saturday first)
      expect(g[12].every((v) => v == 0), isTrue);
    });

    test('reasons, prep by day, areas', () {
      final rows = [
        order(
          at: DateTime(2026, 11, 3, 12),
          status: 'rejected',
          reason: 'Fermé',
        ),
        order(
          at: DateTime(2026, 11, 3, 13),
          status: 'rejected',
          reason: 'Fermé',
        ),
        order(at: DateTime(2026, 11, 4, 13), status: 'cancelled', reason: 'X'),
        order(at: DateTime(2026, 11, 4, 14), area: 'Hydra'),
      ];
      expect(reasons(rows, from, to, (r) => r), [('Fermé', 2), ('X', 1)]);
      final prep = prepByDay(rows, from, to);
      expect(prep.length, 7);
      expect(prep[2], 18);
      expect(prep[0], isNull);
      expect(topAreas(rows, from, to).first, ('Kouba', 3));
    });

    test('previous month', () {
      expect(previousMonth(DateTime(2026, 1, 15)), (
        DateTime(2025, 12),
        DateTime(2026, 1),
      ));
    });
  });

  testWidgets('login, then the dashboard with waiting orders', (t) async {
    final p = await portal(t, signedIn: false);
    expect(find.byType(PortalLoginPage), findsOneWidget);
    await t.enterText(find.byType(TextFormField).at(0), 'o@mail.dz');
    await t.enterText(find.byType(TextFormField).at(1), 'secret123');
    await t.tap(find.text('LOG IN'));
    await t.pumpAndSettle();
    expect(find.byType(PortalDashboardPage), findsOneWidget);
    expect(p.auth.calls, contains('signIn:o@mail.dz'));

    p.orders.addIncoming();
    // Live updates are grouped for 400 ms.
    await t.pump(const Duration(milliseconds: 500));
    await t.pumpAndSettle();
    expect(find.text('No order is waiting.'), findsNothing);
    expect(find.textContaining('#K7P2Q1'), findsOneWidget);
    await t.tap(find.text('Accept'));
    await t.pumpAndSettle();
    expect(p.orders.calls.single, startsWith('oo1:accepted'));
    expect(find.text('No order is waiting.'), findsOneWidget);
  });

  testWidgets('customers and drivers see the partners-only page', (t) async {
    final auth = FakeAuthRepository()
      ..seedUser('c@mail.dz', 'secret123')
      ..signInDirect('c@mail.dz');
    await pumpFoodApp(t, repo: auth, portal: true, size: _desk);
    expect(find.byType(PortalNotPartnerPage), findsOneWidget);
  });

  testWidgets('staff accounts are sent back to the app', (t) async {
    await portal(t, role: 'staff');
    expect(
      find.textContaining('Your staff access works in the app'),
      findsOneWidget,
    );
  });

  testWidgets('dashboard: today, outlets closed, week summary', (t) async {
    final early = DateTime.now().hour == 0;
    await portal(
      t,
      past: [
        if (!early) order(at: ago(0, 0)),
        if (!early) order(at: ago(0, 0), status: 'rejected', reason: 'Fermé'),
        order(at: ago(1, 12), food: 2000),
      ],
    );
    if (!early) {
      expect(find.text('2'), findsWidgets); // orders today
    }
    expect(find.text('Outlets closed now'), findsOneWidget);
    expect(find.text('Business summary'), findsOneWidget);
    await t.tap(find.text('Last week'));
    await t.pumpAndSettle();
    await t.tap(find.byType(Switch).first);
    await t.pumpAndSettle();
    expect(find.text('Previous period'), findsWidgets);
    expect(t.takeException(), isNull);
  });

  testWidgets('orders: table, outlet filter, side panel, CSV', (t) async {
    final p = await portal(
      t,
      past: [
        order(at: ago(0, 0), customer: 'Amina'),
        order(at: ago(0, 0), customer: 'Bilal', outlet: 'own2'),
      ],
    );
    await go(t, '/orders');
    expect(find.byType(PortalOrdersPage), findsOneWidget);
    if (DateTime.now().hour > 0) {
      expect(find.text('Amina'), findsOneWidget);
      expect(find.text('Bilal'), findsOneWidget);

      // Only the second outlet.
      await t.tap(find.text('2/2'));
      await t.pumpAndSettle();
      await t.tap(
        find.descendant(
          of: find.byType(CheckboxMenuButton),
          matching: find.text('Chez Omar'),
        ),
      );
      await t.pumpAndSettle();
      await t.tapAt(const Offset(5, 5));
      await t.pumpAndSettle();
      expect(find.text('Amina'), findsNothing);
      expect(find.text('Bilal'), findsOneWidget);

      await t.tap(find.text('Bilal'));
      await t.pumpAndSettle();
      expect(find.byType(OrderPanel), findsOneWidget);
      expect(find.text('Order details'), findsOneWidget);
      expect(find.textContaining('Accepted in 40 s'), findsOneWidget);
      expect(find.text('Download receipt'), findsOneWidget);
      await t.tap(find.byType(BackButtonIcon));
      await t.pumpAndSettle();
      expect(find.byType(OrderPanel), findsNothing);

      await t.tap(find.text('Export CSV'));
      await t.pumpAndSettle();
      expect(p.files.saved.length, 1);
    }
  });

  testWidgets('reports: sales, operations and customers tabs', (t) async {
    await portal(
      t,
      past: [
        for (var d = 1; d <= 5; d++) order(at: ago(d, 13), key: 'k$d'),
        order(at: ago(2, 20), key: 'k1', area: 'Hydra'),
        order(at: ago(3, 20), status: 'rejected', reason: 'Fermé'),
        order(at: ago(40, 12), key: 'k2'),
      ],
    );
    await go(t, '/reports');
    expect(find.byType(PortalReportsPage), findsOneWidget);
    expect(find.text('Sales by hour'), findsOneWidget);
    expect(find.text('Best sellers'), findsOneWidget);

    await t.tap(find.text('Operations'));
    await t.pumpAndSettle();
    expect(find.text('Refusals and cancellations by reason'), findsOneWidget);
    expect(find.text('Fermé'), findsOneWidget);

    await t.tap(find.text('Customers'));
    await t.pumpAndSettle();
    expect(find.text('New vs returning customers'), findsOneWidget);
    // k1 and k2 had ordered before: 2 returning of 7 orders.
    expect(
      find.textContaining('Orders from returning customers (29%)'),
      findsOneWidget,
    );
    expect(t.takeException(), isNull);
  });

  testWidgets('team: add by email, errors, role change, last owner', (t) async {
    final p = await portal(t);
    await go(t, '/team');
    expect(find.text('Omar'), findsOneWidget);

    Future<void> add(String email) async {
      await t.tap(find.text('Add member').first);
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextFormField), email);
      await t.tap(find.text('Add member').last);
      await t.pumpAndSettle();
    }

    await add('nobody@mail.dz');
    expect(find.textContaining('No account with this email'), findsOneWidget);
    await t.pump(const Duration(seconds: 5));
    await t.pumpAndSettle();

    await add('samia@mail.dz');
    expect(find.text('Samia'), findsOneWidget);
    expect(p.owner.teams['own1']!.last.role, 'staff');

    // The only owner can't step down.
    await t.tap(find.text('Owner').last);
    await t.pumpAndSettle();
    await t.tap(find.text('Manager').last);
    await t.pumpAndSettle();
    expect(find.text('An outlet needs at least one owner.'), findsOneWidget);
  });

  testWidgets('outlets: add one and switch it on', (t) async {
    final p = await portal(t);
    await go(t, '/outlets');
    expect(find.text('Chez Omar Hydra'), findsOneWidget);
    await t.tap(find.text('Add outlet').first);
    await t.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await t.enterText(fields.at(0), 'Chez Omar Bab Ezzouar');
    await t.enterText(fields.at(1), '021 23 45 67');
    await t.enterText(fields.at(2), 'Cité 5 juillet');
    await t.tap(find.text('Add outlet').last);
    await t.pumpAndSettle();
    expect(p.owner.lastRegistration?.name, 'Chez Omar Bab Ezzouar');
  });

  testWidgets('portal renders in Arabic and dark without errors', (t) async {
    await portal(
      t,
      lang: 'ar',
      dark: true,
      past: [order(at: ago(1, 13))],
    );
    for (final path in [
      '/',
      '/orders',
      '/reports',
      '/invoices',
      '/outlets',
      '/team',
      '/menu',
    ]) {
      await go(t, path);
      expect(t.takeException(), isNull, reason: path);
    }
  });
}
