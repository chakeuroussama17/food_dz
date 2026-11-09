import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env.dart';
import '../../auth/data/auth_providers.dart';
import '../order_status.dart';

class OrderLine {
  const OrderLine({
    required this.name,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
  });

  final String name;
  final int unitPrice;
  final int quantity;
  final int lineTotal;

  factory OrderLine.fromJson(Map<String, dynamic> j) => OrderLine(
    name: j['name'] as String,
    unitPrice: (j['unit_price'] as num).toInt(),
    quantity: (j['quantity'] as num).toInt(),
    lineTotal: (j['line_total'] as num).toInt(),
  );
}

/// One of the signed-in customer's orders (from `my_orders`).
class CustomerOrder {
  const CustomerOrder({
    required this.id,
    required this.code,
    required this.status,
    required this.restaurantId,
    required this.restaurantName,
    required this.addressText,
    required this.customerPhone,
    required this.foodTotal,
    required this.deliveryFee,
    required this.total,
    required this.placedAt,
    required this.items,
    this.restaurantLogo,
    this.restaurantSlug,
    this.restaurantPhone,
    this.area = '',
    this.addressDetails = '',
    this.notes = '',
    this.rejectReason,
    this.acceptedAt,
    this.readyAt,
    this.pickedUpAt,
    this.deliveredAt,
    this.cancelledAt,
    this.driverName,
    this.driverPhone,
    this.deliveryPhotoPath,
  });

  /// Proof of delivery taken by the driver (private storage path).
  final String? deliveryPhotoPath;

  /// Set once a driver has taken the order.
  final String? driverName;
  final String? driverPhone;

  final String id;
  final String code;

  /// `public.order_status`: placed, accepted, rejected, ready, picked_up,
  /// delivered, cancelled.
  final String status;
  final String restaurantId;
  final String restaurantName;
  final String? restaurantLogo;
  final String? restaurantSlug;
  final String? restaurantPhone;
  final String addressText;
  final String area;
  final String addressDetails;
  final String customerPhone;
  final String notes;
  final int foodTotal;
  final int deliveryFee;
  final int total;
  final String? rejectReason;
  final DateTime placedAt;
  final DateTime? acceptedAt;
  final DateTime? readyAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;
  final List<OrderLine> items;

  bool get isActive => activeOrderStatuses.contains(status);
  bool get isFailed => status == 'rejected' || status == 'cancelled';

  /// Customers can cancel until the restaurant accepts.
  bool get canCancel => status == 'placed';
  int get itemCount => items.fold(0, (n, i) => n + i.quantity);

  static DateTime? _ts(Object? v) =>
      v == null ? null : DateTime.parse(v as String).toLocal();

  factory CustomerOrder.fromJson(Map<String, dynamic> j) => CustomerOrder(
    id: j['id'] as String,
    code: j['code'] as String,
    status: j['status'] as String,
    restaurantId: j['restaurant_id'] as String,
    restaurantName: j['restaurant_name'] as String,
    restaurantLogo: j['restaurant_logo'] as String?,
    restaurantSlug: j['restaurant_slug'] as String?,
    restaurantPhone: j['restaurant_phone'] as String?,
    addressText: j['address_text'] as String,
    area: (j['area'] as String?) ?? '',
    addressDetails: (j['address_details'] as String?) ?? '',
    customerPhone: j['customer_phone'] as String,
    notes: (j['notes'] as String?) ?? '',
    foodTotal: (j['food_total'] as num).toInt(),
    deliveryFee: (j['delivery_fee'] as num).toInt(),
    total: (j['total'] as num).toInt(),
    rejectReason: j['reject_reason'] as String?,
    placedAt: _ts(j['placed_at'])!,
    acceptedAt: _ts(j['accepted_at']),
    readyAt: _ts(j['ready_at']),
    pickedUpAt: _ts(j['picked_up_at']),
    deliveredAt: _ts(j['delivered_at']),
    cancelledAt: _ts(j['cancelled_at']),
    driverName: j['driver_name'] as String?,
    driverPhone: j['driver_phone'] as String?,
    deliveryPhotoPath: j['delivery_photo_path'] as String?,
    items: [
      for (final i in (j['items'] as List? ?? const []))
        OrderLine.fromJson(i as Map<String, dynamic>),
    ],
  );
}

/// What the app sends to `place_order`: ids and quantities only. The
/// database looks up every price.
class PlaceOrderRequest {
  const PlaceOrderRequest({
    required this.restaurantId,
    required this.items,
    required this.addressId,
    required this.phone,
    required this.expectedTotal,
    required this.clientRef,
    this.notes = '',
  });

  final String restaurantId;
  final List<({String id, int qty})> items;
  final String addressId;
  final String phone;
  final String notes;

  /// Total the customer saw; the order is refused if prices changed.
  final int expectedTotal;

  /// Same value on a retry = same order (no double orders).
  final String clientRef;
}

class PlacedOrder {
  const PlacedOrder({
    required this.id,
    required this.code,
    required this.total,
  });
  final String id;
  final String code;
  final int total;
}

enum CheckoutFailure {
  restaurantClosed,
  restaurantUnavailable,
  itemUnavailable,
  pricesChanged,
  tooManyActiveOrders,
  tooManyOrders,
  invalidPhone,
  addressNotFound,
  cannotCancel,
  network,
  unknown,
}

class CheckoutError implements Exception {
  const CheckoutError(this.failure);
  final CheckoutFailure failure;
  @override
  String toString() => 'CheckoutError($failure)';
}

/// Maps the error keys raised by the checkout functions.
CheckoutFailure checkoutFailureFromMessage(String message) {
  for (final (key, f) in const [
    ('restaurant_closed', CheckoutFailure.restaurantClosed),
    ('restaurant_unavailable', CheckoutFailure.restaurantUnavailable),
    ('item_unavailable', CheckoutFailure.itemUnavailable),
    ('prices_changed', CheckoutFailure.pricesChanged),
    ('too_many_active_orders', CheckoutFailure.tooManyActiveOrders),
    ('too_many_orders', CheckoutFailure.tooManyOrders),
    ('invalid_phone', CheckoutFailure.invalidPhone),
    ('address_not_found', CheckoutFailure.addressNotFound),
    ('cannot_cancel', CheckoutFailure.cannotCancel),
  ]) {
    if (message.contains(key)) return f;
  }
  return CheckoutFailure.unknown;
}

/// Random UUID v4 for [PlaceOrderRequest.clientRef].
String newClientRef([Random? random]) {
  final r = random ?? Random.secure();
  final b = List<int>.generate(16, (_) => r.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-'
      '${h.substring(16, 20)}-${h.substring(20)}';
}

abstract interface class OrdersRepository {
  /// Throws [CheckoutError].
  Future<PlacedOrder> placeOrder(PlaceOrderRequest request);
  Future<List<CustomerOrder>> myOrders();
  Future<CustomerOrder?> myOrder(String id);

  /// Throws [CheckoutError] (cannotCancel once the restaurant accepted).
  Future<void> cancelOrder(String id);

  /// Fires when order [id] changes (live status). Cancel to stop listening.
  Stream<void> orderChanges(String id);

  /// Temporary link to a delivery photo (private storage).
  Future<String> proofUrl(String path);
}

class SupabaseOrdersRepository implements OrdersRepository {
  SupabaseOrdersRepository(this._db);
  final SupabaseClient _db;

  Future<T> _guard<T>(Future<T> Function() f) async {
    try {
      return await f();
    } on PostgrestException catch (e) {
      throw CheckoutError(checkoutFailureFromMessage(e.message));
    } on CheckoutError {
      rethrow;
    } catch (_) {
      throw const CheckoutError(CheckoutFailure.network);
    }
  }

  @override
  Future<PlacedOrder> placeOrder(PlaceOrderRequest r) => _guard(() async {
    final rows = await _db.rpc(
      'place_order',
      params: {
        'p_restaurant_id': r.restaurantId,
        'p_items': [
          for (final i in r.items) {'id': i.id, 'qty': i.qty},
        ],
        'p_address_id': r.addressId,
        'p_phone': r.phone,
        'p_notes': r.notes,
        'p_expected_total': r.expectedTotal,
        'p_client_ref': r.clientRef,
      },
    );
    final row = (rows as List).first as Map<String, dynamic>;
    return PlacedOrder(
      id: row['id'] as String,
      code: row['code'] as String,
      total: (row['total'] as num).toInt(),
    );
  });

  @override
  Future<List<CustomerOrder>> myOrders() async {
    final rows = await _db.rpc('my_orders');
    return [
      for (final r in rows as List)
        CustomerOrder.fromJson(r as Map<String, dynamic>),
    ];
  }

  @override
  Future<CustomerOrder?> myOrder(String id) async {
    final rows = await _db.rpc('my_orders', params: {'p_order_id': id});
    final list = rows as List;
    return list.isEmpty
        ? null
        : CustomerOrder.fromJson(list.first as Map<String, dynamic>);
  }

  @override
  Future<void> cancelOrder(String id) =>
      _guard(() => _db.rpc('cancel_my_order', params: {'p_order_id': id}));

  @override
  Future<String> proofUrl(String path) =>
      _db.storage.from('delivery-proofs').createSignedUrl(path, 600);

  @override
  Stream<void> orderChanges(String id) {
    late final StreamController<void> ctrl;
    RealtimeChannel? channel;
    ctrl = StreamController<void>(
      onListen: () {
        channel = _db
            .channel('order-$id')
            .onPostgresChanges(
              event: PostgresChangeEvent.update,
              schema: 'public',
              table: 'orders',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'id',
                value: id,
              ),
              callback: (_) => ctrl.add(null),
            )
            .subscribe();
      },
      onCancel: () async {
        final c = channel;
        if (c != null) await _db.removeChannel(c);
      },
    );
    return ctrl.stream;
  }
}

final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  if (!Env.hasSupabase) {
    throw StateError('Supabase not configured (env.json)');
  }
  return SupabaseOrdersRepository(Supabase.instance.client);
});

final myOrdersProvider = FutureProvider<List<CustomerOrder>>((ref) {
  ref.watch(currentUserIdProvider);
  return ref.watch(ordersRepositoryProvider).myOrders();
});

final myOrderProvider = FutureProvider.family<CustomerOrder?, String>((
  ref,
  id,
) {
  ref.watch(currentUserIdProvider);
  return ref.watch(ordersRepositoryProvider).myOrder(id);
});

/// Signed link to a delivery photo (valid 10 minutes).
final proofUrlProvider = FutureProvider.family<String, String>(
  (ref, path) => ref.watch(ordersRepositoryProvider).proofUrl(path),
);
