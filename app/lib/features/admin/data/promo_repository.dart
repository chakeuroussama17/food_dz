import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env.dart';
import '../../auth/data/auth_providers.dart';

/// A promo code as the admin sees it, with how often it was used.
class PromoCode {
  const PromoCode({
    required this.id,
    required this.code,
    required this.kind,
    required this.value,
    this.maxDiscount,
    this.minOrder = 0,
    this.maxUses,
    this.perCustomer,
    this.startsAt,
    this.endsAt,
    this.restaurantId,
    this.restaurantName,
    this.fundedBy = 'platform',
    this.isActive = true,
    this.note = '',
    this.uses = 0,
    this.discountGiven = 0,
  });

  final String id;
  final String code;

  /// 'percent' or 'amount'.
  final String kind;
  final int value;
  final int? maxDiscount;
  final int minOrder;
  final int? maxUses;
  final int? perCustomer;
  final DateTime? startsAt;
  final DateTime? endsAt;

  /// Null: every restaurant.
  final String? restaurantId;
  final String? restaurantName;

  /// 'platform' or 'restaurant'.
  final String fundedBy;
  final bool isActive;
  final String note;
  final int uses;
  final int discountGiven;

  bool get isPercent => kind == 'percent';
  bool get expired => endsAt != null && endsAt!.isBefore(DateTime.now());
  bool get usedUp => maxUses != null && uses >= maxUses!;

  static DateTime? _t(Object? v) =>
      v == null ? null : DateTime.parse(v as String).toLocal();

  factory PromoCode.fromJson(Map<String, dynamic> j) => PromoCode(
    id: j['id'] as String,
    code: j['code'] as String,
    kind: j['kind'] as String,
    value: (j['value'] as num).toInt(),
    maxDiscount: (j['max_discount'] as num?)?.toInt(),
    minOrder: (j['min_order'] as num?)?.toInt() ?? 0,
    maxUses: (j['max_uses'] as num?)?.toInt(),
    perCustomer: (j['per_customer'] as num?)?.toInt(),
    startsAt: _t(j['starts_at']),
    endsAt: _t(j['ends_at']),
    restaurantId: j['restaurant_id'] as String?,
    restaurantName: j['restaurant_name'] as String?,
    fundedBy: (j['funded_by'] as String?) ?? 'platform',
    isActive: (j['is_active'] as bool?) ?? true,
    note: (j['note'] as String?) ?? '',
    uses: (j['uses'] as num?)?.toInt() ?? 0,
    discountGiven: (j['discount_given'] as num?)?.toInt() ?? 0,
  );
}

/// What the admin form sends (id null = new code).
class PromoInput {
  const PromoInput({
    this.id,
    required this.code,
    required this.kind,
    required this.value,
    this.maxDiscount,
    this.minOrder = 0,
    this.maxUses,
    this.perCustomer,
    this.endsAt,
    this.restaurantId,
    this.fundedBy = 'platform',
    this.note = '',
  });
  final String? id;
  final String code;
  final String kind;
  final int value;
  final int? maxDiscount;
  final int minOrder;
  final int? maxUses;
  final int? perCustomer;
  final DateTime? endsAt;
  final String? restaurantId;
  final String fundedBy;
  final String note;
}

enum PromoFailure { invalidCode, codeTaken, invalidValue, network }

class PromoError implements Exception {
  const PromoError(this.failure);
  final PromoFailure failure;
}

abstract interface class PromoRepository {
  Future<List<PromoCode>> list();

  /// Throws [PromoError].
  Future<void> save(PromoInput input);
  Future<void> setActive(String id, bool active);
}

class SupabasePromoRepository implements PromoRepository {
  SupabasePromoRepository(this._db);
  final SupabaseClient _db;

  @override
  Future<List<PromoCode>> list() async {
    final rows = await _db.rpc('admin_promo_codes') as List;
    return [
      for (final r in rows) PromoCode.fromJson(r as Map<String, dynamic>),
    ];
  }

  @override
  Future<void> save(PromoInput i) async {
    try {
      await _db.rpc(
        'admin_save_promo_code',
        params: {
          'p_id': i.id,
          'p_code': i.code,
          'p_kind': i.kind,
          'p_value': i.value,
          'p_max_discount': i.maxDiscount,
          'p_min_order': i.minOrder,
          'p_max_uses': i.maxUses,
          'p_per_customer': i.perCustomer,
          'p_starts_at': null,
          'p_ends_at': i.endsAt?.toUtc().toIso8601String(),
          'p_restaurant_id': i.restaurantId,
          'p_funded_by': i.fundedBy,
          'p_note': i.note,
        },
      );
    } on PostgrestException catch (e) {
      final m = e.message;
      throw PromoError(
        m.contains('invalid_code')
            ? PromoFailure.invalidCode
            : m.contains('code_taken')
            ? PromoFailure.codeTaken
            : PromoFailure.invalidValue,
      );
    } catch (_) {
      throw const PromoError(PromoFailure.network);
    }
  }

  @override
  Future<void> setActive(String id, bool active) => _db.rpc(
    'admin_set_promo_active',
    params: {'p_id': id, 'p_active': active},
  );
}

final promoRepositoryProvider = Provider<PromoRepository>((ref) {
  if (!Env.hasSupabase) {
    throw StateError('Supabase not configured (env.json)');
  }
  return SupabasePromoRepository(Supabase.instance.client);
});

final promoCodesProvider = FutureProvider<List<PromoCode>>((ref) {
  ref.watch(currentUserIdProvider);
  return ref.watch(promoRepositoryProvider).list();
});
