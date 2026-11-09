import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_app/app/router.dart';
import 'package:food_app/core/i18n/locale_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:food_app/core/location/location_service.dart';
import 'package:food_app/features/cart/cart_controller.dart';
import 'package:food_app/features/catalog/data/catalog_models.dart';

const pizza = MenuItem(id: 'p', restaurantId: 'r1', name: 'Pizza', price: 700);
const thon = MenuItem(id: 't', restaurantId: 'r1', name: 'Thon', price: 900);
const burger = MenuItem(
  id: 'b',
  restaurantId: 'r2',
  name: 'Burger',
  price: 850,
);

void main() {
  group('cart', () {
    late ProviderContainer c;
    late CartController cart;
    setUp(() {
      c = ProviderContainer();
      cart = c.read(cartProvider.notifier);
    });
    tearDown(() => c.dispose());

    test('adds, merges lines and totals', () {
      cart.add(pizza, restaurantName: 'A');
      cart.add(pizza, restaurantName: 'A', quantity: 2);
      cart.add(thon, restaurantName: 'A');
      final s = c.read(cartProvider);
      expect(s.lines.length, 2);
      expect(s.count, 4);
      expect(s.subtotal, 3 * 700 + 900);
    });

    test('one restaurant per cart unless replaced', () {
      cart.add(pizza, restaurantName: 'A');
      expect(cart.add(burger, restaurantName: 'B'), AddResult.otherRestaurant);
      expect(c.read(cartProvider).restaurantName, 'A');
      expect(
        cart.add(burger, restaurantName: 'B', replace: true),
        AddResult.added,
      );
      final s = c.read(cartProvider);
      expect(s.restaurantName, 'B');
      expect(s.lines.single.item.id, 'b');
    });

    test('quantity is capped and 0 removes the line', () {
      cart.add(pizza, restaurantName: 'A', quantity: 50);
      expect(c.read(cartProvider).count, maxQuantityPerItem);
      cart.setQuantity('p', 0);
      expect(c.read(cartProvider).isEmpty, isTrue);
      expect(c.read(cartProvider).restaurantId, isNull);
    });
  });

  test('the cart survives a restart (saved on the device)', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    ProviderContainer make() => ProviderContainer(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
    );
    final first = make();
    first.read(cartProvider.notifier)
      ..add(pizza, restaurantName: 'Pizzeria', quantity: 2)
      ..add(thon, restaurantName: 'Pizzeria');
    first.dispose();

    final second = make();
    final cart = second.read(cartProvider);
    expect(cart.restaurantName, 'Pizzeria');
    expect(cart.count, 3);
    expect(cart.subtotal, 2 * 700 + 900);
    second.read(cartProvider.notifier).clear();
    second.dispose();

    final third = make();
    expect(third.read(cartProvider).isEmpty, isTrue);
    third.dispose();
  });

  test('distanceKm: Hydra to Bab Ezzouar is about 13 km', () {
    final d = distanceKm(36.7422, 3.0350, 36.7213, 3.1834);
    expect(d, closeTo(13.4, 0.5));
    expect(formatKm(1.44), '1.4');
    expect(formatKm(13.4), '13');
  });

  group('login return link', () {
    String? r(
      String path, {
      bool signedIn = false,
      String? from,
      String? full,
    }) => authRedirect(
      path: path,
      signedIn: signedIn,
      recoveringPassword: false,
      role: signedIn ? 'customer' : null,
      from: from,
      fullLocation: full,
    );

    test('a QR link while signed out goes to login and back', () {
      expect(
        r('/r/pizzeria', full: '/r/pizzeria'),
        '/login?from=%2Fr%2Fpizzeria',
      );
      expect(r('/login', signedIn: true, from: '/r/pizzeria'), '/r/pizzeria');
    });

    test('never redirects to another site', () {
      expect(r('/login', signedIn: true, from: 'https://evil.com'), '/home');
      expect(r('/login', signedIn: true, from: '//evil.com'), '/home');
    });
  });
}
