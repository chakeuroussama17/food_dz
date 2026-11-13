import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_app/core/utils/money.dart';
import 'package:food_app/features/cart/cart_controller.dart';
import 'package:food_app/features/catalog/data/catalog_models.dart';
import 'package:food_app/features/catalog/widgets/opening_text.dart';
import 'package:food_app/features/restaurant_owner/data/outlet_admin_repository.dart';
import 'package:food_app/features/restaurant_owner/data/owner_repository.dart';
import 'package:food_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'checkout_flow_test.dart' show Setup, signedIn, tap;
import 'helpers/fake_auth.dart';

const size = OptionGroup(
  id: 'g-size',
  name: 'Size',
  min: 1,
  max: 1,
  choices: [
    OptionChoice(id: 'c-s', name: 'Small'),
    OptionChoice(id: 'c-l', name: 'Large', price: 300),
  ],
);
const extras = OptionGroup(
  id: 'g-extra',
  name: 'Extras',
  max: 2,
  choices: [
    OptionChoice(id: 'c-cheese', name: 'Cheese', price: 100),
    OptionChoice(id: 'c-olive', name: 'Olives', price: 50),
    OptionChoice(id: 'c-egg', name: 'Egg', price: 80, isAvailable: false),
  ],
);
const pizza = MenuItem(
  id: 'i9',
  restaurantId: 'r1',
  categoryId: 'c-pizza',
  name: 'Pizza Royale',
  price: 1000,
  restaurantName: 'Pizzeria El Bahdja',
  restaurantSlug: 'pizzeria-el-bahdja',
  optionGroups: [size, extras],
);

OptionChoice choice(String id) =>
    [...size.choices, ...extras.choices].firstWhere((c) => c.id == id);

String money(int n) => formatDzd(n, 'en');

void main() {
  setUpAll(loadFonts);

  group('option rules', () {
    test('required, max, unavailable, unknown and duplicate choices', () {
      expect(optionsValid(pizza, [choice('c-s')]), isTrue);
      expect(optionsValid(pizza, []), isFalse); // size required
      expect(
        optionsValid(pizza, [
          choice('c-l'),
          choice('c-cheese'),
          choice('c-olive'),
        ]),
        isTrue,
      );
      expect(optionsValid(pizza, [choice('c-s'), choice('c-l')]), isFalse);
      expect(optionsValid(pizza, [choice('c-s'), choice('c-egg')]), isFalse);
      expect(
        optionsValid(pizza, [
          choice('c-s'),
          const OptionChoice(id: 'x', name: 'X'),
        ]),
        isFalse,
      );
      expect(optionsValid(pizza, [choice('c-s'), choice('c-s')]), isFalse);
    });

    test('a line per dish + options; prices and keys', () {
      final a = CartLine(
        item: pizza,
        quantity: 2,
        options: [choice('c-l'), choice('c-cheese')],
      );
      expect(a.unitPrice, 1400);
      expect(a.lineTotal, 2800);
      expect(a.optionsText, 'Large, Cheese');
      // Same options in another order = same line.
      expect(lineKey('i9', [choice('c-cheese'), choice('c-l')]), a.key);
      expect(const CartLine(item: pizza, quantity: 1).key, 'i9');
    });
  });

  test('closed text: today, tomorrow, later, unknown', () async {
    await initializeDateFormatting('en');
    final l = await AppLocalizations.delegate.load(const Locale('en'));
    final now = DateTime.now();
    String at(int days, int h) =>
        closedText(l, 'en', DateTime(now.year, now.month, now.day + days, h));
    expect(at(0, 23), 'Closed · opens today at 23:00');
    expect(at(1, 11), 'Closed · opens tomorrow at 11:00');
    expect(at(3, 12), startsWith('Closed · opens '));
    expect(at(3, 12), endsWith(' at 12:00'));
    expect(closedText(l, 'en', null), l.restaurantClosedNote);
  });

  testWidgets('customer picks options, cart and order follow them', (t) async {
    final s = Setup();
    s.catalog.items.add(pizza);
    await signedIn(t, s);
    await tap(t, find.text('Pizzeria El Bahdja').last);
    await t.scrollUntilVisible(
      find.text('Pizza Royale'),
      200,
      scrollable: find
          .byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          )
          .first,
    );
    // Quick "+" on a dish with options opens the options sheet.
    await tap(
      t,
      find
              .descendant(
                of: find
                    .ancestor(
                      of: find.text('Pizza Royale'),
                      matching: find.byType(Row),
                    )
                    .first,
                matching: find.byIcon(Icons.add_rounded),
              )
              .evaluate()
              .isEmpty
          ? find.byIcon(Icons.add_rounded).last
          : find
                .descendant(
                  of: find
                      .ancestor(
                        of: find.text('Pizza Royale'),
                        matching: find.byType(Row),
                      )
                      .first,
                  matching: find.byIcon(Icons.add_rounded),
                )
                .first,
    );
    expect(find.text('Size'), findsOneWidget);
    expect(find.text('Out of stock'), findsOneWidget); // the egg
    await tap(t, find.text('Large'));
    await tap(t, find.text('Cheese'));
    await tap(t, find.text('Olives'));
    expect(find.textContaining(money(1450)), findsOneWidget);
    await tap(t, find.textContaining('ADD TO CART'));

    await tap(t, find.byIcon(Icons.shopping_bag_outlined).first);
    expect(find.text('Large, Cheese, Olives'), findsOneWidget);
    await tap(t, find.text('GO TO CHECKOUT'));
    await tap(t, find.textContaining('PLACE ORDER'));
    final r = s.orders.requests.single;
    expect(r.items.single.options, ['c-l', 'c-cheese', 'c-olive']);
    expect(r.expectedTotal, 1450 + 200);
    expect(
      s.orders.orders.single.items.single.name,
      'Pizza Royale (Large, Cheese, Olives)',
    );
  });

  testWidgets('closed restaurant shows when it opens next', (t) async {
    final s = Setup();
    final now = DateTime.now();
    s.catalog.restaurantsList[0] = s.catalog.restaurantsList[0].withStatus(
      open: false,
      nextOpenAt: DateTime(now.year, now.month, now.day + 1, 11),
    );
    await signedIn(t, s);
    GoRouter.of(
      t.element(find.byType(Scaffold).first),
    ).go('/r/pizzeria-el-bahdja');
    await t.pumpAndSettle();
    expect(find.text('Closed · opens tomorrow at 11:00'), findsOneWidget);
  });

  group('portal', () {
    Future<(FakeOutletAdminRepository, FakeOwnerRepository)> portal(
      WidgetTester t,
      String path,
    ) async {
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
        )
        ..dishes.addAll(const [
          MenuItem(
            id: 'm1',
            restaurantId: 'own1',
            name: 'Pizza Thon',
            price: 900,
          ),
          MenuItem(id: 'm2', restaurantId: 'own1', name: 'Burger', price: 650),
          MenuItem(id: 'm3', restaurantId: 'own1', name: 'Tacos', price: 500),
        ]);
      final admin = FakeOutletAdminRepository();
      admin.groups['own1'] = [
        OwnerOptionGroup(group: size, itemIds: const ['m1']),
      ];
      admin.hoursOf['own1'] = OutletHours(
        weekly: const [HourSlot(0, '11:00', '23:00')],
        special: [
          SpecialDay(day: DateTime(2027, 3, 20), closed: true, note: 'Aïd'),
        ],
        switchOn: true,
        openNow: false,
        nextOpenAt: DateTime.now().add(const Duration(days: 1)),
      );
      await pumpFoodApp(
        t,
        repo: auth,
        owner: owner,
        outletAdmin: admin,
        portal: true,
        size: const Size(1440, 1100),
      );
      GoRouter.of(t.element(find.byType(Scaffold).first)).go(path);
      await t.pumpAndSettle();
      return (admin, owner);
    }

    testWidgets('menu: dishes, bulk hide and price change', (t) async {
      final (admin, _) = await portal(t, '/menu');
      expect(find.text('Pizza Thon'), findsOneWidget);
      expect(find.text('Size'), findsOneWidget); // options column
      await t.tap(find.byType(Checkbox).at(1));
      await t.tap(find.byType(Checkbox).at(2));
      await t.pumpAndSettle();
      expect(find.text('2 selected'), findsOneWidget);
      await t.tap(find.text('Hide'));
      await t.pumpAndSettle();
      expect(admin.calls.last, 'bulk:hide:2:');

      await t.tap(find.byType(Checkbox).at(3));
      await t.pumpAndSettle();
      await t.tap(find.text('Change prices'));
      await t.pumpAndSettle();
      await t.tap(find.text('Apply'));
      await t.pumpAndSettle();
      expect(admin.calls.last, 'bulk:pricePercent:1:10');
    });

    testWidgets('menu: edit a dish and give it option groups', (t) async {
      final (admin, owner) = await portal(t, '/menu');
      await t.tap(find.byTooltip('Edit item').at(1)); // Burger
      await t.pumpAndSettle();
      await t.tap(find.widgetWithText(FilterChip, 'Size'));
      await t.pumpAndSettle();
      await t.tap(find.text('Save changes').last);
      await t.pumpAndSettle();
      expect(admin.calls, contains('itemGroups:m2:g-size'));
      expect(owner.dishes.firstWhere((d) => d.id == 'm2').name, 'Burger');
    });

    testWidgets('menu: create an option group', (t) async {
      final (admin, _) = await portal(t, '/menu');
      await t.tap(find.text('Option groups (1)'));
      await t.pumpAndSettle();
      expect(find.text('Required · choose 1'), findsOneWidget);
      await t.tap(find.text('Add option group'));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextFormField).at(0), 'Extras');
      await t.tap(find.text('Required').last); // make it optional
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextFormField).at(1), 'Cheese');
      await t.enterText(find.byType(TextFormField).at(2), '100');
      await t.enterText(find.byType(TextFormField).at(3), 'Egg');
      await t.tap(find.widgetWithText(FilterChip, 'Tacos'));
      await t.tap(find.text('Save changes').last);
      await t.pumpAndSettle();
      final g = admin.groups['own1']!.last;
      expect(g.group.name, 'Extras');
      expect(g.group.min, 0);
      expect(g.group.choices.map((c) => (c.name, c.price)), [
        ('Cheese', 100),
        ('Egg', 0),
      ]);
      expect(g.itemIds, ['m3']);
      expect(find.text('Optional · up to 1'), findsOneWidget);
    });

    testWidgets('hours: status, weekly editor, holidays', (t) async {
      final (admin, _) = await portal(t, '/hours');
      expect(find.text('Closed now'), findsOneWidget);
      expect(find.textContaining('11:00 – 23:00'), findsOneWidget);
      // Copy Saturday to every day and save.
      await t.tap(find.byTooltip('Copy to every day'));
      await t.pumpAndSettle();
      await t.tap(find.text('Save changes'));
      await t.pumpAndSettle();
      expect(admin.calls.last, 'hours:7');

      await t.tap(find.text('Holidays and special hours'));
      await t.pumpAndSettle();
      expect(find.textContaining('Aïd'), findsOneWidget);
      await t.tap(find.byTooltip('Delete'));
      await t.pumpAndSettle();
      expect(admin.calls.last, 'deleteSpecial');
      expect(t.takeException(), isNull);
    });
  });
}
