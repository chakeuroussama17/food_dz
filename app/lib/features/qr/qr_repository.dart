import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/env.dart';
import '../auth/data/auth_providers.dart';

/// Used until the admin sets the real address (and if it can't be read).
const kDefaultPublicBaseUrl = 'https://foodfennec.com';

/// The link a restaurant's QR code opens.
String restaurantQrLink(String baseUrl, String slug) =>
    '$baseUrl/r/$slug?src=qr';

/// The in-app page a scanned code leads to, or null when it isn't one of
/// ours. Accepts any host (the domain can change after printing) as long as
/// the path is a restaurant: `/r/<slug>`.
/// Later: promo codes ("scan and win") get their own path here.
String? appPathFromScan(String raw) {
  final uri = Uri.tryParse(raw.trim());
  if (uri == null) return null;
  if (uri.scheme != 'https' && uri.scheme != 'http') return null;
  final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
  if (segments.length == 2 &&
      segments[0] == 'r' &&
      RegExp(r'^[a-z0-9-]{3,40}$').hasMatch(segments[1].toLowerCase())) {
    return '/r/${segments[1].toLowerCase()}';
  }
  return null;
}

class QrStats {
  const QrStats({
    this.total = 0,
    this.last30 = 0,
    this.last7 = 0,
    this.app = 0,
    this.web = 0,
    this.people = 0,
    this.ordersAfter = 0,
  });
  final int total;
  final int last30;
  final int last7;
  final int app;
  final int web;
  final int people;
  final int ordersAfter;

  factory QrStats.fromJson(Map<String, dynamic> j) {
    int n(String k) => (j[k] as num?)?.toInt() ?? 0;
    return QrStats(
      total: n('scans_total'),
      last30: n('scans_30d'),
      last7: n('scans_7d'),
      app: n('app_scans'),
      web: n('web_scans'),
      people: n('people'),
      ordersAfter: n('orders_after'),
    );
  }
}

abstract interface class QrRepository {
  Future<String> publicBaseUrl();

  /// [source]: qr_app, qr_web or link. Never throws.
  Future<void> logVisit(String slug, String source);
  Future<QrStats> stats(String restaurantId);

  /// Admin only. Returns the saved address; throws on an invalid one.
  Future<String> setPublicBaseUrl(String url);
}

class SupabaseQrRepository implements QrRepository {
  SupabaseQrRepository(this._db);
  final SupabaseClient _db;

  @override
  Future<String> publicBaseUrl() async {
    try {
      final row = await _db
          .from('app_config')
          .select('public_base_url')
          .maybeSingle();
      return (row?['public_base_url'] as String?) ?? kDefaultPublicBaseUrl;
    } catch (_) {
      return kDefaultPublicBaseUrl;
    }
  }

  @override
  Future<void> logVisit(String slug, String source) async {
    try {
      await _db.rpc(
        'log_restaurant_visit',
        params: {'p_slug': slug, 'p_source': source},
      );
    } catch (_) {
      // Counting must never get in the way of opening the restaurant.
    }
  }

  @override
  Future<QrStats> stats(String restaurantId) async {
    final rows =
        await _db.rpc(
              'restaurant_qr_stats',
              params: {'p_restaurant_id': restaurantId},
            )
            as List;
    return rows.isEmpty
        ? const QrStats()
        : QrStats.fromJson(rows.first as Map<String, dynamic>);
  }

  @override
  Future<String> setPublicBaseUrl(String url) async =>
      await _db.rpc('admin_set_public_url', params: {'p_url': url}) as String;
}

final qrRepositoryProvider = Provider<QrRepository>((ref) {
  if (!Env.hasSupabase) {
    throw StateError('Supabase not configured (env.json)');
  }
  return SupabaseQrRepository(Supabase.instance.client);
});

final publicBaseUrlProvider = FutureProvider<String>(
  (ref) => ref.watch(qrRepositoryProvider).publicBaseUrl(),
);

final qrStatsProvider = FutureProvider.family<QrStats, String>((ref, id) {
  ref.watch(currentUserIdProvider);
  return ref.watch(qrRepositoryProvider).stats(id);
});
