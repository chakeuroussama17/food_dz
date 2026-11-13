// Partner portal pages at desktop size, with sample orders.
// Run: flutter test test/screenshots/portal_screenshot_test.dart --update-goldens --tags screenshot --run-skipped
@Tags(['screenshot'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_app/features/admin/data/admin_models.dart';
import 'package:food_app/features/catalog/data/catalog_models.dart'
    show MenuItem, OptionChoice, OptionGroup;
import 'package:food_app/features/restaurant_owner/data/outlet_admin_repository.dart';
import 'package:food_app/features/restaurant_owner/data/owner_orders_repository.dart';
import 'package:food_app/features/restaurant_owner/data/owner_repository.dart';
import 'package:go_router/go_router.dart';

import '../helpers/fake_auth.dart';
import 'restaurant_v2_screenshot_test.dart' show sampleOrders;

OwnerOrder withOutlet(OwnerOrder o, int i) {
  final second = i % 3 == 0;
  return OwnerOrder(
    id: o.id,
    code: o.code,
    status: o.status,
    customerName: o.customerName,
    customerPhone: '05501234${(i % 90 + 10)}',
    addressText: 'Rue Didouche Mourad ${i % 40 + 1}',
    area: o.area,
    foodTotal: o.foodTotal,
    deliveryFee: o.deliveryFee,
    total: o.total,
    placedAt: o.placedAt,
    acceptedAt: o.acceptedAt,
    readyAt: o.readyAt,
    deliveredAt: o.status == 'delivered'
        ? o.placedAt.add(const Duration(minutes: 45))
        : null,
    commissionAmount: o.commissionAmount,
    rejectReason: o.rejectReason,
    driverName: o.driverName,
    items: o.items,
    restaurantId: second ? 'own2' : 'own1',
    restaurantName: second ? 'El Bahdja Hydra' : 'Pizzeria El Bahdja',
    customerKey: 'c${i % 23}',
  );
}

void main() {
  setUpAll(loadFonts);

  const pages = {
    'dashboard': '/',
    'orders': '/orders',
    'reports': '/reports',
    'invoices': '/invoices',
    'outlets': '/outlets',
    'team': '/team',
    'menu': '/menu',
    'hours': '/hours',
  };

  for (final (lang, dark) in [('fr', false), ('ar', false), ('fr', true)]) {
    for (final e in pages.entries) {
      final tag = '${e.key}_$lang${dark ? '_dark' : ''}';
      testWidgets(tag, (t) async {
        final auth = FakeAuthRepository()
          ..seedUser('o@mail.dz', 'secret123', name: 'Omar')
          ..roles['o@mail.dz'] = 'restaurant'
          ..signInDirect('o@mail.dz');
        final owner = FakeOwnerRepository()
          ..restaurant = const OwnedRestaurant(
            id: 'own1',
            slug: 'el-bahdja',
            name: 'Pizzeria El Bahdja',
            area: 'Kouba',
            isActive: true,
            isOpen: true,
          )
          ..otherOutlets.add(
            const OwnedRestaurant(
              id: 'own2',
              slug: 'el-bahdja-hydra',
              name: 'El Bahdja Hydra',
              area: 'Hydra',
              isActive: true,
            ),
          )
          ..teams['own1'] = const [
            TeamMember(
              userId: 'u1',
              name: 'Omar Benali',
              email: 'restaurant@gmail.com',
              role: 'owner',
            ),
            TeamMember(
              userId: 'u2',
              name: 'Mounir Haddad',
              email: 'mounir@gmail.com',
              role: 'manager',
            ),
            TeamMember(
              userId: 'u3',
              name: 'Samia Ouali',
              email: 'samia@gmail.com',
              role: 'staff',
            ),
          ];
        final rows = sampleOrders();
        final orders = FakeOwnerOrdersRepository()
          ..reportOrders.addAll([
            for (var i = 0; i < rows.length; i++)
              if (rows[i].status != 'placed') withOutlet(rows[i], i),
          ])
          ..statementList.addAll([
            for (var m = 0; m < 3; m++)
              StatementSummary(
                id: 's$m',
                number: 'FD-2026-00${12 - m}',
                restaurantId: m == 1 ? 'own2' : 'own1',
                restaurantName: m == 1
                    ? 'El Bahdja Hydra'
                    : 'Pizzeria El Bahdja',
                periodStart: DateTime(2026, 10 - m, 1),
                periodEnd: DateTime(2026, 10 - m, 28),
                ordersCount: 140 - m * 12,
                foodTotal: 210000 - m * 9000,
                commissionTotal: 16800 - m * 700,
                status: m == 0 ? 'issued' : 'paid',
                issuedAt: DateTime(2026, 11 - m, 2),
              ),
          ]);
        orders.addIncoming(customer: 'Lina');
        owner.dishes.addAll(const [
          MenuItem(
            id: 'm1',
            restaurantId: 'own1',
            categoryId: 'c-pizza',
            name: 'Pizza Margherita',
            description: 'Tomate, mozzarella, basilic',
            price: 700,
          ),
          MenuItem(
            id: 'm2',
            restaurantId: 'own1',
            categoryId: 'c-pizza',
            name: 'Pizza Thon',
            price: 900,
          ),
          MenuItem(
            id: 'm3',
            restaurantId: 'own1',
            categoryId: 'c-burger',
            name: 'Burger maison',
            price: 850,
            isAvailable: false,
          ),
          MenuItem(
            id: 'm4',
            restaurantId: 'own1',
            name: 'Tacos poulet',
            price: 600,
          ),
        ]);
        final admin = FakeOutletAdminRepository()
          ..groups['own1'] = [
            const OwnerOptionGroup(
              group: OptionGroup(
                id: 'g1',
                name: 'Taille',
                min: 1,
                max: 1,
                choices: [
                  OptionChoice(id: 'a', name: 'Normale'),
                  OptionChoice(id: 'b', name: 'Grande', price: 300),
                ],
              ),
              itemIds: ['m1', 'm2'],
            ),
            const OwnerOptionGroup(
              group: OptionGroup(
                id: 'g2',
                name: 'Suppléments',
                max: 3,
                choices: [
                  OptionChoice(id: 'c', name: 'Fromage', price: 100),
                  OptionChoice(
                    id: 'd',
                    name: 'Oeuf',
                    price: 80,
                    isAvailable: false,
                  ),
                ],
              ),
              itemIds: ['m1', 'm4'],
            ),
          ]
          ..hoursOf['own1'] = OutletHours(
            weekly: [
              for (var d = 0; d < 6; d++) HourSlot(d, '11:00', '15:00'),
              for (var d = 0; d < 6; d++) HourSlot(d, '18:00', '01:00'),
              HourSlot(6, '14:00', '23:00'),
            ],
            special: [
              SpecialDay(
                day: DateTime(2027, 3, 20),
                closed: true,
                note: 'Aïd el-Fitr',
              ),
            ],
            switchOn: true,
            openNow: true,
          );
        await pumpFoodApp(
          t,
          repo: auth,
          owner: owner,
          ownerOrders: orders,
          lang: lang,
          dark: dark,
          portal: true,
          outletAdmin: admin,
          size: const Size(1440, 1500),
        );
        GoRouter.of(t.element(find.byType(Scaffold).first)).go(e.value);
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('p_$tag.png'),
        );
      });
    }
  }

  testWidgets('orders panel fr', (t) async {
    final auth = FakeAuthRepository()
      ..seedUser('o@mail.dz', 'secret123')
      ..roles['o@mail.dz'] = 'restaurant'
      ..signInDirect('o@mail.dz');
    final owner = FakeOwnerRepository()
      ..restaurant = const OwnedRestaurant(
        id: 'own1',
        slug: 'x',
        name: 'Pizzeria El Bahdja',
        isActive: true,
        isOpen: true,
      );
    final rows = sampleOrders();
    final orders = FakeOwnerOrdersRepository()
      ..reportOrders.addAll([
        for (var i = 0; i < rows.length; i++)
          if (rows[i].status != 'placed') withOutlet(rows[i], 1),
      ]);
    await pumpFoodApp(
      t,
      repo: auth,
      owner: owner,
      ownerOrders: orders,
      lang: 'fr',
      portal: true,
      size: const Size(1440, 1000),
    );
    GoRouter.of(t.element(find.byType(Scaffold).first)).go('/orders');
    await t.pumpAndSettle();
    await t.tap(find.text('7 jours'));
    await t.pumpAndSettle();
    await t.tap(find.text('Pizzeria El Bahdja').at(1));
    await t.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('p_orders_panel_fr.png'),
    );
  });
}
