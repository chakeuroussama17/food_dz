import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/env.dart';
import '../auth/data/auth_providers.dart';

/// Why someone is sanctioned (user_sanctions.reason).
const sanctionReasons = [
  'fake_orders',
  'no_show',
  'refused_to_pay',
  'abuse',
  'fraud',
  'too_many_cancellations',
  'unsafe_driving',
  'cash_not_returned',
  'other',
];

/// A warning (shown once), a suspension (until [endsAt]) or a ban.
class Sanction {
  const Sanction({
    required this.id,
    required this.kind,
    required this.reason,
    this.message = '',
    this.adminNote = '',
    this.endsAt,
    this.createdAt,
    this.liftedAt,
    this.seenAt,
    this.createdByName = '',
    this.active = false,
  });

  final int id;

  /// warning, suspension, ban.
  final String kind;
  final String reason;

  /// Shown to the person.
  final String message;

  /// Admin only.
  final String adminNote;
  final DateTime? endsAt;
  final DateTime? createdAt;
  final DateTime? liftedAt;
  final DateTime? seenAt;
  final String createdByName;
  final bool active;

  bool get isWarning => kind == 'warning';
  bool get isBan => kind == 'ban';

  static DateTime? _t(Object? v) =>
      v == null ? null : DateTime.parse(v as String).toLocal();

  factory Sanction.fromJson(Map<String, dynamic> j) => Sanction(
    id: (j['id'] as num).toInt(),
    kind: j['kind'] as String,
    reason: j['reason'] as String,
    message: (j['message'] as String?) ?? '',
    adminNote: (j['admin_note'] as String?) ?? '',
    endsAt: _t(j['ends_at']),
    createdAt: _t(j['created_at']),
    liftedAt: _t(j['lifted_at']),
    seenAt: _t(j['seen_at']),
    createdByName: (j['created_by_name'] as String?) ?? '',
    active: (j['active'] as bool?) ?? false,
  );
}

/// A customer who cancelled 3 times or more in 30 days.
class WatchlistEntry {
  const WatchlistEntry({
    required this.userId,
    required this.fullName,
    required this.email,
    this.phone,
    this.cancels30d = 0,
    this.openReports = 0,
    this.lastCancelAt,
    this.restricted = false,
  });
  final String userId;
  final String fullName;
  final String email;
  final String? phone;
  final int cancels30d;
  final int openReports;
  final DateTime? lastCancelAt;
  final bool restricted;

  factory WatchlistEntry.fromJson(Map<String, dynamic> j) => WatchlistEntry(
    userId: j['user_id'] as String,
    fullName: (j['full_name'] as String?) ?? '',
    email: (j['email'] as String?) ?? '',
    phone: j['phone'] as String?,
    cancels30d: (j['cancels_30d'] as num?)?.toInt() ?? 0,
    openReports: (j['open_reports'] as num?)?.toInt() ?? 0,
    lastCancelAt: j['last_cancel_at'] == null
        ? null
        : DateTime.parse(j['last_cancel_at'] as String).toLocal(),
    restricted: (j['restricted'] as bool?) ?? false,
  );
}

enum SanctionFailure { invalid, notFound, network }

class SanctionError implements Exception {
  const SanctionError(this.failure);
  final SanctionFailure failure;
}

abstract interface class SanctionsRepository {
  /// The suspension / ban in force, else a warning not yet seen.
  Future<Sanction?> mine();
  Future<void> acknowledge(int id);

  // Admin.
  Future<int> sanction({
    required String userId,
    required String kind,
    required String reason,
    String message = '',
    int? days,
    String adminNote = '',
  });
  Future<void> lift(int id);
  Future<List<Sanction>> history(String userId);
  Future<List<WatchlistEntry>> watchlist();

  /// user id → 'suspension' | 'ban' (in force now).
  Future<Map<String, String>> restrictions();
}

class SupabaseSanctionsRepository implements SanctionsRepository {
  SupabaseSanctionsRepository(this._db);
  final SupabaseClient _db;

  Future<T> _guard<T>(Future<T> Function() f) async {
    try {
      return await f();
    } on PostgrestException catch (e) {
      throw SanctionError(
        e.message.contains('not_found')
            ? SanctionFailure.notFound
            : SanctionFailure.invalid,
      );
    } catch (e) {
      if (e is SanctionError) rethrow;
      throw const SanctionError(SanctionFailure.network);
    }
  }

  @override
  Future<Sanction?> mine() async {
    try {
      final rows = await _db.rpc('my_restriction') as List;
      return rows.isEmpty
          ? null
          : Sanction.fromJson(rows.first as Map<String, dynamic>);
    } catch (_) {
      // Before the SQL is applied, or offline: never lock anyone out.
      return null;
    }
  }

  @override
  Future<void> acknowledge(int id) async {
    try {
      await _db.rpc('acknowledge_warning', params: {'p_id': id});
    } catch (_) {}
  }

  @override
  Future<int> sanction({
    required String userId,
    required String kind,
    required String reason,
    String message = '',
    int? days,
    String adminNote = '',
  }) => _guard(() async {
    final id = await _db.rpc(
      'admin_sanction_user',
      params: {
        'p_user_id': userId,
        'p_kind': kind,
        'p_reason': reason,
        'p_message': message,
        'p_days': days,
        'p_admin_note': adminNote,
      },
    );
    return (id as num).toInt();
  });

  @override
  Future<void> lift(int id) =>
      _guard(() => _db.rpc('admin_lift_sanction', params: {'p_id': id}));

  @override
  Future<List<Sanction>> history(String userId) => _guard(() async {
    final rows =
        await _db.rpc('admin_user_sanctions', params: {'p_user_id': userId})
            as List;
    return [for (final r in rows) Sanction.fromJson(r as Map<String, dynamic>)];
  });

  @override
  Future<List<WatchlistEntry>> watchlist() => _guard(() async {
    final rows = await _db.rpc('admin_watchlist') as List;
    return [
      for (final r in rows) WatchlistEntry.fromJson(r as Map<String, dynamic>),
    ];
  });

  @override
  Future<Map<String, String>> restrictions() => _guard(() async {
    final rows = await _db.rpc('admin_restrictions') as List;
    return {
      for (final r in rows.cast<Map<String, dynamic>>())
        r['user_id'] as String: r['kind'] as String,
    };
  });
}

final sanctionsRepositoryProvider = Provider<SanctionsRepository>((ref) {
  if (!Env.hasSupabase) {
    throw StateError('Supabase not configured (env.json)');
  }
  return SupabaseSanctionsRepository(Supabase.instance.client);
});

/// The signed-in person's suspension / ban / unseen warning.
final myRestrictionProvider = FutureProvider<Sanction?>((ref) async {
  final uid = ref.watch(currentUserIdProvider).value;
  if (uid == null) return null;
  return ref.watch(sanctionsRepositoryProvider).mine();
});

final watchlistProvider = FutureProvider<List<WatchlistEntry>>((ref) {
  ref.watch(currentUserIdProvider);
  return ref.watch(sanctionsRepositoryProvider).watchlist();
});

final restrictionsProvider = FutureProvider<Map<String, String>>((ref) {
  ref.watch(currentUserIdProvider);
  return ref.watch(sanctionsRepositoryProvider).restrictions();
});

final sanctionHistoryProvider = FutureProvider.family<List<Sanction>, String>(
  (ref, userId) => ref.watch(sanctionsRepositoryProvider).history(userId),
);
