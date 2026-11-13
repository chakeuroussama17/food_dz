import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_app/features/qr/qr_repository.dart';
import 'package:food_app/features/restaurant_owner/data/owner_repository.dart';
import 'package:go_router/go_router.dart';

import 'helpers/fake_auth.dart';

void main() {
  setUpAll(loadFonts);

  test('scanned links: ours on any domain, everything else refused', () {
    expect(
      appPathFromScan('https://foodfennec.com/r/pizzeria-el-bahdja?src=qr'),
      '/r/pizzeria-el-bahdja',
    );
    expect(appPathFromScan(' http://test.dz/r/Chez-Omar/ '), '/r/chez-omar');
    expect(appPathFromScan('https://foodfennec.com/r/'), isNull);
    expect(appPathFromScan('https://foodfennec.com/admin'), isNull);
    expect(appPathFromScan('https://x.dz/r/a/b'), isNull);
    expect(appPathFromScan('https://x.dz/r/<script>'), isNull);
    expect(appPathFromScan('javascript:alert(1)'), isNull);
    expect(appPathFromScan('WIFI:S:cafe;T:WPA;P:1234;;'), isNull);
    expect(
      restaurantQrLink('https://foodfennec.dz', 'chez-omar'),
      'https://foodfennec.dz/r/chez-omar?src=qr',
    );
  });

  Future<void> go(WidgetTester t, String path) async {
    GoRouter.of(t.element(find.byType(Scaffold).first)).go(path);
    await t.pumpAndSettle();
  }

  testWidgets('owner: QR code with the name, scans, poster PDF', (t) async {
    final owner = FakeOwnerRepository()
      ..restaurant = const OwnedRestaurant(
        id: 'own1',
        slug: 'chez-omar',
        name: 'Chez Omar',
        area: 'Kouba',
        isActive: true,
        isOpen: true,
      );
    final qr = FakeQrRepository()
      ..baseUrl = 'https://foodfennec.dz'
      ..statsValue = const QrStats(
        total: 57,
        last30: 41,
        app: 20,
        web: 37,
        people: 33,
        ordersAfter: 12,
      );
    final pdf = FakePdfOutput();
    final auth = FakeAuthRepository()
      ..seedUser('o@mail.dz', 'secret123', name: 'Omar')
      ..roles['o@mail.dz'] = 'restaurant'
      ..signInDirect('o@mail.dz');
    await pumpFoodApp(t, repo: auth, owner: owner, qr: qr, pdf: pdf);
    await go(t, '/restaurant/account');
    await t.tap(find.text('Restaurant QR code'));
    await t.pumpAndSettle();

    expect(find.byKey(const Key('restaurant-qr')), findsOneWidget);
    expect(find.text('Chez Omar'), findsOneWidget);
    expect(find.text('Scan to order'), findsOneWidget);
    expect(
      find.bySemanticsLabel('https://foodfennec.dz/r/chez-omar?src=qr'),
      findsOneWidget,
    );
    await t.scrollUntilVisible(
      find.text('41'),
      200,
      scrollable: find
          .ancestor(
            of: find.byKey(const Key('restaurant-qr')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('33'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.textContaining('57 scans in total'), findsOneWidget);

    await t.scrollUntilVisible(
      find.text('DOWNLOAD THE POSTER (PDF)'),
      -200,
      scrollable: find
          .ancestor(
            of: find.byKey(const Key('restaurant-qr')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await t.runAsync(() async {
      await t.tap(find.text('DOWNLOAD THE POSTER (PDF)'));
      for (var i = 0; i < 50 && pdf.downloads.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    });
    await t.pumpAndSettle();
    expect(pdf.downloads.keys, ['QR-chez-omar.pdf']);
    expect(String.fromCharCodes(pdf.downloads.values.first.take(5)), '%PDF-');
    expect(t.takeException(), isNull);
  });

  testWidgets('customer: scan opens the restaurant; other codes refused', (
    t,
  ) async {
    final qr = FakeQrRepository();
    final camera = FakeCamera()
      ..codes.addAll([
        'https://example.com/menu',
        'https://foodfennec.com/r/pizzeria-el-bahdja?src=qr',
      ]);
    final auth = FakeAuthRepository()
      ..seedUser('k@mail.dz', 'secret123', name: 'Karim')
      ..signInDirect('k@mail.dz');
    await pumpFoodApp(t, repo: auth, qr: qr, camera: camera);
    await go(t, '/home');
    await t.tap(find.byKey(const Key('scan-qr')));
    await t.pumpAndSettle();
    expect(find.text('Scan a QR code'), findsOneWidget);

    await t.tap(find.byKey(const Key('scan:https://example.com/menu')));
    await t.pump();
    expect(find.text('This is not a foodfennec QR code'), findsOneWidget);
    await t.pump(const Duration(seconds: 5));
    await t.pumpAndSettle();

    await t.tap(
      find.byKey(
        const Key('scan:https://foodfennec.com/r/pizzeria-el-bahdja?src=qr'),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('Pizzeria El Bahdja'), findsWidgets);
    expect(qr.visits, ['pizzeria-el-bahdja:qr_app']);

    // A phone camera / browser opens the same page with ?src=qr.
    await go(t, '/r/burger-house-hydra?src=qr');
    expect(qr.visits.last, 'burger-house-hydra:qr_web');
    // A normal visit isn't counted.
    await go(t, '/r/dar-lgharbi');
    expect(qr.visits, hasLength(2));
    expect(t.takeException(), isNull);
  });

  testWidgets('admin sets the QR address; a bad one is refused', (t) async {
    final qr = FakeQrRepository();
    final auth = FakeAuthRepository()
      ..seedUser('a@mail.dz', 'secret123', name: 'Admin')
      ..roles['a@mail.dz'] = 'admin'
      ..signInDirect('a@mail.dz');
    await pumpFoodApp(t, repo: auth, qr: qr, size: const Size(1100, 1000));
    await go(t, '/admin/settings');
    final field = find.descendant(
      of: find.byKey(const Key('public-url')),
      matching: find.byType(TextField),
    );
    await t.scrollUntilVisible(
      field,
      200,
      scrollable: find
          .ancestor(
            of: find.text('Your details (printed on receipts)'),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await t.enterText(field, 'foodfennec');
    await t.tap(find.text('SAVE'));
    await t.pumpAndSettle();
    expect(
      find.text('Invalid address (e.g. https://foodfennec.com)'),
      findsOneWidget,
    );
    await t.enterText(field, 'https://FoodFennec.dz/');
    await t.tap(find.text('SAVE'));
    await t.pumpAndSettle();
    expect(qr.baseUrl, 'https://foodfennec.dz');
    expect(t.takeException(), isNull);
  });
}
