import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env.dart';
import '../../admin/data/admin_models.dart'
    show StatementDetail, StatementSummary;
import '../../auth/data/auth_providers.dart';
import '../../orders/data/orders_repository.dart' show OrderLine;

export '../../orders/data/orders_repository.dart' show OrderLine;

/// An order as the restaurant sees it (from `owner_orders`): with the
/// customer's name, phone and address so the restaurant can call them.
class OwnerOrder {
  const OwnerOrder({
    required this.id,
    required this.code,
    required this.status,
    required this.customerName,
    required this.customerPhone,
    required this.addressText,
    required this.foodTotal,
    required this.deliveryFee,
    required this.total,
    required this.placedAt,
    required this.items,
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
  });

  /// Set once a driver has taken the order.
  final String? driverName;
  final String? driverPhone;

  final String id;
  final String code;
  final String status;
  final String customerName;
  final String customerPhone;
  final String addressText;
  final String area;
  final String addressDetails;
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

  bool get isNew => status == 'placed';

  /// Accepted, ready or with the driver.
  bool get isRunning =>
      status == 'accepted' || status == 'ready' || status == 'picked_up';

  /// "2× Pizza Margherita, 1× Pizza Thon".
  String get summary => items.map((i) => '${i.quantity}× ${i.name}').join(', ');

  static DateTime? _ts(Object? v) =>
      v == null ? null : DateTime.parse(v as String).toLocal();

  factory OwnerOrder.fromJson(Map<String, dynamic> j) => OwnerOrder(
    id: j['id'] as String,
    code: j['code'] as String,
    status: j['status'] as String,
    customerName: j['customer_name'] as String,
    customerPhone: j['customer_phone'] as String,
    addressText: j['address_text'] as String,
    area: (j['area'] as String?) ?? '',
    addressDetails: (j['address_details'] as String?) ?? '',
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
    items: [
      for (final i in (j['items'] as List? ?? const []))
        OrderLine.fromJson(i as Map<String, dynamic>),
    ],
  );
}

/// Food money a driver must give to the restaurant (delivered orders).
class CashToReceive {
  const CashToReceive({
    required this.orderId,
    required this.code,
    required this.amount,
    required this.deliveredAt,
    this.driverName = '',
    this.driverPhone = '',
    this.handedAt,
  });

  final String orderId;
  final String code;
  final int amount;
  final DateTime deliveredAt;
  final String driverName;
  final String driverPhone;

  /// The driver says the money was handed over.
  final DateTime? handedAt;

  factory CashToReceive.fromJson(Map<String, dynamic> j) => CashToReceive(
    orderId: j['id'] as String,
    code: j['code'] as String,
    amount: (j['food_total'] as num).toInt(),
    deliveredAt: DateTime.parse(j['delivered_at'] as String).toLocal(),
    driverName: (j['driver_name'] as String?) ?? '',
    driverPhone: (j['driver_phone'] as String?) ?? '',
    handedAt: j['cash_handed_at'] == null
        ? null
        : DateTime.parse(j['cash_handed_at'] as String).toLocal(),
  );
}

enum OwnerOrderFailure { notAllowed, reasonRequired, notFound, network }

class OwnerOrderError implements Exception {
  const OwnerOrderError(this.failure);
  final OwnerOrderFailure failure;
  @override
  String toString() => 'OwnerOrderError($failure)';
}

abstract interface class OwnerOrdersRepository {
  /// Orders in progress, oldest first.
  Future<List<OwnerOrder>> activeOrders();

  /// Finished orders (delivered, rejected, cancelled), newest first.
  Future<List<OwnerOrder>> history();

  /// accepted / rejected / ready / cancelled. Throws [OwnerOrderError].
  Future<void> setStatus(String orderId, String status, {String? reason});

  /// Fires on every new or changed order of the restaurant (Realtime).
  Stream<void> restaurantChanges(String restaurantId);

  /// Delivered orders whose food money isn't confirmed yet.
  Future<List<CashToReceive>> cashPending();

  /// "Money received". Throws [OwnerOrderError].
  Future<void> confirmCash(String orderId);

  /// Commission statements the admin issued to this restaurant.
  Future<List<StatementSummary>> statements();
  Future<StatementDetail> statementDetail(String id);
}

class SupabaseOwnerOrdersRepository implements OwnerOrdersRepository {
  SupabaseOwnerOrdersRepository(this._db);
  final SupabaseClient _db;

  Future<List<OwnerOrder>> _list(bool active) async {
    final rows = await _db.rpc('owner_orders', params: {'p_active': active});
    return [
      for (final r in rows as List)
        OwnerOrder.fromJson(r as Map<String, dynamic>),
    ];
  }

  @override
  Future<List<OwnerOrder>> activeOrders() => _list(true);

  @override
  Future<List<OwnerOrder>> history() => _list(false);

  @override
  Future<void> setStatus(
    String orderId,
    String status, {
    String? reason,
  }) async {
    try {
      await _db.rpc(
        'owner_set_order_status',
        params: {'p_order_id': orderId, 'p_status': status, 'p_reason': reason},
      );
    } on PostgrestException catch (e) {
      final m = e.message;
      throw OwnerOrderError(
        m.contains('reason_required')
            ? OwnerOrderFailure.reasonRequired
            : m.contains('order_not_found')
            ? OwnerOrderFailure.notFound
            : OwnerOrderFailure.notAllowed,
      );
    } catch (_) {
      throw const OwnerOrderError(OwnerOrderFailure.network);
    }
  }

  @override
  Future<List<StatementSummary>> statements() async {
    final rows = await _db.rpc('owner_statements') as List;
    return [
      for (final r in rows)
        StatementSummary.fromJson({
          ...(r as Map<String, dynamic>),
          'restaurant_id': '',
        }),
    ];
  }

  @override
  Future<StatementDetail> statementDetail(String id) async =>
      StatementDetail.fromJson(
        Map<String, dynamic>.from(
          await _db.rpc('owner_statement_detail', params: {'p_id': id}) as Map,
        ),
      );

  @override
  Future<List<CashToReceive>> cashPending() async {
    final rows = await _db.rpc('owner_cash_pending') as List;
    return [
      for (final r in rows) CashToReceive.fromJson(r as Map<String, dynamic>),
    ];
  }

  @override
  Future<void> confirmCash(String orderId) async {
    try {
      await _db.rpc('owner_confirm_cash', params: {'p_order_id': orderId});
    } on PostgrestException {
      throw const OwnerOrderError(OwnerOrderFailure.notAllowed);
    } catch (_) {
      throw const OwnerOrderError(OwnerOrderFailure.network);
    }
  }

  @override
  Stream<void> restaurantChanges(String restaurantId) {
    late final StreamController<void> ctrl;
    RealtimeChannel? channel;
    ctrl = StreamController<void>(
      onListen: () {
        channel = _db
            .channel('restaurant-orders-$restaurantId')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'orders',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'restaurant_id',
                value: restaurantId,
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

final ownerOrdersRepositoryProvider = Provider<OwnerOrdersRepository>((ref) {
  if (!Env.hasSupabase) {
    throw StateError('Supabase not configured (env.json)');
  }
  return SupabaseOwnerOrdersRepository(Supabase.instance.client);
});

final ownerActiveOrdersProvider = FutureProvider<List<OwnerOrder>>((ref) {
  ref.watch(currentUserIdProvider);
  return ref.watch(ownerOrdersRepositoryProvider).activeOrders();
});

final ownerHistoryProvider = FutureProvider<List<OwnerOrder>>((ref) {
  ref.watch(currentUserIdProvider);
  return ref.watch(ownerOrdersRepositoryProvider).history();
});

final ownerCashPendingProvider = FutureProvider<List<CashToReceive>>((ref) {
  ref.watch(currentUserIdProvider);
  return ref.watch(ownerOrdersRepositoryProvider).cashPending();
});

final ownerStatementsProvider = FutureProvider<List<StatementSummary>>((ref) {
  ref.watch(currentUserIdProvider);
  return ref.watch(ownerOrdersRepositoryProvider).statements();
});
