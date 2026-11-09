import 'dart:async';

import 'package:food_app/features/catalog/data/catalog_models.dart';
import 'package:food_app/features/orders/data/orders_repository.dart';

/// In-memory orders backend with the same rules as `place_order`:
/// prices come from [menu] (the "database"), the fee is 200 DA, the total
/// must match, and the same clientRef returns the same order.
class FakeOrdersRepository implements OrdersRepository {
  FakeOrdersRepository({List<MenuItem>? menu, this.restaurantNames = const {}})
    : menu = menu ?? const [];

  /// Current dishes in the "database".
  List<MenuItem> menu;
  final Map<String, String> restaurantNames;
  final orders = <CustomerOrder>[];
  final requests = <PlaceOrderRequest>[];
  final _byRef = <String, CustomerOrder>{};
  final _changes = <String, StreamController<void>>{};

  /// Next placeOrder call throws this (once).
  CheckoutFailure? failNext;
  var _n = 0;

  @override
  Future<PlacedOrder> placeOrder(PlaceOrderRequest r) async {
    requests.add(r);
    final fail = failNext;
    if (fail != null) {
      failNext = null;
      throw CheckoutError(fail);
    }
    final existing = _byRef[r.clientRef];
    if (existing != null) {
      return PlacedOrder(
        id: existing.id,
        code: existing.code,
        total: existing.total,
      );
    }
    final lines = <OrderLine>[];
    for (final i in r.items) {
      final m = menu.where((m) => m.id == i.id).firstOrNull;
      if (m == null || !m.isAvailable || m.restaurantId != r.restaurantId) {
        throw const CheckoutError(CheckoutFailure.itemUnavailable);
      }
      lines.add(
        OrderLine(
          name: m.name,
          unitPrice: m.price,
          quantity: i.qty,
          lineTotal: m.price * i.qty,
        ),
      );
    }
    final food = lines.fold(0, (s, l) => s + l.lineTotal);
    if (food + 200 != r.expectedTotal) {
      throw const CheckoutError(CheckoutFailure.pricesChanged);
    }
    _n++;
    final o = CustomerOrder(
      id: 'o$_n',
      code: 'ABC23$_n',
      status: 'placed',
      restaurantId: r.restaurantId,
      restaurantName: restaurantNames[r.restaurantId] ?? r.restaurantId,
      addressText: 'Rue Didouche 12',
      customerPhone: r.phone,
      notes: r.notes,
      foodTotal: food,
      deliveryFee: 200,
      total: food + 200,
      placedAt: DateTime(2026, 11, 8, 12, 30),
      items: lines,
    );
    orders.insert(0, o);
    _byRef[r.clientRef] = o;
    return PlacedOrder(id: o.id, code: o.code, total: o.total);
  }

  @override
  Future<List<CustomerOrder>> myOrders() async => [...orders];

  @override
  Future<CustomerOrder?> myOrder(String id) async =>
      orders.where((o) => o.id == id).firstOrNull;

  @override
  Future<void> cancelOrder(String id) async {
    final o = orders.firstWhere((o) => o.id == id);
    if (o.status != 'placed') {
      throw const CheckoutError(CheckoutFailure.cannotCancel);
    }
    setStatus(id, 'cancelled');
  }

  @override
  Future<String> proofUrl(String path) async => '';

  @override
  Stream<void> orderChanges(String id) =>
      (_changes[id] ??= StreamController<void>.broadcast()).stream;

  /// What the restaurant / driver will do: moves the order on and pushes a
  /// live change, like Realtime.
  void setStatus(String id, String status, {String? reason}) {
    final i = orders.indexWhere((o) => o.id == id);
    final o = orders[i];
    final now = DateTime(2026, 11, 8, 12, 40);
    orders[i] = CustomerOrder(
      id: o.id,
      code: o.code,
      status: status,
      restaurantId: o.restaurantId,
      restaurantName: o.restaurantName,
      addressText: o.addressText,
      customerPhone: o.customerPhone,
      notes: o.notes,
      foodTotal: o.foodTotal,
      deliveryFee: o.deliveryFee,
      total: o.total,
      placedAt: o.placedAt,
      items: o.items,
      rejectReason: reason,
      acceptedAt: status == 'accepted' ? now : o.acceptedAt,
      cancelledAt: status == 'cancelled' || status == 'rejected'
          ? now
          : o.cancelledAt,
    );
    _changes[id]?.add(null);
  }
}
