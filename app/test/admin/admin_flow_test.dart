import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_app/features/admin/data/admin_repository.dart';
import 'package:food_app/features/admin/pages/admin_dashboard_page.dart';
import 'package:food_app/features/admin/pages/admin_receipt_pages.dart';
import 'package:food_app/features/home/home_page.dart';
import 'package:go_router/go_router.dart';

import '../helpers/fake_auth.dart';

final _vertical = find.byWidgetPredicate(
  (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
);

Future<void> tap(WidgetTester t, Finder f) async {
  await t.ensureVisible(f);
  await t.pumpAndSettle();
  final h = (t.view.physicalSize / t.view.devicePixelRatio).height;
  final dialogOpen = find.byType(Dialog).evaluate().isNotEmpty;
  if (!dialogOpen &&
      t.getRect(f).bottom > h - 80 &&
      _vertical.evaluate().isNotEmpty) {
    await t.drag(_vertical.first, const Offset(0, -250));
    await t.pumpAndSettle();
  }
  await t.tap(f);
  await t.pumpAndSettle();
}

/// Signed-in admin. [wide] = PC layout (navigation rail).
Future<FakeAdminRepository> adminApp(
  WidgetTester t, {
  FakeAdminRepository? admin,
  FakePdfOutput? pdf,
  bool wide = false,
}) async {
  final auth = FakeAuthRepository()
    ..seedUser('admin@food.dz', 'secret123', name: 'Admin')
    ..roles['admin@food.dz'] = 'admin'
    ..signInDirect('admin@food.dz');
  final repo = admin ?? FakeAdminRepository();
  await pumpFoodApp(
    t,
    repo: auth,
    admin: repo,
    pdf: pdf,
    size: wide ? const Size(1280, 800) : const Size(375, 812),
  );
  return repo;
}

/// Two delivered orders for Burger House 20 days ago (in the previous
/// half-month or the previous month).
FakeAdminRepository withOrders() {
  final repo = FakeAdminRepository();
  final now = DateTime.now();
  // Inside the "previous half-month" billing period.
  final day = now.day > 15
      ? DateTime(now.year, now.month, 5)
      : DateTime(now.year, now.month - 1, 20);
  repo.delivered.addAll([
    FakeDelivered('r1', 'AAA111', 1000, day),
    FakeDelivered('r1', 'BBB222', 2500, day),
  ]);
  return repo;
}

void main() {
  setUpAll(loadFonts);

  testWidgets('admin lands on the dashboard; customer pages are closed', (
    t,
  ) async {
    await adminApp(t);
    expect(find.byType(AdminDashboardPage), findsOneWidget);
    expect(find.text('Commission earned'), findsOneWidget);
    GoRouter.of(t.element(find.byType(Scaffold).first)).go('/home');
    await t.pumpAndSettle();
    expect(find.byType(HomePage), findsNothing);
  });

  testWidgets('dashboard works on a wide screen (navigation rail)', (t) async {
    await adminApp(t, wide: true);
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('approve a pending restaurant', (t) async {
    final repo = await adminApp(t);
    await tap(t, find.byTooltip('Restaurants'));
    await tap(t, find.textContaining('To approve ('));
    expect(find.text('Chez Omar'), findsOneWidget);
    expect(find.text('Burger House'), findsNothing);
    await tap(t, find.text('Approve'));
    expect(
      repo.restaurantsList.firstWhere((r) => r.id == 'r2').isActive,
      isTrue,
    );
  });

  testWidgets('set a restaurant commission to 10 %', (t) async {
    final repo = await adminApp(t);
    await tap(t, find.byTooltip('Restaurants'));
    await tap(t, find.textContaining('Default (8 %)').first);
    await t.enterText(find.byType(TextFormField).last, '10');
    await tap(t, find.text('Save'));
    expect(
      repo.restaurantsList.firstWhere((r) => r.id == 'r1').commissionRate,
      0.10,
    );
    expect(find.text('10 %'), findsOneWidget);
  });

  testWidgets('generate a receipt, download its PDF, mark it paid', (t) async {
    final pdf = FakePdfOutput();
    final repo = await adminApp(t, admin: withOrders(), pdf: pdf);
    await tap(t, find.byTooltip('Receipts'));
    expect(find.text('No receipts yet'), findsOneWidget);
    expect(find.text('New receipt'), findsOneWidget);
    // Open the form with the restaurant preselected (as the dashboard does).
    GoRouter.of(
      t.element(find.byType(Scaffold).first),
    ).push('/admin/receipts/new?restaurant=r1');
    await t.pumpAndSettle();
    // 2 orders, 3 500 DA of food, 280 DA commission.
    expect(find.text('280 DA'), findsOneWidget);
    await tap(t, find.text('GENERATE RECEIPT'));

    expect(find.byType(AdminReceiptPage), findsOneWidget);
    expect(find.text('FD-2026-0001'), findsOneWidget);
    expect(find.text('AAA111'), findsOneWidget);

    await tap(t, find.text('Download PDF'));
    final bytes = pdf.downloads['FD-2026-0001.pdf']!;
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');

    await tap(t, find.text('Mark as paid'));
    expect(repo.statementsList.single.isPaid, isTrue);
    expect(find.text('Paid'), findsOneWidget);
    // Paid receipts can no longer be cancelled.
    expect(find.text('Cancel receipt'), findsNothing);
  });

  testWidgets('nothing to bill: the generate button is disabled', (t) async {
    await adminApp(t);
    GoRouter.of(
      t.element(find.byType(Scaffold).first),
    ).push('/admin/receipts/new?restaurant=r1');
    await t.pumpAndSettle();
    expect(
      find.text('No delivered orders to bill in this period'),
      findsOneWidget,
    );
    final btn = find.ancestor(
      of: find.text('GENERATE RECEIPT'),
      matching: find.byType(Opacity),
    );
    expect(t.widget<Opacity>(btn.first).opacity, lessThan(1));
  });

  testWidgets('cancel an unpaid receipt frees its orders', (t) async {
    final repo = withOrders();
    final now = DateTime.now();
    await repo.generateStatement(
      'r1',
      DateRange(DateTime(now.year - 1), DateTime(now.year + 1)),
    );
    await adminApp(t, admin: repo);
    await tap(t, find.byTooltip('Receipts'));
    await tap(t, find.textContaining('FD-2026-0001'));
    await tap(t, find.text('Cancel receipt'));
    await tap(t, find.text('Cancel receipt').last);
    expect(repo.statementsList, isEmpty);
    expect(repo.delivered.every((d) => d.statementId == null), isTrue);
  });

  testWidgets('settings: fee, block hours and business details are saved', (
    t,
  ) async {
    final repo = await adminApp(t);
    await tap(t, find.byTooltip('Settings'));
    await t.enterText(find.byType(TextFormField).at(0), '250');
    await t.enterText(find.byType(TextFormField).at(2), '12'); // block hours
    await t.enterText(find.byType(TextFormField).at(3), '15'); // auto-reject
    await t.enterText(find.byType(TextFormField).at(4), 'Food DZ');
    await t.scrollUntilVisible(
      find.text('SAVE'),
      300,
      scrollable: _vertical.first,
    );
    await tap(t, find.text('SAVE'));
    expect(repo.cfg.deliveryFee, 250);
    expect(repo.cfg.businessName, 'Food DZ');
    expect(repo.cfg.cashHandoverHours, 12);
    expect(repo.cfg.autoRejectMinutes, 15);
  });

  testWidgets('admin pages render in Arabic without overflow', (t) async {
    final auth = FakeAuthRepository()
      ..seedUser('admin@food.dz', 'secret123')
      ..roles['admin@food.dz'] = 'admin'
      ..signInDirect('admin@food.dz');
    await pumpFoodApp(t, repo: auth, admin: withOrders(), lang: 'ar');
    for (final label in ['مطاعم', 'الطلبات', 'الكشوف', 'الإعدادات']) {
      await tap(t, find.byTooltip(label));
      expect(t.takeException(), isNull);
    }
  });
}
