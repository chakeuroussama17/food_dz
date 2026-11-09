import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env.dart';
import '../../../core/utils/pick_image.dart';
import '../../auth/data/auth_providers.dart';
import '../../orders/data/orders_repository.dart' show OrderLine;

export '../../orders/data/orders_repository.dart' show OrderLine;

enum Vehicle { moto, car, bike }

class DriverProfile {
  const DriverProfile({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.vehicle,
    required this.isApproved,
    required this.isOnline,
    this.cashOwed = 0,
    this.cashBlocked = false,
  });

  final String id;
  final String fullName;
  final String phone;
  final Vehicle vehicle;
  final bool isApproved;
  final bool isOnline;

  /// Food money delivered but not yet confirmed by the restaurants.
  final int cashOwed;

  /// Money unconfirmed for too long: can't take new orders.
  final bool cashBlocked;

  factory DriverProfile.fromJson(Map<String, dynamic> j) => DriverProfile(
    id: j['id'] as String,
    fullName: (j['full_name'] as String?) ?? '',
    phone: j['phone'] as String,
    vehicle: Vehicle.values.byName(j['vehicle'] as String),
    isApproved: j['is_approved'] as bool,
    isOnline: j['is_online'] as bool,
    cashOwed: (j['cash_owed'] as num?)?.toInt() ?? 0,
    cashBlocked: (j['cash_blocked'] as bool?) ?? false,
  );
}

/// Food money a driver still has to give to a restaurant.
class CashDue {
  const CashDue({
    required this.orderId,
    required this.code,
    required this.restaurantName,
    required this.amount,
    required this.deliveredAt,
    this.restaurantPhone = '',
    this.handedAt,
    this.overdue = false,
  });

  final String orderId;
  final String code;
  final String restaurantName;
  final String restaurantPhone;
  final int amount;
  final DateTime deliveredAt;

  /// The driver tapped "I gave the money"; waiting for the restaurant.
  final DateTime? handedAt;
  final bool overdue;

  factory CashDue.fromJson(Map<String, dynamic> j) => CashDue(
    orderId: j['id'] as String,
    code: j['code'] as String,
    restaurantName: j['restaurant_name'] as String,
    restaurantPhone: (j['restaurant_phone'] as String?) ?? '',
    amount: (j['food_total'] as num).toInt(),
    deliveredAt: DateTime.parse(j['delivered_at'] as String).toLocal(),
    handedAt: j['cash_handed_at'] == null
        ? null
        : DateTime.parse(j['cash_handed_at'] as String).toLocal(),
    overdue: (j['overdue'] as bool?) ?? false,
  );
}

DateTime? _ts(Object? v) =>
    v == null ? null : DateTime.parse(v as String).toLocal();
double? _d(Object? v) => (v as num?)?.toDouble();

/// An order waiting for a driver (`driver_available_orders`): no customer
/// name, phone or exact address until the driver takes it.
class AvailableOrder {
  const AvailableOrder({
    required this.id,
    required this.code,
    required this.status,
    required this.restaurantName,
    required this.restaurantAddress,
    required this.deliveryFee,
    required this.total,
    required this.itemCount,
    required this.placedAt,
    this.restaurantArea = '',
    this.restaurantLat,
    this.restaurantLng,
    this.area = '',
    this.lat,
    this.lng,
  });

  final String id;
  final String code;
  final String status;
  final String restaurantName;
  final String restaurantAddress;
  final String restaurantArea;
  final double? restaurantLat;
  final double? restaurantLng;
  final String area;
  final double? lat;
  final double? lng;
  final int deliveryFee;
  final int total;
  final int itemCount;
  final DateTime placedAt;

  bool get isReady => status == 'ready';

  factory AvailableOrder.fromJson(Map<String, dynamic> j) => AvailableOrder(
    id: j['id'] as String,
    code: j['code'] as String,
    status: j['status'] as String,
    restaurantName: j['restaurant_name'] as String,
    restaurantAddress: (j['restaurant_address'] as String?) ?? '',
    restaurantArea: (j['restaurant_area'] as String?) ?? '',
    restaurantLat: _d(j['restaurant_lat']),
    restaurantLng: _d(j['restaurant_lng']),
    area: (j['area'] as String?) ?? '',
    lat: _d(j['lat']),
    lng: _d(j['lng']),
    deliveryFee: (j['delivery_fee'] as num).toInt(),
    total: (j['total'] as num).toInt(),
    itemCount: (j['item_count'] as num).toInt(),
    placedAt: _ts(j['placed_at'])!,
  );
}

/// An order taken by this driver, with everything needed to deliver it.
class DriverOrder {
  const DriverOrder({
    required this.id,
    required this.code,
    required this.status,
    required this.restaurantName,
    required this.restaurantAddress,
    required this.customerName,
    required this.customerPhone,
    required this.addressText,
    required this.foodTotal,
    required this.deliveryFee,
    required this.total,
    required this.placedAt,
    required this.items,
    this.restaurantArea = '',
    this.restaurantPhone = '',
    this.restaurantLat,
    this.restaurantLng,
    this.area = '',
    this.addressDetails = '',
    this.lat,
    this.lng,
    this.notes = '',
    this.rejectReason,
    this.readyAt,
    this.pickedUpAt,
    this.deliveredAt,
  });

  final String id;
  final String code;
  final String status;
  final String restaurantName;
  final String restaurantAddress;
  final String restaurantArea;
  final String restaurantPhone;
  final double? restaurantLat;
  final double? restaurantLng;
  final String customerName;
  final String customerPhone;
  final String addressText;
  final String area;
  final String addressDetails;
  final double? lat;
  final double? lng;
  final String notes;
  final int foodTotal;
  final int deliveryFee;
  final int total;
  final String? rejectReason;
  final DateTime placedAt;
  final DateTime? readyAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;
  final List<OrderLine> items;

  bool get isActive =>
      status == 'accepted' || status == 'ready' || status == 'picked_up';

  /// Before pickup the driver may give the order back.
  bool get canRelease => status == 'accepted' || status == 'ready';

  factory DriverOrder.fromJson(Map<String, dynamic> j) => DriverOrder(
    id: j['id'] as String,
    code: j['code'] as String,
    status: j['status'] as String,
    restaurantName: j['restaurant_name'] as String,
    restaurantAddress: (j['restaurant_address'] as String?) ?? '',
    restaurantArea: (j['restaurant_area'] as String?) ?? '',
    restaurantPhone: (j['restaurant_phone'] as String?) ?? '',
    restaurantLat: _d(j['restaurant_lat']),
    restaurantLng: _d(j['restaurant_lng']),
    customerName: j['customer_name'] as String,
    customerPhone: j['customer_phone'] as String,
    addressText: j['address_text'] as String,
    area: (j['area'] as String?) ?? '',
    addressDetails: (j['address_details'] as String?) ?? '',
    lat: _d(j['lat']),
    lng: _d(j['lng']),
    notes: (j['notes'] as String?) ?? '',
    foodTotal: (j['food_total'] as num).toInt(),
    deliveryFee: (j['delivery_fee'] as num).toInt(),
    total: (j['total'] as num).toInt(),
    rejectReason: j['reject_reason'] as String?,
    placedAt: _ts(j['placed_at'])!,
    readyAt: _ts(j['ready_at']),
    pickedUpAt: _ts(j['picked_up_at']),
    deliveredAt: _ts(j['delivered_at']),
    items: [
      for (final i in (j['items'] as List? ?? const []))
        OrderLine.fromJson(i as Map<String, dynamic>),
    ],
  );
}

/// One delivered order on a driver statement.
class StatementDelivery {
  const StatementDelivery({
    required this.code,
    required this.deliveredAt,
    required this.restaurantName,
    required this.total,
    required this.foodTotal,
    required this.deliveryFee,
    this.cashConfirmed = false,
  });

  final String code;
  final DateTime deliveredAt;
  final String restaurantName;

  /// Cash collected from the customer.
  final int total;

  /// Owed to the restaurant.
  final int foodTotal;

  /// Kept by the driver.
  final int deliveryFee;

  /// The restaurant confirmed it received [foodTotal].
  final bool cashConfirmed;

  factory StatementDelivery.fromJson(Map<String, dynamic> j) =>
      StatementDelivery(
        code: j['code'] as String,
        deliveredAt: DateTime.parse(j['delivered_at'] as String).toLocal(),
        restaurantName: j['restaurant_name'] as String,
        total: (j['total'] as num).toInt(),
        foodTotal: (j['food_total'] as num).toInt(),
        deliveryFee: (j['delivery_fee'] as num).toInt(),
        cashConfirmed: j['cash_confirmed_at'] != null,
      );
}

enum DriverFailure {
  alreadyTaken,
  cashOverdue,
  photoRequired,
  busy,
  notOnline,
  notApproved,
  notAllowed,
  invalidPhone,
  accountHasRole,
  network,
  unknown,
}

class DriverError implements Exception {
  const DriverError(this.failure);
  final DriverFailure failure;
  @override
  String toString() => 'DriverError($failure)';
}

DriverFailure driverFailureFromMessage(String m) {
  for (final (key, f) in const [
    ('already_taken', DriverFailure.alreadyTaken),
    ('cash_overdue', DriverFailure.cashOverdue),
    ('photo_required', DriverFailure.photoRequired),
    ('busy', DriverFailure.busy),
    ('not_online', DriverFailure.notOnline),
    ('not_approved', DriverFailure.notApproved),
    ('not_allowed', DriverFailure.notAllowed),
    ('order_not_found', DriverFailure.notAllowed),
    ('invalid_phone', DriverFailure.invalidPhone),
    ('account_has_role', DriverFailure.accountHasRole),
  ]) {
    if (m.contains(key)) return f;
  }
  return DriverFailure.unknown;
}

abstract interface class DriverRepository {
  /// Null when the account isn't a driver.
  Future<DriverProfile?> me();

  /// Turns the signed-in customer account into a driver (not approved).
  Future<void> register({required String phone, required Vehicle vehicle});
  Future<void> setOnline(bool online);
  Future<List<AvailableOrder>> available();
  Future<void> claim(String orderId);
  Future<void> release(String orderId);

  /// picked_up.
  Future<void> setStatus(String orderId, String status);

  /// Uploads the proof photo, then marks the order delivered.
  Future<void> completeDelivery(String orderId, PickedImage photo);

  /// Delivered orders between [from] and [to] (Algiers dates, inclusive).
  Future<List<StatementDelivery>> statement(DateTime from, DateTime to);

  /// Food money still to give to restaurants (oldest first).
  Future<List<CashDue>> cashPending();
  Future<void> markCashHanded(String orderId);
  Future<List<DriverOrder>> myOrders({required bool active});

  /// Fires when one of this driver's orders changes (Realtime).
  Stream<void> myOrderChanges(String driverId);
}

class SupabaseDriverRepository implements DriverRepository {
  SupabaseDriverRepository(this._db);
  final SupabaseClient _db;

  Future<T> _guard<T>(Future<T> Function() f) async {
    try {
      return await f();
    } on PostgrestException catch (e) {
      throw DriverError(driverFailureFromMessage(e.message));
    } on DriverError {
      rethrow;
    } on StorageException catch (e) {
      // Upload refused (order no longer on its way) vs. no connection.
      final code = int.tryParse(e.statusCode ?? '') ?? 0;
      throw DriverError(
        code >= 400 && code < 500
            ? DriverFailure.notAllowed
            : DriverFailure.network,
      );
    } catch (_) {
      throw const DriverError(DriverFailure.network);
    }
  }

  @override
  Future<DriverProfile?> me() async {
    final rows = await _db.rpc('my_driver') as List;
    return rows.isEmpty
        ? null
        : DriverProfile.fromJson(rows.first as Map<String, dynamic>);
  }

  @override
  Future<void> register({required String phone, required Vehicle vehicle}) =>
      _guard(
        () => _db.rpc(
          'register_driver',
          params: {'p_phone': phone, 'p_vehicle': vehicle.name},
        ),
      );

  @override
  Future<void> setOnline(bool online) =>
      _guard(() => _db.rpc('driver_set_online', params: {'p_online': online}));

  @override
  Future<List<AvailableOrder>> available() async {
    final rows = await _db.rpc('driver_available_orders') as List;
    return [
      for (final r in rows) AvailableOrder.fromJson(r as Map<String, dynamic>),
    ];
  }

  @override
  Future<void> claim(String orderId) => _guard(
    () => _db.rpc('driver_claim_order', params: {'p_order_id': orderId}),
  );

  @override
  Future<void> release(String orderId) => _guard(
    () => _db.rpc('driver_release_order', params: {'p_order_id': orderId}),
  );

  @override
  Future<void> setStatus(String orderId, String status) => _guard(
    () => _db.rpc(
      'driver_set_order_status',
      params: {'p_order_id': orderId, 'p_status': status},
    ),
  );

  @override
  Future<void> completeDelivery(String orderId, PickedImage photo) =>
      _guard(() async {
        final ext = photo.extension;
        final path = '$orderId/${DateTime.now().millisecondsSinceEpoch}.$ext';
        await _db.storage
            .from('delivery-proofs')
            .uploadBinary(
              path,
              Uint8List.fromList(photo.bytes),
              fileOptions: FileOptions(
                contentType: ext == 'png'
                    ? 'image/png'
                    : ext == 'webp'
                    ? 'image/webp'
                    : 'image/jpeg',
              ),
            );
        await _db.rpc(
          'driver_complete_delivery',
          params: {'p_order_id': orderId, 'p_photo_path': path},
        );
      });

  @override
  Future<List<StatementDelivery>> statement(DateTime from, DateTime to) async {
    String d(DateTime x) =>
        '${x.year}-${x.month.toString().padLeft(2, '0')}-${x.day.toString().padLeft(2, '0')}';
    final rows =
        await _db.rpc(
              'driver_statement',
              params: {'p_from': d(from), 'p_to': d(to)},
            )
            as List;
    return [
      for (final r in rows)
        StatementDelivery.fromJson(r as Map<String, dynamic>),
    ];
  }

  @override
  Future<List<CashDue>> cashPending() async {
    final rows = await _db.rpc('driver_cash_pending') as List;
    return [for (final r in rows) CashDue.fromJson(r as Map<String, dynamic>)];
  }

  @override
  Future<void> markCashHanded(String orderId) => _guard(
    () => _db.rpc('driver_mark_cash_handed', params: {'p_order_id': orderId}),
  );

  @override
  Future<List<DriverOrder>> myOrders({required bool active}) async {
    final rows =
        await _db.rpc('driver_orders', params: {'p_active': active}) as List;
    return [
      for (final r in rows) DriverOrder.fromJson(r as Map<String, dynamic>),
    ];
  }

  @override
  Stream<void> myOrderChanges(String driverId) {
    late final StreamController<void> ctrl;
    RealtimeChannel? channel;
    ctrl = StreamController<void>(
      onListen: () {
        channel = _db
            .channel('driver-orders-$driverId')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'orders',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'driver_id',
                value: driverId,
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

final driverRepositoryProvider = Provider<DriverRepository>((ref) {
  if (!Env.hasSupabase) {
    throw StateError('Supabase not configured (env.json)');
  }
  return SupabaseDriverRepository(Supabase.instance.client);
});

final myDriverProvider = FutureProvider<DriverProfile?>((ref) {
  ref.watch(currentUserIdProvider);
  return ref.watch(driverRepositoryProvider).me();
});

final availableOrdersProvider = FutureProvider<List<AvailableOrder>>((ref) {
  ref.watch(currentUserIdProvider);
  return ref.watch(driverRepositoryProvider).available();
});

final driverActiveOrdersProvider = FutureProvider<List<DriverOrder>>((ref) {
  ref.watch(currentUserIdProvider);
  return ref.watch(driverRepositoryProvider).myOrders(active: true);
});

final driverHistoryProvider = FutureProvider<List<DriverOrder>>((ref) {
  ref.watch(currentUserIdProvider);
  return ref.watch(driverRepositoryProvider).myOrders(active: false);
});

final driverCashPendingProvider = FutureProvider<List<CashDue>>((ref) {
  ref.watch(currentUserIdProvider);
  return ref.watch(driverRepositoryProvider).cashPending();
});

/// Opens the camera (or the gallery) for the delivery photo. Overridden in
/// tests.
final takeProofPhotoProvider =
    Provider<Future<PickedImage?> Function({required bool camera})>(
      (ref) =>
          ({required bool camera}) => pickImage(
            camera: camera,
            maxSide: 1280,
            maxBytes: 5 * 1024 * 1024,
          ),
    );
