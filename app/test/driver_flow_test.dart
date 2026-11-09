import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_app/features/admin/data/admin_drivers.dart';
import 'package:food_app/features/admin/pages/admin_drivers_page.dart';
import 'package:food_app/features/driver/data/driver_repository.dart';
import 'package:food_app/features/driver/pages/driver_home_page.dart';
import 'package:food_app/features/driver/pages/driver_order_page.dart';
import 'package:food_app/features/driver/pages/driver_register_page.dart';

import 'helpers/fake_auth.dart';

String da(String s) {
  final i = s.lastIndexOf(' ');
  return '${s.substring(0, i).replaceAll(' ', ' ')} ${s.substring(i + 1)}';
}

class DriverSetup {
  DriverSetup({bool approved = true, bool online = false}) {
    driver.seedDriver(approved: approved, online: online);
  }
  final driver = FakeDriverRepository();
  final sound = FakeAlertSound();
}

Future<DriverSetup> driverApp(WidgetTester t, DriverSetup s) async {
  final auth = FakeAuthRepository()
    ..seedUser('d@mail.dz', 'secret123', name: 'Rachid')
    ..roles['d@mail.dz'] = 'driver'
    ..signInDirect('d@mail.dz');
  await pumpFoodApp(t, repo: auth, driver: s.driver, sound: s.sound);
  return s;
}

Future<void> tap(WidgetTester t, Finder f) async {
  await t.ensureVisible(f);
  await t.pumpAndSettle();
  await t.tap(f);
  await t.pumpAndSettle();
}

void main() {
  setUpAll(loadFonts);

  testWidgets('not approved yet: banner, cannot go online', (t) async {
    final s = await driverApp(t, DriverSetup(approved: false));
    expect(find.byType(DriverHomePage), findsOneWidget);
    expect(find.text('Waiting for approval'), findsOneWidget);
    expect(find.text('Offline'), findsOneWidget);
    await t.tap(find.byType(Switch));
    await t.pumpAndSettle();
    expect(s.driver.calls, isEmpty); // switch disabled
  });

  testWidgets('full delivery: online → take → pick up → delivered', (t) async {
    final s = DriverSetup();
    s.driver.addAvailable();
    await driverApp(t, s);
    expect(find.text('Available orders'), findsNothing); // offline

    await tap(t, find.byType(Switch));
    expect(s.driver.calls, ['online:true']);
    expect(find.text('Online'), findsOneWidget);
    expect(find.text('Available orders'), findsOneWidget);
    expect(find.text('Pizzeria El Bahdja'), findsOneWidget);
    expect(find.text('Alger Centre'), findsOneWidget);
    expect(find.text(da('200 DA')), findsOneWidget); // your fee
    expect(find.text(da('1 600 DA')), findsOneWidget); // cash to collect

    await tap(t, find.text('TAKE IT'));
    expect(s.driver.calls.last, 'claim:av1');
    expect(find.byType(DriverOrderPage), findsOneWidget);
    // Full details now: customer, phone, notes, amounts.
    expect(find.text('Amina'), findsOneWidget);
    expect(find.text('0550123456'), findsOneWidget);
    expect(find.text('“Sonner deux fois”'), findsOneWidget);
    expect(find.text(da('1 400 DA')), findsOneWidget); // hand to restaurant
    // Restaurant still cooking: no pickup button yet.
    expect(find.text('PICKED UP'), findsNothing);
    expect(find.textContaining('preparing'), findsOneWidget);

    // The restaurant marks it ready: the page updates by itself.
    s.driver.restaurantMarksReady('av1');
    await t.pumpAndSettle();
    await tap(t, find.text('PICKED UP'));
    expect(s.driver.calls.last, 'av1:picked_up');
    expect(find.text('Give it back'), findsNothing); // too late now

    // Delivered: the photo sheet opens; can't confirm without a photo.
    await tap(t, find.text('DELIVERED & PAID'));
    expect(find.text('Delivery photo'), findsOneWidget);
    expect(find.textContaining('The customer paid you'), findsOneWidget);
    await t.tap(find.text('DELIVERED & PAID').last); // disabled, no photo
    await t.pumpAndSettle();
    expect(s.driver.calls.last, 'av1:picked_up');
    await tap(t, find.text('Take the photo'));
    expect(find.text('Retake'), findsOneWidget); // preview shown
    await tap(t, find.text('DELIVERED & PAID').last);
    expect(s.driver.calls.last, 'av1:delivered+photo');
    expect(s.driver.photos['av1'], isNotNull);
    expect(find.byType(DriverHomePage), findsOneWidget);
    expect(find.text('Today: 1 deliveries · ${da('200 DA')}'), findsOneWidget);

    // Food money to give to the restaurant.
    expect(find.text('Money to give to restaurants'), findsOneWidget);
    expect(find.text('Total to give: ${da('1 400 DA')}'), findsOneWidget);
    await tap(t, find.text('I gave the money'));
    expect(s.driver.calls.last, 'cash:av1');
    expect(find.text('Waiting for the restaurant to confirm'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('money overdue: red banner, taking an order is refused', (
    t,
  ) async {
    final s = DriverSetup(online: true);
    s.driver.cash.add(
      CashDue(
        orderId: 'old1',
        code: 'OLD111',
        restaurantName: 'Pizzeria El Bahdja',
        amount: 1400,
        deliveredAt: DateTime.now().subtract(const Duration(hours: 30)),
        overdue: true,
      ),
    );
    await driverApp(t, s);
    expect(find.text('New orders blocked'), findsOneWidget);
    expect(find.text('Money to give to restaurants'), findsOneWidget);
  });

  testWidgets('someone else was faster: clear message, list refreshed', (
    t,
  ) async {
    final s = DriverSetup(online: true);
    s.driver.addAvailable();
    s.driver.takenByOthers.add('av1');
    await driverApp(t, s);
    await tap(t, find.text('TAKE IT'));
    expect(find.text('Another driver took it first.'), findsOneWidget);
    expect(find.byType(DriverHomePage), findsOneWidget);
    expect(find.textContaining('No orders right now'), findsOneWidget);
  });

  testWidgets('give an order back before pickup', (t) async {
    final s = DriverSetup(online: true);
    s.driver.addAvailable(ready: true);
    await driverApp(t, s);
    await tap(t, find.text('TAKE IT'));
    await tap(t, find.text('Give it back'));
    await tap(t, find.text('Give it back').last); // confirm
    expect(s.driver.calls.last, 'release:av1');
    expect(find.byType(DriverHomePage), findsOneWidget);
    expect(find.text('TAKE IT'), findsOneWidget); // back in the list
  });

  testWidgets('new order while online: chime after the 10 s check', (t) async {
    final s = await driverApp(t, DriverSetup(online: true));
    expect(s.sound.plays, 0);
    s.driver.addAvailable();
    await t.pump(const Duration(seconds: 10));
    await t.pumpAndSettle();
    expect(find.text('TAKE IT'), findsOneWidget);
    expect(s.sound.plays, 1);
    // Same order on the next check: no second chime.
    await t.pump(const Duration(seconds: 10));
    await t.pumpAndSettle();
    expect(s.sound.plays, 1);
  });

  testWidgets('a customer becomes a driver from the login page', (t) async {
    final driver = FakeDriverRepository();
    final auth = FakeAuthRepository()..requireEmailConfirmation = false;
    await pumpFoodApp(t, repo: auth, driver: driver);
    await tap(t, find.text('JOIN'));
    expect(find.byType(DriverRegisterPage), findsOneWidget);
    final fields = find.byType(TextFormField);
    await t.enterText(fields.at(0), 'Rachid Benali');
    await t.enterText(fields.at(1), 'r@mail.dz');
    await t.enterText(fields.at(2), 'secret123');
    await t.enterText(fields.at(3), '0661 00 00 01');
    await tap(t, find.text('Car'));
    // The fake auth turns the account into a driver like the SQL does.
    auth.roles['r@mail.dz'] = 'driver';
    await tap(t, find.text('SIGN UP'));
    expect(driver.calls, ['register:0661000001:car']);
    expect(find.byType(DriverHomePage), findsOneWidget);
    expect(find.text('Waiting for approval'), findsOneWidget);
  });

  testWidgets('admin approves a driver', (t) async {
    final admin = FakeAdminDriversRepository()
      ..list.add(
        AdminDriver(
          id: 'drv9',
          fullName: 'Sofiane',
          email: 's@mail.dz',
          phone: '0661000002',
          vehicle: 'moto',
          isApproved: false,
          isOnline: false,
          createdAt: DateTime(2026, 11, 8),
        ),
      );
    final auth = FakeAuthRepository()
      ..seedUser('a@mail.dz', 'secret123', name: 'Admin')
      ..roles['a@mail.dz'] = 'admin'
      ..signInDirect('a@mail.dz');
    await pumpFoodApp(t, repo: auth, adminDrivers: admin);
    await tap(t, find.byIcon(Icons.delivery_dining_outlined).last);
    expect(find.byType(AdminDriversPage), findsOneWidget);
    expect(find.text('Sofiane'), findsOneWidget);
    expect(find.text('To approve'), findsOneWidget);
    await tap(t, find.text('Approve'));
    expect(admin.calls, ['drv9:true']);
    expect(find.text('Offline'), findsOneWidget);
    expect(find.text('Deactivate'), findsOneWidget);
  });
}
