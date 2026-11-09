import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env.dart';
import 'admin_models.dart';

/// Inclusive date range (local Algiers dates).
class DateRange {
  const DateRange(this.start, this.end);
  final DateTime start;
  final DateTime end;

  @override
  bool operator ==(Object other) =>
      other is DateRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);
}

String sqlDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// Admin API. Every call is refused by the database unless the signed-in
/// account has the admin role.
abstract interface class AdminRepository {
  Future<List<AdminRestaurant>> restaurants();
  Future<void> setActive(String restaurantId, bool active);

  /// [rate] 0..0.5, or null to use the default.
  Future<void> setCommission(String restaurantId, double? rate);

  Future<AdminConfig> config();
  Future<void> updateConfig(AdminConfig c);

  Future<AdminStats> stats(DateRange r);
  Future<List<RestaurantStat>> statsByRestaurant(DateRange r);

  Future<List<AdminOrder>> orders(
    DateRange r, {
    String? restaurantId,
    String? status,
    int limit = 50,
    int offset = 0,
  });
  Future<List<AdminOrderItem>> orderItems(String orderId);

  Future<List<AdminCustomer>> customers({String search = ''});

  Future<StatementPreview> previewStatement(String restaurantId, DateRange r);
  Future<String> generateStatement(String restaurantId, DateRange r);
  Future<List<StatementSummary>> statements({String? restaurantId});
  Future<StatementDetail> statementDetail(String id);
  Future<void> setStatementPaid(String id, bool paid);
  Future<void> cancelStatement(String id);
}

class SupabaseAdminRepository implements AdminRepository {
  SupabaseAdminRepository(this._db);
  final SupabaseClient _db;

  Future<List<Map<String, dynamic>>> _rows(
    String fn, [
    Map<String, dynamic>? params,
  ]) async {
    final res = await _db.rpc(fn, params: params);
    return (res as List).cast<Map<String, dynamic>>();
  }

  @override
  Future<List<AdminRestaurant>> restaurants() async => (await _rows(
    'admin_list_restaurants',
  )).map(AdminRestaurant.fromJson).toList();

  @override
  Future<void> setActive(String id, bool active) => _db.rpc(
    'admin_set_restaurant_active',
    params: {'p_id': id, 'p_active': active},
  );

  @override
  Future<void> setCommission(String id, double? rate) =>
      _db.rpc('admin_set_commission', params: {'p_id': id, 'p_rate': rate});

  @override
  Future<AdminConfig> config() async => AdminConfig.fromJson(
    Map<String, dynamic>.from(await _db.rpc('admin_get_config') as Map),
  );

  @override
  Future<void> updateConfig(AdminConfig c) async {
    await _db.rpc(
      'admin_update_config',
      params: {
        'p_delivery_fee': c.deliveryFee,
        'p_default_commission_rate': c.defaultCommissionRate,
        'p_business_name': c.businessName,
        'p_business_phone': c.businessPhone,
        'p_business_email': c.businessEmail,
        'p_business_address': c.businessAddress,
        'p_business_tax_id': c.businessTaxId,
      },
    );
    await _db.rpc(
      'admin_set_cash_hours',
      params: {'p_hours': c.cashHandoverHours},
    );
    await _db.rpc(
      'admin_set_auto_reject_minutes',
      params: {'p_minutes': c.autoRejectMinutes},
    );
  }

  Map<String, dynamic> _range(DateRange r) => {
    'p_from': sqlDate(r.start),
    'p_to': sqlDate(r.end),
  };

  @override
  Future<AdminStats> stats(DateRange r) async => AdminStats.fromJson(
    Map<String, dynamic>.from(
      await _db.rpc('admin_stats', params: _range(r)) as Map,
    ),
  );

  @override
  Future<List<RestaurantStat>> statsByRestaurant(DateRange r) async =>
      (await _rows(
        'admin_stats_by_restaurant',
        _range(r),
      )).map(RestaurantStat.fromJson).toList();

  @override
  Future<List<AdminOrder>> orders(
    DateRange r, {
    String? restaurantId,
    String? status,
    int limit = 50,
    int offset = 0,
  }) async => (await _rows('admin_list_orders', {
    ..._range(r),
    'p_restaurant_id': restaurantId,
    'p_status': status,
    'p_limit': limit,
    'p_offset': offset,
  })).map(AdminOrder.fromJson).toList();

  @override
  Future<List<AdminOrderItem>> orderItems(String orderId) async => (await _rows(
    'admin_order_items',
    {'p_order_id': orderId},
  )).map(AdminOrderItem.fromJson).toList();

  @override
  Future<List<AdminCustomer>> customers({String search = ''}) async =>
      (await _rows('admin_list_customers', {
        'p_search': search,
      })).map(AdminCustomer.fromJson).toList();

  Map<String, dynamic> _stmt(String rid, DateRange r) => {
    'p_restaurant_id': rid,
    'p_start': sqlDate(r.start),
    'p_end': sqlDate(r.end),
  };

  @override
  Future<StatementPreview> previewStatement(String rid, DateRange r) async =>
      StatementPreview.fromJson(
        Map<String, dynamic>.from(
          await _db.rpc('admin_preview_statement', params: _stmt(rid, r))
              as Map,
        ),
      );

  @override
  Future<String> generateStatement(String rid, DateRange r) async =>
      await _db.rpc('admin_generate_statement', params: _stmt(rid, r))
          as String;

  @override
  Future<List<StatementSummary>> statements({String? restaurantId}) async =>
      (await _rows('admin_list_statements', {
        'p_restaurant_id': restaurantId,
      })).map(StatementSummary.fromJson).toList();

  @override
  Future<StatementDetail> statementDetail(String id) async =>
      StatementDetail.fromJson(
        Map<String, dynamic>.from(
          await _db.rpc('admin_statement_detail', params: {'p_id': id}) as Map,
        ),
      );

  @override
  Future<void> setStatementPaid(String id, bool paid) =>
      _db.rpc('admin_set_statement_paid', params: {'p_id': id, 'p_paid': paid});

  @override
  Future<void> cancelStatement(String id) =>
      _db.rpc('admin_cancel_statement', params: {'p_id': id});
}

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  if (!Env.hasSupabase) {
    throw StateError('Supabase not configured (env.json)');
  }
  return SupabaseAdminRepository(Supabase.instance.client);
});

final adminRestaurantsProvider = FutureProvider<List<AdminRestaurant>>(
  (ref) => ref.watch(adminRepositoryProvider).restaurants(),
);

final adminStatsProvider = FutureProvider.family<AdminStats, DateRange>(
  (ref, r) => ref.watch(adminRepositoryProvider).stats(r),
);

final adminStatsByRestaurantProvider =
    FutureProvider.family<List<RestaurantStat>, DateRange>(
      (ref, r) => ref.watch(adminRepositoryProvider).statsByRestaurant(r),
    );

final adminStatementsProvider = FutureProvider<List<StatementSummary>>(
  (ref) => ref.watch(adminRepositoryProvider).statements(),
);

final adminStatementDetailProvider =
    FutureProvider.family<StatementDetail, String>(
      (ref, id) => ref.watch(adminRepositoryProvider).statementDetail(id),
    );

final adminConfigProvider = FutureProvider<AdminConfig>(
  (ref) => ref.watch(adminRepositoryProvider).config(),
);
