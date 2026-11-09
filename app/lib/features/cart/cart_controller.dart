import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/locale_controller.dart';
import '../catalog/data/catalog_models.dart';

class CartLine {
  const CartLine({required this.item, required this.quantity});
  final MenuItem item;
  final int quantity;

  /// Display only. The server recalculates prices from the database when
  /// the order is placed.
  int get lineTotal => item.price * quantity;
}

class Cart {
  const Cart({this.restaurantId, this.restaurantName, this.lines = const []});

  /// A cart holds dishes from one restaurant only.
  final String? restaurantId;
  final String? restaurantName;
  final List<CartLine> lines;

  int get count => lines.fold(0, (n, l) => n + l.quantity);
  int get subtotal => lines.fold(0, (n, l) => n + l.lineTotal);
  bool get isEmpty => lines.isEmpty;
}

enum AddResult { added, otherRestaurant }

const maxQuantityPerItem = 20;
const maxCartLines = 30;

final cartProvider = NotifierProvider<CartController, Cart>(CartController.new);

class CartController extends Notifier<Cart> {
  static const _key = 'cart_v1';

  /// The cart is kept on the device, so a refresh (web) or closing the app
  /// doesn't lose it. Prices are checked again when the order is placed.
  @override
  Cart build() {
    listenSelf((_, next) => _save(next));
    return _load();
  }

  Cart _load() {
    try {
      final raw = ref.read(sharedPrefsProvider).getString(_key);
      if (raw == null) return const Cart();
      final j = jsonDecode(raw) as Map<String, dynamic>;
      final lines = [
        for (final l in (j['lines'] as List))
          CartLine(
            item: MenuItem.fromJson(
              Map<String, dynamic>.from(l['item'] as Map),
            ),
            quantity: (l['qty'] as num).toInt().clamp(1, maxQuantityPerItem),
          ),
      ];
      if (lines.isEmpty) return const Cart();
      return Cart(
        restaurantId: j['restaurant_id'] as String?,
        restaurantName: j['restaurant_name'] as String?,
        lines: lines.take(maxCartLines).toList(),
      );
    } catch (_) {
      // No storage (tests) or an old/damaged value: start empty.
      return const Cart();
    }
  }

  void _save(Cart c) {
    try {
      final prefs = ref.read(sharedPrefsProvider);
      if (c.isEmpty) {
        prefs.remove(_key);
        return;
      }
      prefs.setString(
        _key,
        jsonEncode({
          'restaurant_id': c.restaurantId,
          'restaurant_name': c.restaurantName,
          'lines': [
            for (final l in c.lines)
              {'item': l.item.toJson(), 'qty': l.quantity},
          ],
        }),
      );
    } catch (_) {
      // No storage available: the cart just isn't kept.
    }
  }

  /// Adds [quantity] of [item]. Refuses (without changing anything) when the
  /// cart already holds another restaurant's dishes, unless [replace].
  AddResult add(
    MenuItem item, {
    required String restaurantName,
    int quantity = 1,
    bool replace = false,
  }) {
    if (!state.isEmpty && state.restaurantId != item.restaurantId) {
      if (!replace) return AddResult.otherRestaurant;
      state = const Cart();
    }
    final lines = [...state.lines];
    final i = lines.indexWhere((l) => l.item.id == item.id);
    if (i >= 0) {
      final q = (lines[i].quantity + quantity).clamp(1, maxQuantityPerItem);
      lines[i] = CartLine(item: item, quantity: q);
    } else if (lines.length < maxCartLines) {
      lines.add(
        CartLine(item: item, quantity: quantity.clamp(1, maxQuantityPerItem)),
      );
    }
    state = Cart(
      restaurantId: item.restaurantId,
      restaurantName: restaurantName,
      lines: lines,
    );
    return AddResult.added;
  }

  void setQuantity(String itemId, int quantity) {
    final lines = [
      for (final l in state.lines)
        if (l.item.id != itemId)
          l
        else if (quantity > 0)
          CartLine(
            item: l.item,
            quantity: quantity.clamp(1, maxQuantityPerItem),
          ),
    ];
    state = lines.isEmpty
        ? const Cart()
        : Cart(
            restaurantId: state.restaurantId,
            restaurantName: state.restaurantName,
            lines: lines,
          );
  }

  void clear() => state = const Cart();

  /// Applies the database's current prices and availability. Dishes that
  /// are missing from [current] or unavailable are removed. Returns true
  /// when anything changed.
  bool syncWith(List<MenuItem> current) {
    final byId = {for (final i in current) i.id: i};
    var changed = false;
    final lines = <CartLine>[];
    for (final l in state.lines) {
      final now = byId[l.item.id];
      if (now == null || !now.isAvailable) {
        changed = true;
        continue;
      }
      if (now.price != l.item.price) changed = true;
      lines.add(CartLine(item: now, quantity: l.quantity));
    }
    if (!changed) return false;
    state = lines.isEmpty
        ? const Cart()
        : Cart(
            restaurantId: state.restaurantId,
            restaurantName: state.restaurantName,
            lines: lines,
          );
    return true;
  }
}
