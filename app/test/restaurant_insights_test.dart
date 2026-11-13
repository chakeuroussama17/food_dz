import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_app/core/widgets/widgets.dart';
import 'package:food_app/features/restaurant_owner/data/owner_orders_repository.dart';
import 'package:food_app/features/restaurant_owner/data/owner_repository.dart';
import 'package:food_app/features/restaurant_owner/insights/insights.dart';
import 'package:food_app/features/restaurant_owner/insights/orders_csv.dart';
import 'package:food_app/features/restaurant_owner/pages/owner_account_page.dart';
import 'package:food_app/features/restaurant_owner/pages/owner_insights_page.dart';
import 'package:food_app/features/restaurant_owner/pages/owner_orders_table_page.dart';
import 'package:food_app/features/restaurant_owner/widgets/owner_widgets.dart';
import 'package:food_app/core/utils/money.dart';
import 'package:food_app/l10n/app_localizations.dart';

import 'helpers/fake_auth.dart';

var _n = 0;

final vertical = find
    .byWidgetPredicate(
      (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
    )
    .first;

/// A tab of the restaurant bottom bar.
Finder nav(String label) => find.descendant(
  of: find.byType(OwnerBottomBar),
  matching: find.bySemanticsLabel(label),
);

/// A past order of the pizzeria.
OwnerOrder order({
  required DateTime at,
  String status = 'delivered',
  int food = 1400,
  int? commission,
  String customer = 'Amina',
  List<OrderLine>? items,
  Duration? accept,
  Duration? prep,
  String? reason,
}) {
  _n++;
  final accepted = status == 'rejected' && accept == null
      ? null
      : at.add(accept ?? const Duration(minutes: 2));
  return OwnerOrder(
    id: 'r$_n',
    code: 'C$_n',
    status: status,
    customerName: customer,
    customerPhone: '',
    addressText: '',
    area: 'Kouba',
    foodTotal: food,
    deliveryFee: 200,
    total: food + 200,
    placedAt: at,
    acceptedAt: accepted,
    readyAt: accepted?.add(prep ?? const Duration(minutes: 20)),
    deliveredAt: status == 'delivered'
        ? at.add(const Duration(hours: 1))
        : null,
    commissionAmount: status == 'delivered'
        ? (commission ?? (food * 0.08).round())
        : null,
    rejectReason: reason,
    driverName: status == 'delivered' ? 'Rachid' : null,
    items:
        items ??
        [
          OrderLine(
            name: 'Pizza Margherita',
            unitPrice: food ~/ 2,
            quantity: 2,
            lineTotal: food,
          ),
        ],
  );
}

void main() {
  final from = DateTime(2026, 11, 2); // a Monday
  final to = DateTime(2026, 11, 9);

  group('Insights.compute', () {
    test('sales, outcomes, basket, acceptance, prep and response', () {
      final i = Insights.compute(
        [
          order(at: DateTime(2026, 11, 2, 12, 30), food: 1000, commission: 80),
          order(
            at: DateTime(2026, 11, 2, 13, 10),
            food: 2000,
            commission: 160,
            accept: const Duration(minutes: 4),
            prep: const Duration(minutes: 30),
          ),
          order(at: DateTime(2026, 11, 3, 20), status: 'rejected', food: 900),
          order(at: DateTime(2026, 11, 4, 20), status: 'cancelled'),
          order(at: DateTime(2026, 11, 8, 21), status: 'accepted'),
          // Outside the period: ignored.
          order(at: DateTime(2026, 11, 9, 0, 5)),
        ],
        from,
        to,
      );
      expect(i.orders, 5);
      expect(i.delivered, 2);
      expect(i.rejected, 1);
      expect(i.cancelled, 1);
      expect(i.inProgress, 1);
      expect(i.sales, 3000);
      expect(i.commission, 240);
      expect(i.net, 2760);
      expect(i.avgBasket, 1500);
      expect(i.lostSales, 900);
      // 4 accepted (2 delivered, the cancelled one, the running one), 1 refused.
      expect(i.acceptanceRate, closeTo(0.8, 1e-9));
      expect(i.avgPrepMinutes, 23); // (20 + 30 + 20 + 20) / 4 = 22.5
      expect(i.avgResponseMinutes, closeTo(2.5, 1e-9));
    });

    test('one point per day, hours, Saturday-first weekdays, best sellers', () {
      final burger = OrderLine(
        name: 'Burger',
        unitPrice: 500,
        quantity: 3,
        lineTotal: 1500,
      );
      final i = Insights.compute(
        [
          order(at: DateTime(2026, 11, 2, 13), food: 1000),
          order(at: DateTime(2026, 11, 2, 13, 40), food: 1500, items: [burger]),
          order(at: DateTime(2026, 11, 7, 19), food: 1500, items: [burger]),
        ],
        from,
        to,
      );
      expect(i.days.length, 7);
      expect(i.days.first.day, DateTime(2026, 11, 2));
      expect(i.days.first.sales, 2500);
      expect(i.days.first.orders, 2);
      expect(i.days[1].sales, 0);
      expect(i.byHour[13], 2);
      expect(i.peakHour, 13);
      // Monday = index 2 (Sat 0, Sun 1), Saturday = index 0.
      expect(i.byWeekday[2], 2);
      expect(i.byWeekday[0], 1);
      expect(i.topDishes.first.name, 'Burger');
      expect(i.topDishes.first.quantity, 6);
      expect(i.topDishes.first.sales, 3000);
    });

    test('empty period', () {
      final i = Insights.compute(const [], from, to);
      expect(i.orders, 0);
      expect(i.avgBasket, 0);
      expect(i.acceptanceRate, isNull);
      expect(i.avgPrepMinutes, isNull);
      expect(i.peakHour, isNull);
      expect(tipsFor(i, i).single.kind, TipKind.noOrders);
    });
  });

  test('percentChange', () {
    expect(percentChange(150, 100), 50);
    expect(percentChange(50, 100), -50);
    expect(percentChange(10, 0), isNull);
  });

  test('tips: growth, refusals, slow answer and prep, rush hour, top dish', () {
    final prevFrom = DateTime(2026, 10, 26);
    final rows = [
      order(at: DateTime(2026, 10, 27, 13), food: 1000),
      for (var k = 0; k < 4; k++)
        order(
          at: DateTime(2026, 11, 3, 13, k * 10),
          food: 1000,
          accept: const Duration(minutes: 6),
          prep: const Duration(minutes: 40),
        ),
      order(
        at: DateTime(2026, 11, 4, 20),
        food: 3000,
        items: const [
          OrderLine(
            name: 'Couscous',
            unitPrice: 3000,
            quantity: 1,
            lineTotal: 3000,
          ),
        ],
      ),
      order(at: DateTime(2026, 11, 5, 21), status: 'rejected', food: 1200),
    ];
    final now = Insights.compute(rows, from, to);
    final before = Insights.compute(rows, prevFrom, from);
    final kinds = {for (final t in tipsFor(now, before)) t.kind: t};

    expect(kinds[TipKind.salesUp]!.number, 600); // 7000 vs 1000
    expect(kinds[TipKind.refusals]!.amount, 1200);
    expect(kinds[TipKind.slowResponse], isNotNull);
    expect(kinds[TipKind.slowPrep]!.number, greaterThan(25));
    expect(kinds[TipKind.peakHour]!.number, 13);
    expect(kinds[TipKind.topDish]!.text, 'Pizza Margherita');
    expect(kinds.containsKey(TipKind.salesDown), isFalse);
  });

  test('CSV: header, Excel-safe cells, net only when delivered', () async {
    final l = await AppLocalizations.delegate.load(const Locale('en'));
    final csv = ordersCsv([
      order(
        at: DateTime(2026, 11, 3, 12, 5),
        food: 1400,
        commission: 112,
        customer: 'Ali "Le Chef"; Kouba',
      ),
      order(
        at: DateTime(2026, 11, 3, 20),
        status: 'rejected',
        customer: '=HYPERLINK("x")',
        reason: 'no_answer',
      ),
    ], l);
    final lines = csv.split('\r\n');
    expect(lines.length, 3);
    expect(lines[0], startsWith('Code;Date;Time;Status;Customer;'));
    final first = lines[1].split(';');
    expect(first.sublist(0, 3), [first[0], '2026-11-03', '12:05']);
    expect(lines[1], contains('"Ali ""Le Chef""; Kouba"'));
    expect(lines[1], contains(';1400;200;1600;112;1288;Rachid;20;'));
    // Formula-looking text is defused; refused order has no net.
    expect(lines[2], contains("'=HYPERLINK"));
    expect(lines[2], contains(';1400;200;1600;;;;'));

    final bytes = csvBytes(csv);
    expect(bytes.sublist(0, 3), [0xEF, 0xBB, 0xBF]);
    expect(utf8.decode(bytes.sublist(3)), csv);
  });

  group('screens', () {
    setUpAll(loadFonts);

    Future<(FakeOwnerOrdersRepository, FakeOwnerRepository, FakeFileOutput)>
    app(
      WidgetTester t, {
      String lang = 'en',
      List<OwnerOrder> past = const [],
    }) async {
      final orders = FakeOwnerOrdersRepository()..reportOrders.addAll(past);
      final owner = FakeOwnerRepository()
        ..restaurant = const OwnedRestaurant(
          id: 'own1',
          slug: 'chez-omar',
          name: 'Chez Omar',
          area: 'Kouba',
          isActive: true,
          isOpen: true,
        );
      final files = FakeFileOutput();
      final auth = FakeAuthRepository()
        ..seedUser('o@mail.dz', 'secret123', name: 'Omar')
        ..roles['o@mail.dz'] = 'restaurant'
        ..signInDirect('o@mail.dz');
      await pumpFoodApp(
        t,
        repo: auth,
        owner: owner,
        ownerOrders: orders,
        files: files,
        lang: lang,
      );
      return (orders, owner, files);
    }

    DateTime todayAt(int h, [int m = 0]) {
      final n = DateTime.now();
      return DateTime(n.year, n.month, n.day, h, m);
    }

    DateTime daysAgo(int d, int h) {
      final n = DateTime.now();
      return DateTime(n.year, n.month, n.day - d, h);
    }

    testWidgets('dashboard shows today against yesterday', (t) async {
      final early = DateTime.now().hour == 0;
      await app(
        t,
        past: [
          if (!early) order(at: todayAt(0, 1), food: 2000),
          order(at: daysAgo(1, 0), food: 1000),
        ],
      );
      if (!early) {
        expect(
          find.text(formatDzd(2000, 'en')),
          findsWidgets,
        ); // sales + basket
        expect(find.text('100%'), findsWidgets);
      }
      expect(find.text('Last 7 days'), findsOneWidget);
      expect(find.text('Open for orders'), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets('orders table: filter, search, details and CSV export', (
      t,
    ) async {
      final (_, _, files) = await app(
        t,
        past: [
          order(at: daysAgo(1, 12), customer: 'Amina'),
          order(at: daysAgo(2, 13), customer: 'Bilal'),
          order(
            at: daysAgo(3, 20),
            status: 'rejected',
            customer: 'Chakib',
            reason: 'Fermé',
          ),
        ],
      );
      await t.tap(nav('Account'));
      await t.pumpAndSettle();
      await t.tap(find.text('Orders table'));
      await t.pumpAndSettle();
      expect(find.byType(OwnerOrdersTablePage), findsOneWidget);
      expect(find.text('Amina'), findsOneWidget);
      expect(find.text('Chakib'), findsOneWidget);

      // Status filter.
      await t.tap(find.text('Delivered').first);
      await t.pumpAndSettle();
      expect(find.text('Chakib'), findsNothing);
      expect(find.text('Bilal'), findsOneWidget);

      // Search.
      await t.enterText(find.byType(TextField), 'bil');
      await t.pumpAndSettle();
      expect(find.text('Amina'), findsNothing);
      expect(find.text('Bilal'), findsOneWidget);

      // Export what is shown.
      await t.tap(find.byTooltip('Export CSV'));
      await t.pumpAndSettle();
      final name = files.saved.keys.single;
      expect(
        name,
        matches(RegExp(r'^orders_\d{4}-\d\d-\d\d_\d{4}-\d\d-\d\d\.csv$')),
      );
      final csv = utf8.decode(files.saved[name]!.sublist(3));
      expect(csv.split('\r\n').length, 2);
      expect(csv, contains('Bilal'));
      expect(find.text('CSV file ready'), findsOneWidget);

      // Row details.
      await t.tap(find.text('Bilal'));
      await t.pumpAndSettle();
      expect(find.text('2× Pizza Margherita'), findsOneWidget);
      expect(find.text('Net after commission'), findsWidgets);
      expect(find.text('- ${formatDzd(112, 'en')}'), findsOneWidget);
    });

    testWidgets('insights: KPIs, charts, best sellers and tips', (t) async {
      await app(
        t,
        past: [
          for (var d = 1; d <= 5; d++) order(at: daysAgo(d, 13), food: 1500),
          order(at: daysAgo(9, 13), food: 1000),
        ],
      );
      await t.tap(nav('Insights'));
      await t.pumpAndSettle();
      expect(find.byType(OwnerInsightsPage), findsOneWidget);
      expect(find.text(formatDzd(7500, 'en')), findsOneWidget);
      expect(find.text('Tips to sell more'), findsOneWidget);
      expect(find.textContaining('Sales are up 650%'), findsOneWidget);
      expect(find.textContaining('Rush hour: 13:00'), findsOneWidget);
      await t.scrollUntilVisible(
        find.text('Best sellers'),
        300,
        scrollable: vertical,
      );
      expect(find.text('10 sold'), findsOneWidget);

      await t.tap(find.text('30 days'));
      await t.pumpAndSettle();
      expect(find.text('Compared with the previous 30 days'), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets('insights and table render in Arabic and dark', (t) async {
      final past = [order(at: daysAgo(1, 13)), order(at: daysAgo(2, 20))];
      await app(t, lang: 'ar', past: past);
      await t.tap(nav('الإحصائيات'));
      await t.pumpAndSettle();
      expect(find.byType(OwnerInsightsPage), findsOneWidget);
      expect(t.takeException(), isNull);
      await t.tap(find.byTooltip('جدول الطلبات'));
      await t.pumpAndSettle();
      expect(find.byType(OwnerOrdersTablePage), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets('delete account: refused while money is pending', (t) async {
      final (_, owner, _) = await app(t);
      owner.deleteFailure = DeleteRestaurantFailure.cashPending;
      await t.tap(nav('Account'));
      await t.pumpAndSettle();
      expect(find.byType(OwnerAccountPage), findsOneWidget);
      expect(find.text('Approved'), findsOneWidget);
      await t.scrollUntilVisible(
        find.text('Delete my account'),
        200,
        scrollable: vertical,
      );
      await t.tap(find.text('Delete my account'));
      await t.pumpAndSettle();
      await t.tap(find.text('Delete my account').last);
      await t.pumpAndSettle();
      expect(owner.deleted, isFalse);
      expect(
        find.text('First confirm the money received from drivers.'),
        findsOneWidget,
      );
    });

    testWidgets('delete account: signed out after deleting', (t) async {
      final (_, owner, _) = await app(t);
      await t.tap(nav('Account'));
      await t.pumpAndSettle();
      await t.scrollUntilVisible(
        find.text('Delete my account'),
        200,
        scrollable: vertical,
      );
      await t.tap(find.text('Delete my account'));
      await t.pumpAndSettle();
      expect(find.textContaining('archived for accounting'), findsOneWidget);
      await t.tap(find.text('Delete my account').last);
      await t.pumpAndSettle();
      expect(owner.deleted, isTrue);
      expect(find.byType(OwnerAccountPage), findsNothing);
    });
  });

  testWidgets('outline buttons stay readable in dark mode', (t) async {
    await pumpFoodApp(t, dark: true);
    // Any screen with the shared button will do: the login page has none,
    // so check the widget directly.
    await t.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: Brightness.dark),
        home: Scaffold(
          body: Column(
            children: [
              AppButton(
                label: 'Print',
                variant: AppButtonVariant.outline,
                onPressed: () {},
              ),
              AppButton(
                label: 'Cancel',
                variant: AppButtonVariant.dangerOutline,
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
    for (final b in t.widgetList<Material>(
      find.descendant(
        of: find.byType(AppButton),
        matching: find.byType(Material),
      ),
    )) {
      if (b.color == null || b.color == Colors.transparent) continue;
      expect(b.color, isNot(Colors.white));
    }
  });

  testWidgets('dashboard: a failing report shows Retry, not endless loading', (
    t,
  ) async {
    final orders = FakeOwnerOrdersRepository()..reportFails = true;
    final auth = FakeAuthRepository()
      ..seedUser('o@mail.dz', 'secret123')
      ..roles['o@mail.dz'] = 'restaurant'
      ..signInDirect('o@mail.dz');
    final owner = FakeOwnerRepository()
      ..restaurant = const OwnedRestaurant(
        id: 'own1',
        slug: 'x',
        name: 'Chez Omar',
        isActive: true,
      );
    await pumpFoodApp(t, repo: auth, owner: owner, ownerOrders: orders);
    await t.scrollUntilVisible(
      find.text('Last 7 days'),
      200,
      scrollable: vertical,
    );
    expect(find.text('Retry'), findsOneWidget);
    orders.reportFails = false;
    await t.drag(vertical, const Offset(0, -200));
    await t.pumpAndSettle();
    await t.tap(find.text('Retry'));
    await t.pumpAndSettle();
    expect(find.text('Retry'), findsNothing);
  });
}
