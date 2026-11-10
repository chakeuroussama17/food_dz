import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_app/features/admin/pages/admin_banners_page.dart';
import 'package:food_app/features/banners/banners_repository.dart';
import 'package:food_app/features/catalog/pages/restaurant_page.dart';

import 'helpers/fake_auth.dart';

Future<void> tap(WidgetTester t, Finder f) async {
  await t.ensureVisible(f);
  await t.pumpAndSettle();
  await t.tap(f);
  await t.pumpAndSettle();
}

Future<void> customerHome(WidgetTester t, FakeBannersRepository banners) async {
  final auth = FakeAuthRepository()
    ..seedUser('k@mail.dz', 'secret123', name: 'Karim')
    ..signInDirect('k@mail.dz');
  await pumpFoodApp(t, repo: auth, banners: banners);
}

void main() {
  setUpAll(loadFonts);

  testWidgets('no banners: nothing at the top of the home', (t) async {
    await customerHome(t, FakeBannersRepository());
    expect(find.byType(PageView), findsNothing);
    expect(t.takeException(), isNull);
  });

  testWidgets(
    'admin banners slide on the home; a linked one opens the restaurant',
    (t) async {
      final banners = FakeBannersRepository()
        ..list.addAll(const [
          AdminBanner(
            id: 'b1',
            imageUrl: 'https://example.com/1.png',
            title: 'Ramadan -10%',
            restaurantId: 'r1',
            isActive: true,
          ),
          AdminBanner(
            id: 'b2',
            imageUrl: 'https://example.com/2.png',
            isActive: true,
          ),
          AdminBanner(
            id: 'b3',
            imageUrl: 'https://example.com/3.png',
            title: 'Hidden',
            isActive: false,
          ),
        ]);
      await customerHome(t, banners);
      expect(find.byType(PageView), findsOneWidget);
      expect(find.text('Ramadan -10%'), findsOneWidget);
      expect(find.text('Hidden'), findsNothing);
      await tap(t, find.text('Ramadan -10%'));
      expect(find.byType(RestaurantPage), findsOneWidget);
    },
  );

  testWidgets('admin adds, switches off, reorders and deletes banners', (
    t,
  ) async {
    final banners = FakeBannersRepository();
    final auth = FakeAuthRepository()
      ..seedUser('a@mail.dz', 'secret123', name: 'Admin')
      ..roles['a@mail.dz'] = 'admin'
      ..signInDirect('a@mail.dz');
    await pumpFoodApp(t, repo: auth, banners: banners);
    await tap(t, find.byTooltip('Settings'));
    await t.scrollUntilVisible(
      find.text('Home banners'),
      300,
      scrollable: find
          .byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          )
          .first,
    );
    await tap(t, find.text('Home banners'));
    expect(find.byType(AdminBannersPage), findsOneWidget);
    expect(find.textContaining('No banners yet'), findsOneWidget);

    for (final title in ['First', 'Second']) {
      await tap(t, find.text('Add banner').last);
      await tap(t, find.text('Choose a picture'));
      await t.enterText(find.byType(TextField).last, title);
      await tap(t, find.text('SAVE'));
    }
    expect(banners.list.map((b) => b.title), ['First', 'Second']);
    expect(find.text('First'), findsOneWidget);

    await tap(t, find.byTooltip('Move up').last);
    expect(banners.list.map((b) => b.title), ['Second', 'First']);

    await tap(t, find.byType(Switch).first);
    expect(banners.list.first.isActive, isFalse);

    await tap(t, find.text('Delete').first);
    await tap(t, find.text('Delete').last);
    expect(banners.list.map((b) => b.title), ['First']);
    expect(t.takeException(), isNull);
  });
}
