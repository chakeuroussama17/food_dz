import 'dart:async';

import 'package:food_app/features/cart/cart_controller.dart' show optionsValid;
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

  /// Same as app_config.tax_rate (0 = older tests' exact totals).
  double taxRate = 0;

  /// Promo codes: CODE → (kind, value, min order).
  final promos = <String, (String, int, int)>{};

  @override
  Future<PromoQuote> checkPromo(
    String restaurantId,
    String code,
    int foodTotal,
  ) async {
    final c = code.trim().toUpperCase();
    final p = promos[c];
    if (p == null) throw const CheckoutError(CheckoutFailure.promoInvalid);
    final (kind, value, min) = p;
    if (foodTotal < min) {
      throw const CheckoutError(CheckoutFailure.promoMinOrder);
    }
    final d = kind == 'percent' ? foodTotal * value ~/ 100 : value;
    return PromoQuote(
      code: c,
      discount: d.clamp(0, foodTotal),
      kind: kind,
      value: value,
    );
  }

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
      // Options like place_order: valid choices only, priced here.
      final chosen = [
        for (final g in m.optionGroups)
          for (final c in g.choices)
            if (i.options.contains(c.id)) c,
      ];
      if (chosen.length != i.options.length || !optionsValid(m, chosen)) {
        throw const CheckoutError(CheckoutFailure.optionsInvalid);
      }
      final unit = m.price + chosen.fold<int>(0, (s, c) => s + c.price);
      lines.add(
        OrderLine(
          name: chosen.isEmpty
              ? m.name
              : '${m.name} (${chosen.map((c) => c.name).join(', ')})',
          unitPrice: unit,
          quantity: i.qty,
          lineTotal: unit * i.qty,
        ),
      );
    }
    final food = lines.fold(0, (s, l) => s + l.lineTotal);
    if (r.paymentMethod != 'cash') {
      throw const CheckoutError(CheckoutFailure.paymentUnavailable);
    }
    final quote = (r.promoCode ?? '').isEmpty
        ? null
        : await checkPromo(r.restaurantId, r.promoCode!, food);
    final price = OrderPrice(
      food: food,
      fee: 200,
      taxRate: taxRate,
      discount: quote?.discount ?? 0,
    );
    if (price.total != r.expectedTotal) {
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
      total: price.total,
      discountAmount: price.discount,
      taxAmount: price.tax,
      promoCode: quote?.code,
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

  final cancelCalls = <String>[];

  @override
  Future<String> cancelOrder(
    String id, {
    String reason = 'other',
    String note = '',
  }) async {
    cancelCalls.add('$id:$reason:$note');
    final o = orders.firstWhere((o) => o.id == id);
    if (o.status == 'placed') {
      setStatus(id, 'cancelled', cancelledBy: 'customer', cancelReason: reason);
      return 'cancelled';
    }
    if (o.status == 'accepted' || o.status == 'ready') {
      if (o.cancelRequestStatus == 'pending') {
        throw const CheckoutError(CheckoutFailure.alreadyRequested);
      }
      if (o.cancelRequestStatus != null) {
        throw const CheckoutError(CheckoutFailure.requestRefused);
      }
      setStatus(id, o.status, request: 'pending', requestReason: reason);
      return 'requested';
    }
    throw const CheckoutError(CheckoutFailure.cannotCancel);
  }

  @override
  Future<String> proofUrl(String path) async => '';

  /// Live rider positions, by order id.
  final riderAt = <String, RiderLocation>{};

  @override
  Future<RiderLocation?> riderLocation(String orderId) async =>
      riderAt[orderId];

  @override
  Stream<void> orderChanges(String id) =>
      (_changes[id] ??= StreamController<void>.broadcast()).stream;

  /// The driver hands over the food: the order becomes delivered now, with
  /// a driver, and the change is pushed live like Realtime.
  void deliver(String id, {String driverName = 'Rachid'}) {
    final i = orders.indexWhere((o) => o.id == id);
    final o = orders[i];
    orders[i] = CustomerOrder(
      id: o.id,
      code: o.code,
      status: 'delivered',
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
      pickedUpAt: o.pickedUpAt,
      deliveredAt: DateTime.now(),
      driverName: driverName,
    );
    _changes[id]?.add(null);
  }

  /// What the restaurant / driver will do: moves the order on and pushes a
  /// live change, like Realtime.
  void setStatus(
    String id,
    String status, {
    String? reason,
    String? cancelledBy,
    String? cancelReason,
    String? request,
    String? requestReason,
  }) {
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
      cancelledBy: cancelledBy ?? o.cancelledBy,
      cancelReason: cancelReason ?? o.cancelReason,
      cancelRequestStatus: request ?? o.cancelRequestStatus,
      cancelRequestReason: requestReason ?? o.cancelRequestReason,
    );
    _changes[id]?.add(null);
  }
}
