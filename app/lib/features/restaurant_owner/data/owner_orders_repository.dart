import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env.dart';
import '../../admin/data/admin_models.dart'
    show StatementDetail, StatementSummary;
import '../../auth/data/auth_providers.dart';
import 'owner_repository.dart' show outletFilterProvider;
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
    this.commissionAmount,
    this.discountAmount = 0,
    this.taxAmount = 0,
    this.promoCode,
    this.discountFundedBy,
    this.cancelledBy,
    this.cancelReason,
    this.cancelRequestStatus,
    this.cancelRequestReason,
    this.cancelRequestNote = '',
    this.restaurantId,
    this.restaurantName = '',
    this.customerKey,
  });

  /// The platform's commission (set once delivered). Report rows only.
  /// Promo code reduction and tax (inside [total]). The rider hands the
  /// restaurant total − delivery fee.
  final int discountAmount;
  final int taxAmount;
  final String? promoCode;

  /// 'platform' or 'restaurant' (who pays the discount).
  final String? discountFundedBy;

  /// customer, restaurant, admin or system.
  final String? cancelledBy;
  final String? cancelReason;

  /// The customer asked to cancel after acceptance: pending (answer
  /// needed), accepted, refused, expired.
  final String? cancelRequestStatus;
  final String? cancelRequestReason;
  final String cancelRequestNote;
  bool get cancelRequestPending => cancelRequestStatus == 'pending';

  /// What the restaurant keeps from a delivered order: the food, minus the
  /// commission, minus the discount when the restaurant pays it (the tax is
  /// only passed on to the platform).
  int get net =>
      foodTotal -
      (commissionAmount ?? 0) -
      (discountFundedBy == 'restaurant' ? discountAmount : 0);

  final int? commissionAmount;

  /// The outlet (when the account has several).
  final String? restaurantId;
  final String restaurantName;

  /// Same value for the same customer (new vs returning). Report rows only.
  final String? customerKey;

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
    customerPhone: (j['customer_phone'] as String?) ?? '',
    addressText: (j['address_text'] as String?) ?? '',
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
    commissionAmount: (j['commission_amount'] as num?)?.toInt(),
    discountAmount: (j['discount_amount'] as num?)?.toInt() ?? 0,
    taxAmount: (j['tax_amount'] as num?)?.toInt() ?? 0,
    promoCode: j['promo_code'] as String?,
    discountFundedBy: j['discount_funded_by'] as String?,
    cancelledBy: j['cancelled_by'] as String?,
    cancelReason: j['cancel_reason'] as String?,
    cancelRequestStatus: j['cancel_request_status'] as String?,
    cancelRequestReason: j['cancel_request_reason'] as String?,
    cancelRequestNote: (j['cancel_request_note'] as String?) ?? '',
    restaurantId: j['restaurant_id'] as String?,
    restaurantName: (j['restaurant_name'] as String?) ?? '',
    customerKey: j['customer_key'] as String?,
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
    this.restaurantName = '',
  });

  final String restaurantName;
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
    restaurantName: (j['restaurant_name'] as String?) ?? '',
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
  /// Orders in progress, oldest first. [restaurantId] null = all outlets.
  Future<List<OwnerOrder>> activeOrders({String? restaurantId});

  /// Finished orders (delivered, rejected, cancelled), newest first.
  Future<List<OwnerOrder>> history({String? restaurantId});

  /// Every order placed in [from, to) (max ~13 months), newest first:
  /// the orders table, the CSV export and the trends.
  /// [restaurantIds] null = all the account's outlets.
  Future<List<OwnerOrder>> report(
    DateTime from,
    DateTime to, {
    List<String>? restaurantIds,
  });

  /// accepted / rejected / ready / cancelled. Throws [OwnerOrderError].
  Future<void> setStatus(String orderId, String status, {String? reason});

  /// Fires on every new or changed order of the restaurant (Realtime).
  Stream<void> restaurantChanges(String restaurantId);

  /// Delivered orders whose food money isn't confirmed yet.
  Future<List<CashToReceive>> cashPending({String? restaurantId});

  /// "Money received". Throws [OwnerOrderError].
  Future<void> confirmCash(String orderId);

  /// The customer's cancellation request: accept (order cancelled) or
  /// refuse (it goes on).
  Future<void> answerCancelRequest(String orderId, {required bool accept});

  /// Commission statements the admin issued to this restaurant.
  Future<List<StatementSummary>> statements({String? restaurantId});
  Future<StatementDetail> statementDetail(String id);
}

class SupabaseOwnerOrdersRepository implements OwnerOrdersRepository {
  SupabaseOwnerOrdersRepository(this._db);
  final SupabaseClient _db;

  Future<List<OwnerOrder>> _list(bool active, String? restaurantId) async {
    final rows = await _db.rpc(
      'owner_orders',
      params: {
        'p_active': active,
        // Only sent when needed: works before the outlets SQL too.
        'p_restaurant_id': ?restaurantId,
      },
    );
    return [
      for (final r in rows as List)
        OwnerOrder.fromJson(r as Map<String, dynamic>),
    ];
  }

  @override
  Future<List<OwnerOrder>> activeOrders({String? restaurantId}) =>
      _list(true, restaurantId);

  @override
  Future<List<OwnerOrder>> history({String? restaurantId}) =>
      _list(false, restaurantId);

  @override
  Future<List<OwnerOrder>> report(
    DateTime from,
    DateTime to, {
    List<String>? restaurantIds,
  }) async {
    final rows = await _db.rpc(
      'owner_report',
      params: {
        'p_from': from.toUtc().toIso8601String(),
        'p_to': to.toUtc().toIso8601String(),
        'p_restaurant_ids': ?restaurantIds,
      },
    );
    return [
      for (final r in rows as List)
        OwnerOrder.fromJson(r as Map<String, dynamic>),
    ];
  }

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
  Future<List<StatementSummary>> statements({String? restaurantId}) async {
    final rows =
        await _db.rpc(
              'owner_statements',
              params: {'p_restaurant_id': ?restaurantId},
            )
            as List;
    return [
      for (final r in rows)
        StatementSummary.fromJson({
          'restaurant_id': '',
          ...(r as Map<String, dynamic>),
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
  Future<List<CashToReceive>> cashPending({String? restaurantId}) async {
    final rows =
        await _db.rpc(
              'owner_cash_pending',
              params: {'p_restaurant_id': ?restaurantId},
            )
            as List;
    return [
      for (final r in rows) CashToReceive.fromJson(r as Map<String, dynamic>),
    ];
  }

  @override
  Future<void> answerCancelRequest(
    String orderId, {
    required bool accept,
  }) async {
    try {
      await _db.rpc(
        'owner_answer_cancel_request',
        params: {'p_order_id': orderId, 'p_accept': accept},
      );
    } on PostgrestException {
      throw const OwnerOrderError(OwnerOrderFailure.notAllowed);
    } catch (_) {
      throw const OwnerOrderError(OwnerOrderFailure.network);
    }
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

// The app's lists follow the outlet shown in the header.
final ownerActiveOrdersProvider = FutureProvider<List<OwnerOrder>>((ref) async {
  ref.watch(currentUserIdProvider);
  final outlet = await ref.watch(outletFilterProvider.future);
  return ref
      .watch(ownerOrdersRepositoryProvider)
      .activeOrders(restaurantId: outlet);
});

final ownerHistoryProvider = FutureProvider<List<OwnerOrder>>((ref) async {
  ref.watch(currentUserIdProvider);
  final outlet = await ref.watch(outletFilterProvider.future);
  return ref.watch(ownerOrdersRepositoryProvider).history(restaurantId: outlet);
});

final ownerCashPendingProvider = FutureProvider<List<CashToReceive>>((
  ref,
) async {
  ref.watch(currentUserIdProvider);
  final outlet = await ref.watch(outletFilterProvider.future);
  return ref
      .watch(ownerOrdersRepositoryProvider)
      .cashPending(restaurantId: outlet);
});

final ownerStatementsProvider = FutureProvider<List<StatementSummary>>((
  ref,
) async {
  ref.watch(currentUserIdProvider);
  final outlet = await ref.watch(outletFilterProvider.future);
  return ref
      .watch(ownerOrdersRepositoryProvider)
      .statements(restaurantId: outlet);
});

/// A period of the report: [from, to), local days. [outlets] null = the
/// outlet shown in the app; the portal passes its selection.
class ReportRange {
  const ReportRange(this.from, this.to, {this.outlets});
  final DateTime from;
  final DateTime to;
  final List<String>? outlets;

  String get _outletKey =>
      outlets == null ? '-' : ([...outlets!]..sort()).join(',');

  @override
  bool operator ==(Object other) =>
      other is ReportRange &&
      other.from == from &&
      other.to == to &&
      other._outletKey == _outletKey;

  @override
  int get hashCode => Object.hash(from, to, _outletKey);
}

final ownerReportProvider =
    FutureProvider.family<List<OwnerOrder>, ReportRange>(
      (ref, r) async {
        ref.watch(currentUserIdProvider);
        final ids =
            r.outlets ??
            switch (await ref.watch(outletFilterProvider.future)) {
              final String id => [id],
              null => null,
            };
        return ref
            .watch(ownerOrdersRepositoryProvider)
            .report(r.from, r.to, restaurantIds: ids);
      },
      // Show the error (with a retry button) instead of retrying silently
      // behind a spinner.
      retry: (_, _) => null,
    );

/// Bumped after the restaurant changes an order, so every screen that
/// lists orders (app and portal) reloads.
class OrderChanges extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final orderChangesProvider = NotifierProvider<OrderChanges, int>(
  OrderChanges.new,
);
