import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_app/core/pdf/receipt_pdf.dart';
import 'package:food_app/features/account/data/account_repository.dart';
import 'package:food_app/features/admin/data/admin_models.dart';
import 'package:food_app/features/driver/data/driver_repository.dart';
import 'package:food_app/features/driver/driver_statement.dart';
import 'package:food_app/features/orders/data/orders_repository.dart';
import 'package:food_app/features/orders/order_receipt.dart';
import 'package:food_app/features/orders/pages/order_page.dart';
import 'package:food_app/features/restaurant_owner/data/owner_repository.dart';
import 'package:food_app/features/restaurant_owner/pages/owner_statements_page.dart';
import 'package:food_app/l10n/app_localizations.dart';

import 'helpers/fake_auth.dart';

Future<void> tap(WidgetTester t, Finder f) async {
  await t.ensureVisible(f);
  await t.pumpAndSettle();
  await t.tap(f);
  await t.pumpAndSettle();
}

bool isPdf(List<int> bytes) => ascii.decode(bytes.sublist(0, 5)) == '%PDF-';

const _items = [
  OrderLine(
    name: 'Pizza Margherita',
    unitPrice: 700,
    quantity: 2,
    lineTotal: 1400,
  ),
];

void main() {
  setUpAll(loadFonts);

  testWidgets('customer downloads the receipt of a delivered order', (t) async {
    final orders = FakeOrdersRepository(
      menu: FakeCatalogRepository().items,
      restaurantNames: {'r1': 'Pizzeria El Bahdja'},
    );
    final account = FakeAccountRepository()
      ..addressList.add(
        const Address(
          id: 'a1',
          label: AddressLabel.home,
          addressText: 'Rue Didouche 12',
          isDefault: true,
        ),
      )
      ..profile = const Profile(
        id: 'u1',
        fullName: 'Karim Benali',
        email: 'k@mail.dz',
        phone: '0550123456',
      );
    final pdf = FakePdfOutput();
    final auth = FakeAuthRepository()
      ..seedUser('k@mail.dz', 'secret123')
      ..signInDirect('k@mail.dz');
    await pumpFoodApp(
      t,
      repo: auth,
      orders: orders,
      account: account,
      pdf: pdf,
    );

    // Place an order through the app, then the driver delivers it.
    await tap(t, find.text('Pizzeria El Bahdja'));
    await tap(t, find.byIcon(Icons.add_rounded).first);
    await tap(t, find.byIcon(Icons.shopping_bag_outlined).first);
    await tap(t, find.text('PLACE ORDER'));
    await tap(t, find.text('TRACK ORDER'));
    expect(find.byType(OrderPage), findsOneWidget);
    expect(find.text('Download receipt'), findsNothing); // not delivered yet
    orders.setStatus('o1', 'delivered');
    await t.pumpAndSettle();

    await t.scrollUntilVisible(find.text('Download receipt'), 200);
    await tap(t, find.text('Download receipt'));
    expect(pdf.downloads.keys, ['recu-ABC231.pdf']);
    expect(isPdf(pdf.downloads.values.single), isTrue);
    await tap(t, find.text('Print'));
    expect(pdf.printed, ['recu-ABC231']);
  });

  testWidgets('driver downloads an earnings statement for a period', (t) async {
    final driver = FakeDriverRepository()..seedDriver();
    driver.statementRows.add(
      StatementDelivery(
        code: 'K7P2QX',
        deliveredAt: DateTime(2026, 11, 8, 13, 20),
        restaurantName: 'Pizzeria El Bahdja',
        total: 1600,
        foodTotal: 1400,
        deliveryFee: 200,
      ),
    );
    final pdf = FakePdfOutput();
    final auth = FakeAuthRepository()
      ..seedUser('d@mail.dz', 'secret123')
      ..roles['d@mail.dz'] = 'driver'
      ..signInDirect('d@mail.dz');
    await pumpFoodApp(t, repo: auth, driver: driver, pdf: pdf);
    await tap(t, find.text('My deliveries'));
    await tap(t, find.byIcon(Icons.picture_as_pdf_outlined));
    await tap(t, find.text('This week'));
    expect(driver.lastStatementRange, isNotNull);
    expect(pdf.downloads.length, 1);
    expect(pdf.downloads.keys.single, startsWith('releve-livreur-'));
    expect(isPdf(pdf.downloads.values.single), isTrue);

    // Empty period: a message, no file.
    driver.statementRows.clear();
    await tap(t, find.byIcon(Icons.picture_as_pdf_outlined));
    await tap(t, find.text('Last month'));
    expect(find.text('No deliveries in this period'), findsOneWidget);
    expect(pdf.downloads.length, 1);
  });

  testWidgets('restaurant downloads its commission statements', (t) async {
    final ownerOrders = FakeOwnerOrdersRepository();
    ownerOrders.statementList.add(
      StatementSummary(
        id: 's1',
        number: 'FD-2026-0001',
        restaurantId: '',
        restaurantName: 'Chez Omar',
        periodStart: DateTime(2026, 11, 1),
        periodEnd: DateTime(2026, 11, 15),
        ordersCount: 12,
        foodTotal: 18000,
        commissionTotal: 1440,
        status: 'issued',
        issuedAt: DateTime(2026, 11, 16),
      ),
    );
    final owner = FakeOwnerRepository()
      ..restaurant = const OwnedRestaurant(
        id: 'own1',
        slug: 'chez-omar',
        name: 'Chez Omar',
        isActive: true,
      );
    final pdf = FakePdfOutput();
    final auth = FakeAuthRepository()
      ..seedUser('o@mail.dz', 'secret123')
      ..roles['o@mail.dz'] = 'restaurant'
      ..signInDirect('o@mail.dz');
    await pumpFoodApp(
      t,
      repo: auth,
      owner: owner,
      ownerOrders: ownerOrders,
      pdf: pdf,
    );
    await tap(t, find.bySemanticsLabel(RegExp('^Restaurant profile')).last);
    await t.scrollUntilVisible(
      find.text('My commission statements'),
      200,
      scrollable: find
          .byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          )
          .first,
    );
    await tap(t, find.text('My commission statements'));
    expect(find.byType(OwnerStatementsPage), findsOneWidget);
    expect(find.text('FD-2026-0001'), findsOneWidget);
    expect(find.text('Unpaid'), findsOneWidget);
    await tap(t, find.text('Download PDF'));
    expect(pdf.downloads.keys, ['FD-2026-0001.pdf']);
    expect(isPdf(pdf.downloads.values.single), isTrue);
  });

  test('receipts build in Arabic and French', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final fonts = await PdfFonts.fromAssets();
    const business = AdminConfig(
      deliveryFee: 200,
      defaultCommissionRate: 0.08,
      businessName: 'Food DZ',
      businessTaxId: 'NIF123',
    );
    final o = CustomerOrder(
      id: 'o1',
      code: 'ABC231',
      status: 'delivered',
      restaurantId: 'r1',
      restaurantName: 'مطعم البهجة',
      addressText: 'شارع ديدوش مراد 12',
      customerPhone: '0550123456',
      foodTotal: 1400,
      deliveryFee: 200,
      total: 1600,
      placedAt: DateTime(2026, 11, 8, 12, 30),
      deliveredAt: DateTime(2026, 11, 8, 13, 10),
      driverName: 'Rachid',
      items: _items,
    );
    for (final lang in ['ar', 'fr']) {
      final l = lookupAppLocalizations(Locale(lang));
      final bytes = await buildOrderReceipt(
        order: o,
        customerName: 'كريم',
        business: business,
        l: l,
        lang: lang,
        fonts: fonts,
      );
      expect(isPdf(bytes), isTrue, reason: lang);
      final st = await buildDriverStatement(
        deliveries: [
          StatementDelivery(
            code: 'K7P2QX',
            deliveredAt: DateTime(2026, 11, 8),
            restaurantName: 'مطعم البهجة',
            total: 1600,
            foodTotal: 1400,
            deliveryFee: 200,
            cashConfirmed: true,
          ),
        ],
        from: DateTime(2026, 11, 1),
        to: DateTime(2026, 11, 8),
        driverName: 'Rachid',
        driverPhone: '0661000001',
        business: business,
        l: l,
        lang: lang,
        fonts: fonts,
      );
      expect(isPdf(st), isTrue, reason: lang);
    }
  });

  test('driver periods: weeks start on Saturday', () {
    // Monday 9 Nov 2026.
    final now = DateTime(2026, 11, 9, 15);
    final (a, b) = driverPeriodRange(DriverPeriod.thisWeek, now);
    expect([a, b], [DateTime(2026, 11, 7), DateTime(2026, 11, 9)]);
    final (c, d) = driverPeriodRange(DriverPeriod.lastWeek, now);
    expect([c, d], [DateTime(2026, 10, 31), DateTime(2026, 11, 6)]);
    final (e, f) = driverPeriodRange(DriverPeriod.lastMonth, now);
    expect([e, f], [DateTime(2026, 10, 1), DateTime(2026, 10, 31)]);
  });
}
