import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/locale_controller.dart';
import '../catalog/data/catalog_models.dart';

class CartLine {
  const CartLine({
    required this.item,
    required this.quantity,
    this.options = const [],
  });
  final MenuItem item;
  final int quantity;

  /// Chosen options (size, extras...).
  final List<OptionChoice> options;

  /// Same dish with the same options = same line.
  String get key => lineKey(item.id, options);

  /// Display only. The server recalculates prices from the database when
  /// the order is placed.
  int get unitPrice => item.price + options.fold(0, (s, o) => s + o.price);
  int get lineTotal => unitPrice * quantity;

  /// "Large, Extra cheese".
  String get optionsText => options.map((o) => o.name).join(', ');

  CartLine copyWith({
    MenuItem? item,
    int? quantity,
    List<OptionChoice>? options,
  }) => CartLine(
    item: item ?? this.item,
    quantity: quantity ?? this.quantity,
    options: options ?? this.options,
  );
}

/// Line identity: the dish id, plus the sorted option ids.
String lineKey(String itemId, List<OptionChoice> options) =>
    [itemId, ...(options.map((o) => o.id).toList()..sort())].join('|');

/// Do [chosen] choices meet every group's min / max for [item]? Unknown or
/// unavailable choices make it invalid.
bool optionsValid(MenuItem item, List<OptionChoice> chosen) {
  final ids = chosen.map((c) => c.id).toSet();
  if (ids.length != chosen.length) return false;
  var matched = 0;
  for (final g in item.optionGroups) {
    final inGroup = g.choices.where((c) => ids.contains(c.id)).toList();
    if (inGroup.any((c) => !c.isAvailable)) return false;
    if (inGroup.length < g.min || inGroup.length > g.max) return false;
    matched += inGroup.length;
  }
  return matched == ids.length;
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
            options: [
              for (final o in (l['options'] as List? ?? const []))
                OptionChoice.fromJson(Map<String, dynamic>.from(o as Map)),
            ],
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
              {
                'item': l.item.toJson(),
                'qty': l.quantity,
                if (l.options.isNotEmpty)
                  'options': [for (final o in l.options) o.toJson()],
              },
          ],
        }),
      );
    } catch (_) {
      // No storage available: the cart just isn't kept.
    }
  }

  /// Adds [quantity] of [item] with [options]. Refuses (without changing
  /// anything) when the cart already holds another restaurant's dishes,
  /// unless [replace].
  AddResult add(
    MenuItem item, {
    required String restaurantName,
    int quantity = 1,
    bool replace = false,
    List<OptionChoice> options = const [],
  }) {
    if (!state.isEmpty && state.restaurantId != item.restaurantId) {
      if (!replace) return AddResult.otherRestaurant;
      state = const Cart();
    }
    final lines = [...state.lines];
    final key = lineKey(item.id, options);
    final i = lines.indexWhere((l) => l.key == key);
    if (i >= 0) {
      final q = (lines[i].quantity + quantity).clamp(1, maxQuantityPerItem);
      lines[i] = CartLine(item: item, quantity: q, options: options);
    } else if (lines.length < maxCartLines) {
      lines.add(
        CartLine(
          item: item,
          quantity: quantity.clamp(1, maxQuantityPerItem),
          options: options,
        ),
      );
    }
    state = Cart(
      restaurantId: item.restaurantId,
      restaurantName: restaurantName,
      lines: lines,
    );
    return AddResult.added;
  }

  /// [key] is the line's [CartLine.key] (the dish id for a dish without
  /// options).
  void setQuantity(String key, int quantity) {
    final lines = [
      for (final l in state.lines)
        if (l.key != key)
          l
        else if (quantity > 0)
          l.copyWith(quantity: quantity.clamp(1, maxQuantityPerItem)),
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
      // Options as they are now (price, availability, group rules).
      final current = {
        for (final g in now.optionGroups)
          for (final c in g.choices) c.id: c,
      };
      final options = [
        for (final o in l.options)
          if (current[o.id] != null) current[o.id]!,
      ];
      if (options.length != l.options.length || !optionsValid(now, options)) {
        changed = true;
        continue;
      }
      if (now.price != l.item.price ||
          [
            for (var i = 0; i < options.length; i++)
              options[i].price != l.options[i].price,
          ].any((d) => d)) {
        changed = true;
      }
      lines.add(CartLine(item: now, quantity: l.quantity, options: options));
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
