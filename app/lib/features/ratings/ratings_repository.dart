import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/env.dart';
import '../auth/data/auth_providers.dart';
import 'ratings_models.dart';

export 'ratings_models.dart';

enum RatingFailure {
  windowClosed,
  locked,
  notDelivered,
  noDriver,
  alreadyReplied,
  alreadyFlagged,
  alreadyReported,
  tooManyReports,
  customerGone,
  notFound,
  invalid,
  network,
}

class RatingError implements Exception {
  const RatingError(this.failure);
  final RatingFailure failure;
  @override
  String toString() => 'RatingError($failure)';
}

/// Ratings, reviews, replies, flags and reports about customers (every
/// role goes through this one repository).
abstract interface class RatingsRepository {
  // ---- customer
  /// My delivered orders with what I rated (last 30 days, or one order).
  Future<List<OrderRating>> myRatings({String? orderId});

  /// [part] is 'food' or 'driver'. Throws [RatingError].
  Future<void> rate(
    String orderId,
    String part,
    int stars, {
    List<String> reasons = const [],
    String comment = '',
  });

  // ---- public
  Future<List<Review>> reviews(String slug, {int limit = 20, int offset = 0});

  // ---- restaurant (managers)
  Future<List<OwnerReview>> ownerReviews({
    List<String>? restaurantIds,
    DateTime? from,
    DateTime? to,
  });
  Future<void> reply(String orderId, String text);
  Future<void> flag(String orderId, String reason);

  // ---- driver
  Future<DriverRatingSummary> driverSummary();

  // ---- reports about customers (restaurant team, driver)
  Future<void> reportCustomer(
    String orderId,
    String reason, {
    String note = '',
  });
  Future<Set<String>> myReportedOrders();

  // ---- admin
  Future<List<AdminDriverRating>> adminDrivers();
  Future<List<AdminRestaurantRating>> adminRestaurants();
  Future<List<FlaggedReview>> adminFlagged();
  Future<void> adminDecision(String orderId, {required bool hide});
  Future<List<CustomerReport>> adminReports({String? status});
  Future<void> adminHandleReport(int id, String status, {String note = ''});
  Future<void> adminSetBlocked(String customerId, bool blocked);
}

RatingFailure _failure(PostgrestException e) {
  final m = e.message;
  for (final (key, f) in [
    ('window_closed', RatingFailure.windowClosed),
    ('rating_locked', RatingFailure.locked),
    ('not_delivered', RatingFailure.notDelivered),
    ('no_driver', RatingFailure.noDriver),
    ('already_replied', RatingFailure.alreadyReplied),
    ('already_flagged', RatingFailure.alreadyFlagged),
    ('already_reported', RatingFailure.alreadyReported),
    ('too_many_reports', RatingFailure.tooManyReports),
    ('customer_gone', RatingFailure.customerGone),
    ('not_found', RatingFailure.notFound),
    ('order_not_found', RatingFailure.notFound),
    ('invalid_', RatingFailure.invalid),
  ]) {
    if (m.contains(key)) return f;
  }
  return RatingFailure.network;
}

class SupabaseRatingsRepository implements RatingsRepository {
  SupabaseRatingsRepository(this._db);
  final SupabaseClient _db;

  Future<T> _run<T>(Future<T> Function() f) async {
    try {
      return await f();
    } on PostgrestException catch (e) {
      throw RatingError(_failure(e));
    } on RatingError {
      rethrow;
    } catch (_) {
      throw const RatingError(RatingFailure.network);
    }
  }

  Future<List<Map<String, dynamic>>> _rows(
    String fn, [
    Map<String, dynamic>? params,
  ]) async {
    final r = await _db.rpc(fn, params: params) as List;
    return r.cast<Map<String, dynamic>>();
  }

  @override
  Future<List<OrderRating>> myRatings({String? orderId}) async {
    final r = await _rows('my_order_ratings', {'p_order_id': orderId});
    return r.map(OrderRating.fromJson).toList();
  }

  @override
  Future<void> rate(
    String orderId,
    String part,
    int stars, {
    List<String> reasons = const [],
    String comment = '',
  }) => _run(
    () => _db.rpc(
      'rate_order',
      params: {
        'p_order_id': orderId,
        'p_part': part,
        'p_stars': stars,
        'p_reasons': reasons,
        'p_comment': comment,
      },
    ),
  );

  @override
  Future<List<Review>> reviews(
    String slug, {
    int limit = 20,
    int offset = 0,
  }) async {
    final r = await _rows('restaurant_reviews', {
      'p_slug': slug,
      'p_limit': limit,
      'p_offset': offset,
    });
    return r.map(Review.fromJson).toList();
  }

  @override
  Future<List<OwnerReview>> ownerReviews({
    List<String>? restaurantIds,
    DateTime? from,
    DateTime? to,
  }) async {
    final r = await _rows('owner_reviews', {
      'p_restaurant_ids': ?restaurantIds,
      'p_from': ?from?.toUtc().toIso8601String(),
      'p_to': ?to?.toUtc().toIso8601String(),
    });
    return r.map(OwnerReview.fromJson).toList();
  }

  @override
  Future<void> reply(String orderId, String text) => _run(
    () => _db.rpc(
      'owner_reply_review',
      params: {'p_order_id': orderId, 'p_text': text},
    ),
  );

  @override
  Future<void> flag(String orderId, String reason) => _run(
    () => _db.rpc(
      'owner_flag_review',
      params: {'p_order_id': orderId, 'p_reason': reason},
    ),
  );

  @override
  Future<DriverRatingSummary> driverSummary() async {
    final r = await _rows('driver_rating_summary');
    return r.isEmpty
        ? const DriverRatingSummary()
        : DriverRatingSummary.fromJson(r.first);
  }

  @override
  Future<void> reportCustomer(
    String orderId,
    String reason, {
    String note = '',
  }) => _run(
    () => _db.rpc(
      'report_customer',
      params: {'p_order_id': orderId, 'p_reason': reason, 'p_note': note},
    ),
  );

  @override
  Future<Set<String>> myReportedOrders() async => {
    for (final r in await _rows('my_reported_orders')) r['order_id'] as String,
  };

  @override
  Future<List<AdminDriverRating>> adminDrivers() async => (await _rows(
    'admin_driver_ratings',
  )).map(AdminDriverRating.fromJson).toList();

  @override
  Future<List<AdminRestaurantRating>> adminRestaurants() async => (await _rows(
    'admin_restaurant_ratings',
  )).map(AdminRestaurantRating.fromJson).toList();

  @override
  Future<List<FlaggedReview>> adminFlagged() async => (await _rows(
    'admin_flagged_reviews',
  )).map(FlaggedReview.fromJson).toList();

  @override
  Future<void> adminDecision(String orderId, {required bool hide}) => _run(
    () => _db.rpc(
      'admin_review_decision',
      params: {'p_order_id': orderId, 'p_hide': hide},
    ),
  );

  @override
  Future<List<CustomerReport>> adminReports({String? status}) async =>
      (await _rows('admin_customer_reports', {
        'p_status': status,
      })).map(CustomerReport.fromJson).toList();

  @override
  Future<void> adminHandleReport(int id, String status, {String note = ''}) =>
      _run(
        () => _db.rpc(
          'admin_handle_report',
          params: {'p_id': id, 'p_status': status, 'p_note': note},
        ),
      );

  @override
  Future<void> adminSetBlocked(String customerId, bool blocked) => _run(
    () => _db.rpc(
      'admin_set_customer_blocked',
      params: {'p_customer_id': customerId, 'p_blocked': blocked},
    ),
  );
}

final ratingsRepositoryProvider = Provider<RatingsRepository>((ref) {
  if (!Env.hasSupabase) {
    throw StateError('Supabase not configured (env.json)');
  }
  return SupabaseRatingsRepository(Supabase.instance.client);
});

/// All my delivered orders of the last 30 days with their ratings.
final myRatingsProvider = FutureProvider<List<OrderRating>>((ref) {
  ref.watch(currentUserIdProvider);
  return ref.watch(ratingsRepositoryProvider).myRatings();
});

/// The rating state of one of my orders (any age).
final orderRatingProvider = FutureProvider.family<OrderRating?, String>((
  ref,
  orderId,
) async {
  ref.watch(currentUserIdProvider);
  final list = await ref
      .watch(ratingsRepositoryProvider)
      .myRatings(orderId: orderId);
  return list.firstOrNull;
});

/// Public reviews of a restaurant (by slug).
final restaurantReviewsProvider = FutureProvider.family<List<Review>, String>(
  (ref, slug) => ref.watch(ratingsRepositoryProvider).reviews(slug),
);

final driverRatingProvider = FutureProvider<DriverRatingSummary>((ref) {
  ref.watch(currentUserIdProvider);
  return ref.watch(ratingsRepositoryProvider).driverSummary();
});

/// Orders the signed-in driver / restaurant already reported.
final reportedOrdersProvider = FutureProvider<Set<String>>((ref) {
  ref.watch(currentUserIdProvider);
  return ref.watch(ratingsRepositoryProvider).myReportedOrders();
});
