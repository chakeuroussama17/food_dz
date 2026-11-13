import 'dart:async';

import 'package:food_app/features/admin/data/admin_models.dart';
import 'package:food_app/features/restaurant_owner/data/owner_live.dart';
import 'package:food_app/features/restaurant_owner/data/owner_orders_repository.dart';

/// Counts chimes instead of playing them.
class FakeAlertSound implements AlertSound {
  int plays = 0;
  @override
  Future<void> play() async => plays++;
}

/// In-memory restaurant orders with the same moves as
/// `owner_set_order_status`.
class FakeOwnerOrdersRepository implements OwnerOrdersRepository {
  final orders = <OwnerOrder>[];
  final calls = <String>[];
  final _changes = StreamController<void>.broadcast();
  var _n = 0;

  static const _allowed = {
    'placed': {'accepted', 'rejected'},
    'accepted': {'ready', 'cancelled'},
    'ready': {'cancelled'},
  };

  /// A customer places an order: arrives live, like Realtime INSERT.
  OwnerOrder addIncoming({
    String customer = 'Amina',
    String notes = '',
    DateTime? at,
  }) {
    _n++;
    final o = OwnerOrder(
      id: 'oo$_n',
      code: 'K7P2Q$_n',
      status: 'placed',
      customerName: customer,
      customerPhone: '0550123456',
      addressText: 'Rue Didouche 12',
      area: 'Alger Centre',
      notes: notes,
      foodTotal: 1400,
      deliveryFee: 200,
      total: 1600,
      placedAt: at ?? DateTime.now().subtract(const Duration(minutes: 3)),
      items: const [
        OrderLine(
          name: 'Pizza Margherita',
          unitPrice: 700,
          quantity: 2,
          lineTotal: 1400,
        ),
      ],
    );
    orders.add(o);
    _changes.add(null);
    return o;
  }

  /// The customer asks to cancel an accepted order.
  void customerAsksCancel(
    String id, {
    String reason = 'too_long',
    String note = '',
  }) {
    final o = orders.firstWhere((x) => x.id == id);
    _replace(
      id,
      o.status,
      request: 'pending',
      requestReason: reason,
      requestNote: note,
    );
    _changes.add(null);
  }

  /// The customer cancels from their side.
  void customerCancels(String id) {
    _replace(id, 'cancelled');
    _changes.add(null);
  }

  void _replace(
    String id,
    String status, {
    String? reason,
    String? request,
    String? cancelledBy,
    String? requestReason,
    String? requestNote,
  }) {
    final i = orders.indexWhere((o) => o.id == id);
    final o = orders[i];
    orders[i] = OwnerOrder(
      id: o.id,
      code: o.code,
      status: status,
      customerName: o.customerName,
      customerPhone: o.customerPhone,
      addressText: o.addressText,
      area: o.area,
      notes: o.notes,
      foodTotal: o.foodTotal,
      deliveryFee: o.deliveryFee,
      total: o.total,
      placedAt: o.placedAt,
      items: o.items,
      rejectReason: reason ?? o.rejectReason,
      cancelRequestStatus: request ?? o.cancelRequestStatus,
      cancelRequestReason: requestReason ?? o.cancelRequestReason,
      cancelRequestNote: requestNote ?? o.cancelRequestNote,
      cancelledBy: cancelledBy ?? o.cancelledBy,
    );
  }

  static bool _active(OwnerOrder o) =>
      const {'placed', 'accepted', 'ready', 'picked_up'}.contains(o.status);

  /// Past orders for the table / insights (on top of [orders]).
  final reportOrders = <OwnerOrder>[];
  final reportCalls = <(DateTime, DateTime)>[];

  /// Makes every report call fail (e.g. a broken database function).
  bool reportFails = false;

  @override
  Future<List<OwnerOrder>> report(
    DateTime from,
    DateTime to, {
    List<String>? restaurantIds,
  }) async {
    reportCalls.add((from, to));
    if (reportFails) throw Exception('PGRST203');
    return [...orders, ...reportOrders]
        .where((o) => _inAny(o, restaurantIds))
        .where((o) => !o.placedAt.isBefore(from) && o.placedAt.isBefore(to))
        .toList()
      ..sort((a, b) => b.placedAt.compareTo(a.placedAt));
  }

  /// Orders without an outlet belong to every outlet (single-outlet tests).
  static bool _inAny(OwnerOrder o, List<String>? ids) =>
      ids == null || o.restaurantId == null || ids.contains(o.restaurantId);

  static bool _in(OwnerOrder o, String? id) =>
      _inAny(o, id == null ? null : [id]);

  @override
  Future<List<OwnerOrder>> activeOrders({String? restaurantId}) async =>
      orders.where(_active).where((o) => _in(o, restaurantId)).toList();

  @override
  Future<List<OwnerOrder>> history({String? restaurantId}) async => orders
      .where((o) => !_active(o) && _in(o, restaurantId))
      .toList()
      .reversed
      .toList();

  @override
  Future<void> setStatus(
    String orderId,
    String status, {
    String? reason,
  }) async {
    calls.add('$orderId:$status:${reason ?? ''}');
    final o = orders.where((x) => x.id == orderId).firstOrNull;
    if (o == null) throw const OwnerOrderError(OwnerOrderFailure.notFound);
    if (!(_allowed[o.status]?.contains(status) ?? false)) {
      throw const OwnerOrderError(OwnerOrderFailure.notAllowed);
    }
    if ((status == 'rejected' || status == 'cancelled') &&
        (reason ?? '').trim().isEmpty) {
      throw const OwnerOrderError(OwnerOrderFailure.reasonRequired);
    }
    _replace(orderId, status, reason: reason);
    _changes.add(null);
  }

  @override
  Stream<void> restaurantChanges(String restaurantId) => _changes.stream;

  /// Delivered orders whose money the restaurant hasn't confirmed.
  final cash = <CashToReceive>[];

  @override
  Future<List<CashToReceive>> cashPending({String? restaurantId}) async => [
    ...cash,
  ];

  /// Commission statements issued by the admin.
  final statementList = <StatementSummary>[];

  @override
  Future<List<StatementSummary>> statements({String? restaurantId}) async => [
    ...statementList,
  ];

  @override
  Future<StatementDetail> statementDetail(String id) async {
    final s = statementList.firstWhere((x) => x.id == id);
    return StatementDetail(
      statement: s,
      restaurantName: s.restaurantName,
      restaurantAddress: 'Rue 1, Alger',
      restaurantPhone: '0550111222',
      ownerName: 'Omar',
      ownerEmail: 'o@mail.dz',
      business: const AdminConfig(
        deliveryFee: 200,
        defaultCommissionRate: 0.08,
        businessName: 'Food DZ',
      ),
      lines: [
        StatementLine(
          code: 'ABC123',
          deliveredAt: DateTime(2026, 11, 3, 13),
          foodTotal: s.foodTotal,
          commissionRate: 0.08,
          commissionAmount: s.commissionTotal,
        ),
      ],
    );
  }

  @override
  Future<void> answerCancelRequest(
    String orderId, {
    required bool accept,
  }) async {
    calls.add('cancelRequest:$orderId:$accept');
    final o = orders.firstWhere((x) => x.id == orderId);
    if (!o.cancelRequestPending) {
      throw const OwnerOrderError(OwnerOrderFailure.notAllowed);
    }
    if (accept) {
      _replace(
        orderId,
        'cancelled',
        request: 'accepted',
        cancelledBy: 'customer',
      );
    } else {
      _replace(orderId, o.status, request: 'refused');
    }
    _changes.add(null);
  }

  @override
  Future<void> confirmCash(String orderId) async {
    calls.add('cash:$orderId');
    cash.removeWhere((c) => c.orderId == orderId);
    _changes.add(null);
  }
}
