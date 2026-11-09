import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env.dart';

class AdminDriver {
  const AdminDriver({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.vehicle,
    required this.isApproved,
    required this.isOnline,
    required this.createdAt,
    this.email = '',
    this.deliveredCount = 0,
    this.activeOrderCode,
    this.cashOwed = 0,
    this.cashOwedCount = 0,
    this.cashOldestAt,
    this.cashBlocked = false,
  });

  /// Food money delivered but not confirmed by restaurants.
  final int cashOwed;
  final int cashOwedCount;
  final DateTime? cashOldestAt;
  final bool cashBlocked;

  final String id;
  final String fullName;
  final String email;
  final String phone;

  /// moto / car / bike.
  final String vehicle;
  final bool isApproved;
  final bool isOnline;
  final DateTime createdAt;
  final int deliveredCount;
  final String? activeOrderCode;

  factory AdminDriver.fromJson(Map<String, dynamic> j) => AdminDriver(
    id: j['id'] as String,
    fullName: (j['full_name'] as String?) ?? '',
    email: (j['email'] as String?) ?? '',
    phone: j['phone'] as String,
    vehicle: j['vehicle'] as String,
    isApproved: j['is_approved'] as bool,
    isOnline: j['is_online'] as bool,
    createdAt: DateTime.parse(j['created_at'] as String).toLocal(),
    deliveredCount: (j['delivered_count'] as num?)?.toInt() ?? 0,
    activeOrderCode: j['active_order_code'] as String?,
    cashOwed: (j['cash_owed'] as num?)?.toInt() ?? 0,
    cashOwedCount: (j['cash_owed_count'] as num?)?.toInt() ?? 0,
    cashOldestAt: j['cash_oldest_at'] == null
        ? null
        : DateTime.parse(j['cash_oldest_at'] as String).toLocal(),
    cashBlocked: (j['cash_blocked'] as bool?) ?? false,
  );
}

/// Driver, delivery photo and cash state of one order (admin).
class AdminOrderDelivery {
  const AdminOrderDelivery({
    this.driverName,
    this.driverPhone,
    this.photoUrl,
    this.cashHandedAt,
    this.cashConfirmedAt,
  });
  final String? driverName;
  final String? driverPhone;

  /// Signed link, or null when there is no photo.
  final String? photoUrl;
  final DateTime? cashHandedAt;
  final DateTime? cashConfirmedAt;
}

abstract interface class AdminDriversRepository {
  Future<List<AdminDriver>> drivers();
  Future<void> setApproved(String driverId, bool approved);
  Future<AdminOrderDelivery> orderDelivery(String orderId);
}

class SupabaseAdminDriversRepository implements AdminDriversRepository {
  SupabaseAdminDriversRepository(this._db);
  final SupabaseClient _db;

  @override
  Future<List<AdminDriver>> drivers() async {
    final rows = await _db.rpc('admin_list_drivers') as List;
    return [
      for (final r in rows) AdminDriver.fromJson(r as Map<String, dynamic>),
    ];
  }

  @override
  Future<AdminOrderDelivery> orderDelivery(String orderId) async {
    final rows =
        await _db.rpc('admin_order_delivery', params: {'p_order_id': orderId})
            as List;
    if (rows.isEmpty) return const AdminOrderDelivery();
    final j = rows.first as Map<String, dynamic>;
    DateTime? ts(Object? v) =>
        v == null ? null : DateTime.parse(v as String).toLocal();
    final path = j['delivery_photo_path'] as String?;
    return AdminOrderDelivery(
      driverName: j['driver_name'] as String?,
      driverPhone: j['driver_phone'] as String?,
      photoUrl: path == null
          ? null
          : await _db.storage
                .from('delivery-proofs')
                .createSignedUrl(path, 600),
      cashHandedAt: ts(j['cash_handed_at']),
      cashConfirmedAt: ts(j['cash_confirmed_at']),
    );
  }

  @override
  Future<void> setApproved(String id, bool approved) => _db.rpc(
    'admin_set_driver_approved',
    params: {'p_id': id, 'p_approved': approved},
  );
}

final adminDriversRepositoryProvider = Provider<AdminDriversRepository>((ref) {
  if (!Env.hasSupabase) {
    throw StateError('Supabase not configured (env.json)');
  }
  return SupabaseAdminDriversRepository(Supabase.instance.client);
});

final adminDriversProvider = FutureProvider<List<AdminDriver>>(
  (ref) => ref.watch(adminDriversRepositoryProvider).drivers(),
);
