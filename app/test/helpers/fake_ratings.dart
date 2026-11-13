import 'package:food_app/features/ratings/ratings_repository.dart';

/// In-memory ratings with the same rules as the database: 7 days to rate,
/// 24 hours to change, one reply, one flag, one report per order.
class FakeRatingsRepository implements RatingsRepository {
  final ratings = <String, OrderRating>{};
  final reviewsBySlug = <String, List<Review>>{};
  final owner = <OwnerReview>[];
  final reported = <String>{};
  final calls = <String>[];
  DriverRatingSummary driver = const DriverRatingSummary();

  // admin
  final adminDriverList = <AdminDriverRating>[];
  final adminRestaurantList = <AdminRestaurantRating>[];
  final flagged = <FlaggedReview>[];
  final reports = <CustomerReport>[];

  /// A delivered order of the customer, ready to be rated.
  OrderRating addDelivered(
    String orderId, {
    DateTime? deliveredAt,
    bool hasDriver = true,
  }) => ratings[orderId] = OrderRating(
    orderId: orderId,
    deliveredAt: deliveredAt ?? DateTime.now(),
    hasDriver: hasDriver,
  );

  @override
  Future<List<OrderRating>> myRatings({String? orderId}) async => [
    for (final r in ratings.values)
      if (orderId == null || r.orderId == orderId) r,
  ];

  @override
  Future<void> rate(
    String orderId,
    String part,
    int stars, {
    List<String> reasons = const [],
    String comment = '',
  }) async {
    final r = ratings[orderId];
    if (r == null) throw const RatingError(RatingFailure.notDelivered);
    final now = DateTime.now();
    if (!r.windowOpen(now)) throw const RatingError(RatingFailure.windowClosed);
    final food = part == 'food';
    final at = food ? r.foodRatedAt : r.driverRatedAt;
    if (at != null && now.isAfter(at.add(ratingEditWindow))) {
      throw const RatingError(RatingFailure.locked);
    }
    final keep = stars <= 3 ? reasons : const <String>[];
    calls.add('rate:$orderId:$part:$stars:${keep.join('+')}:$comment');
    ratings[orderId] = OrderRating(
      orderId: orderId,
      deliveredAt: r.deliveredAt,
      hasDriver: r.hasDriver,
      foodStars: food ? stars : r.foodStars,
      foodReasons: food ? keep : r.foodReasons,
      foodComment: food ? comment : r.foodComment,
      foodRatedAt: food ? (r.foodRatedAt ?? now) : r.foodRatedAt,
      driverStars: food ? r.driverStars : stars,
      driverReasons: food ? r.driverReasons : keep,
      driverComment: food ? r.driverComment : comment,
      driverRatedAt: food ? r.driverRatedAt : (r.driverRatedAt ?? now),
      reply: r.reply,
      replyAt: r.replyAt,
    );
  }

  @override
  Future<List<Review>> reviews(
    String slug, {
    int limit = 20,
    int offset = 0,
  }) async => [...?reviewsBySlug[slug]];

  @override
  Future<List<OwnerReview>> ownerReviews({
    List<String>? restaurantIds,
    DateTime? from,
    DateTime? to,
  }) async => [
    for (final r in owner)
      if ((restaurantIds == null || restaurantIds.contains(r.restaurantId)) &&
          (from == null || !r.ratedAt.isBefore(from)) &&
          (to == null || r.ratedAt.isBefore(to)))
        r,
  ];

  @override
  Future<void> reply(String orderId, String text) async {
    final i = owner.indexWhere((r) => r.orderId == orderId);
    if (i < 0) throw const RatingError(RatingFailure.notFound);
    if ((owner[i].reply ?? '').isNotEmpty) {
      throw const RatingError(RatingFailure.alreadyReplied);
    }
    owner[i] = owner[i].copyWith(reply: text, replyAt: DateTime.now());
    calls.add('reply:$orderId:$text');
  }

  @override
  Future<void> flag(String orderId, String reason) async {
    final i = owner.indexWhere((r) => r.orderId == orderId);
    if (i < 0) throw const RatingError(RatingFailure.notFound);
    if (owner[i].flagged) throw const RatingError(RatingFailure.alreadyFlagged);
    owner[i] = owner[i].copyWith(flaggedAt: DateTime.now());
    calls.add('flag:$orderId:$reason');
  }

  @override
  Future<DriverRatingSummary> driverSummary() async => driver;

  @override
  Future<void> reportCustomer(
    String orderId,
    String reason, {
    String note = '',
  }) async {
    if (!reported.add(orderId)) {
      throw const RatingError(RatingFailure.alreadyReported);
    }
    calls.add('report:$orderId:$reason:$note');
  }

  @override
  Future<Set<String>> myReportedOrders() async => {...reported};

  @override
  Future<List<AdminDriverRating>> adminDrivers() async => [...adminDriverList];

  @override
  Future<List<AdminRestaurantRating>> adminRestaurants() async => [
    ...adminRestaurantList,
  ];

  @override
  Future<List<FlaggedReview>> adminFlagged() async => [...flagged];

  @override
  Future<void> adminDecision(String orderId, {required bool hide}) async {
    final i = flagged.indexWhere((f) => f.orderId == orderId);
    if (i >= 0) {
      final f = flagged[i];
      flagged[i] = FlaggedReview(
        orderId: f.orderId,
        code: f.code,
        restaurantName: f.restaurantName,
        customerLabel: f.customerLabel,
        stars: f.stars,
        ratedAt: f.ratedAt,
        flaggedAt: f.flaggedAt,
        reasons: f.reasons,
        comment: f.comment,
        reply: f.reply,
        flagReason: f.flagReason,
        flagDecision: hide ? 'hidden' : 'kept',
        hidden: hide,
      );
    }
    calls.add('decision:$orderId:${hide ? 'hide' : 'keep'}');
  }

  @override
  Future<List<CustomerReport>> adminReports({String? status}) async => [
    for (final r in reports)
      if (status == null || r.status == status) r,
  ];

  CustomerReport _with(CustomerReport r, {String? status, bool? blocked}) =>
      CustomerReport(
        id: r.id,
        orderCode: r.orderCode,
        reporterRole: r.reporterRole,
        reason: r.reason,
        createdAt: r.createdAt,
        reporterName: r.reporterName,
        restaurantName: r.restaurantName,
        customerId: r.customerId,
        customerName: r.customerName,
        customerPhone: r.customerPhone,
        note: r.note,
        status: status ?? r.status,
        adminNote: r.adminNote,
        customerReportsTotal: r.customerReportsTotal,
        customerBlocked: blocked ?? r.customerBlocked,
      );

  @override
  Future<void> adminHandleReport(
    int id,
    String status, {
    String note = '',
  }) async {
    final i = reports.indexWhere((r) => r.id == id);
    reports[i] = _with(
      reports[i],
      status: status,
      blocked: status == 'blocked' ? true : null,
    );
    calls.add('handle:$id:$status');
  }

  @override
  Future<void> adminSetBlocked(String customerId, bool blocked) async {
    for (var i = 0; i < reports.length; i++) {
      if (reports[i].customerId == customerId) {
        reports[i] = _with(reports[i], blocked: blocked);
      }
    }
    calls.add('block:$customerId:$blocked');
  }
}
