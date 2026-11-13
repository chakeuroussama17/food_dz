/// Reasons offered with a poor rating (keys match the database).
const foodReasons = [
  'cold',
  'missing_item',
  'wrong_order',
  'small_portion',
  'bad_taste',
  'bad_packaging',
];
const deliveryReasons = [
  'late',
  'rude',
  'careless',
  'no_contact',
  'wrong_place',
];

/// Why a customer is reported (restaurant or driver, private).
const reportReasons = [
  'fake_order',
  'no_answer',
  'wrong_address',
  'refused_to_pay',
  'rude',
  'other',
];

/// Days a delivered order can be rated.
const ratingWindow = Duration(days: 7);

/// A rating can be changed this long after it was given.
const ratingEditWindow = Duration(hours: 24);

DateTime? _t(Object? v) =>
    v == null ? null : DateTime.parse(v as String).toLocal();

List<String> _list(Object? v) => [
  for (final x in (v as List? ?? const [])) x as String,
];

/// What the customer rated on one delivered order.
class OrderRating {
  const OrderRating({
    required this.orderId,
    required this.deliveredAt,
    this.hasDriver = true,
    this.foodStars,
    this.foodReasons = const [],
    this.foodComment = '',
    this.foodRatedAt,
    this.driverStars,
    this.driverReasons = const [],
    this.driverComment = '',
    this.driverRatedAt,
    this.reply,
    this.replyAt,
  });

  final String orderId;
  final DateTime deliveredAt;
  final bool hasDriver;
  final int? foodStars;
  final List<String> foodReasons;
  final String foodComment;
  final DateTime? foodRatedAt;
  final int? driverStars;
  final List<String> driverReasons;
  final String driverComment;
  final DateTime? driverRatedAt;

  /// The restaurant's public answer to the food rating.
  final String? reply;
  final DateTime? replyAt;

  DateTime get windowEnds => deliveredAt.add(ratingWindow);

  bool windowOpen(DateTime now) => now.isBefore(windowEnds);

  /// Whole days left to rate (at least 1 while open).
  int daysLeft(DateTime now) {
    final h = windowEnds.difference(now).inHours;
    return h <= 0 ? 0 : (h / 24).ceil();
  }

  bool _open(DateTime now, int? stars, DateTime? at) {
    if (!windowOpen(now)) return false;
    if (stars == null) return true;
    return at != null && now.isBefore(at.add(ratingEditWindow));
  }

  /// Not rated yet, or still changeable.
  bool foodOpen(DateTime now) => _open(now, foodStars, foodRatedAt);
  bool driverOpen(DateTime now) =>
      hasDriver && _open(now, driverStars, driverRatedAt);

  /// Waiting for the first rating of the driver.
  bool needsDriver(DateTime now) =>
      hasDriver && driverStars == null && windowOpen(now);
  bool needsFood(DateTime now) => foodStars == null && windowOpen(now);

  factory OrderRating.fromJson(Map<String, dynamic> j) => OrderRating(
    orderId: j['order_id'] as String,
    deliveredAt: _t(j['delivered_at'])!,
    hasDriver: (j['has_driver'] as bool?) ?? true,
    foodStars: (j['food_stars'] as num?)?.toInt(),
    foodReasons: _list(j['food_reasons']),
    foodComment: (j['food_comment'] as String?) ?? '',
    foodRatedAt: _t(j['food_rated_at']),
    driverStars: (j['driver_stars'] as num?)?.toInt(),
    driverReasons: _list(j['driver_reasons']),
    driverComment: (j['driver_comment'] as String?) ?? '',
    driverRatedAt: _t(j['driver_rated_at']),
    reply: j['reply'] as String?,
    replyAt: _t(j['reply_at']),
  );
}

/// A public review on a restaurant page.
class Review {
  const Review({
    required this.customerLabel,
    required this.stars,
    required this.ratedAt,
    this.reasons = const [],
    this.comment = '',
    this.reply,
    this.replyAt,
  });

  final String customerLabel;
  final int stars;
  final List<String> reasons;
  final String comment;
  final DateTime ratedAt;
  final String? reply;
  final DateTime? replyAt;

  factory Review.fromJson(Map<String, dynamic> j) => Review(
    customerLabel: (j['customer_label'] as String?) ?? '',
    stars: (j['stars'] as num).toInt(),
    reasons: _list(j['reasons']),
    comment: (j['comment'] as String?) ?? '',
    ratedAt: _t(j['rated_at'])!,
    reply: j['reply'] as String?,
    replyAt: _t(j['reply_at']),
  );
}

/// A review as the restaurant sees it (portal).
class OwnerReview {
  const OwnerReview({
    required this.orderId,
    required this.code,
    required this.restaurantId,
    required this.restaurantName,
    required this.customerLabel,
    required this.stars,
    required this.ratedAt,
    this.reasons = const [],
    this.comment = '',
    this.reply,
    this.replyAt,
    this.flaggedAt,
    this.flagDecision,
    this.items = '',
    this.total = 0,
  });

  final String orderId;
  final String code;
  final String restaurantId;
  final String restaurantName;
  final String customerLabel;
  final int stars;
  final List<String> reasons;
  final String comment;
  final DateTime ratedAt;
  final String? reply;
  final DateTime? replyAt;
  final DateTime? flaggedAt;

  /// 'hidden' | 'kept' | null (waiting).
  final String? flagDecision;
  final String items;
  final int total;

  bool get flagged => flaggedAt != null;
  bool get flagPending => flaggedAt != null && flagDecision == null;

  OwnerReview copyWith({
    String? reply,
    DateTime? replyAt,
    DateTime? flaggedAt,
  }) => OwnerReview(
    orderId: orderId,
    code: code,
    restaurantId: restaurantId,
    restaurantName: restaurantName,
    customerLabel: customerLabel,
    stars: stars,
    ratedAt: ratedAt,
    reasons: reasons,
    comment: comment,
    reply: reply ?? this.reply,
    replyAt: replyAt ?? this.replyAt,
    flaggedAt: flaggedAt ?? this.flaggedAt,
    flagDecision: flagDecision,
    items: items,
    total: total,
  );

  factory OwnerReview.fromJson(Map<String, dynamic> j) => OwnerReview(
    orderId: j['order_id'] as String,
    code: (j['code'] as String?) ?? '',
    restaurantId: j['restaurant_id'] as String,
    restaurantName: (j['restaurant_name'] as String?) ?? '',
    customerLabel: (j['customer_label'] as String?) ?? '',
    stars: (j['stars'] as num).toInt(),
    reasons: _list(j['reasons']),
    comment: (j['comment'] as String?) ?? '',
    ratedAt: _t(j['rated_at'])!,
    reply: j['reply'] as String?,
    replyAt: _t(j['reply_at']),
    flaggedAt: _t(j['flagged_at']),
    flagDecision: j['flag_decision'] as String?,
    items: (j['items'] as String?) ?? '',
    total: (j['total'] as num?)?.toInt() ?? 0,
  );
}

/// The driver's own rating: an average from 5 ratings on, and how often
/// each reason came up (never who).
class DriverRatingSummary {
  const DriverRatingSummary({
    this.average,
    this.count = 0,
    this.reasons = const {},
  });

  final double? average;
  final int count;
  final Map<String, int> reasons;

  factory DriverRatingSummary.fromJson(Map<String, dynamic> j) =>
      DriverRatingSummary(
        average: (j['rating_avg'] as num?)?.toDouble(),
        count: (j['rating_count'] as num?)?.toInt() ?? 0,
        reasons: {
          for (final e in ((j['reasons'] as Map?) ?? const {}).entries)
            e.key as String: (e.value as num).toInt(),
        },
      );
}

/// Rating figures of a restaurant: average null until 5 ratings.
class RatingFigures {
  const RatingFigures({this.average, this.count = 0});
  final double? average;
  final int count;
}

// ---------------------------------------------------------------- admin

class AdminDriverRating {
  const AdminDriverRating({
    required this.driverId,
    required this.name,
    this.phone = '',
    this.ratedCount = 0,
    this.average,
    this.average30d,
    this.low30d = 0,
    this.reasons = const {},
  });

  final String driverId;
  final String name;
  final String phone;
  final int ratedCount;
  final double? average;
  final double? average30d;

  /// Ratings of 1 or 2 stars in the last 30 days.
  final int low30d;
  final Map<String, int> reasons;

  factory AdminDriverRating.fromJson(Map<String, dynamic> j) =>
      AdminDriverRating(
        driverId: j['driver_id'] as String,
        name: (j['name'] as String?) ?? '',
        phone: (j['phone'] as String?) ?? '',
        ratedCount: (j['rated_count'] as num?)?.toInt() ?? 0,
        average: (j['rating_avg'] as num?)?.toDouble(),
        average30d: (j['avg_30d'] as num?)?.toDouble(),
        low30d: (j['low_30d'] as num?)?.toInt() ?? 0,
        reasons: {
          for (final e in ((j['reasons'] as Map?) ?? const {}).entries)
            e.key as String: (e.value as num).toInt(),
        },
      );
}

class AdminRestaurantRating {
  const AdminRestaurantRating({
    required this.restaurantId,
    required this.name,
    this.ratedCount = 0,
    this.average,
    this.average30d,
    this.flaggedPending = 0,
  });

  final String restaurantId;
  final String name;
  final int ratedCount;
  final double? average;
  final double? average30d;
  final int flaggedPending;

  factory AdminRestaurantRating.fromJson(Map<String, dynamic> j) =>
      AdminRestaurantRating(
        restaurantId: j['restaurant_id'] as String,
        name: (j['name'] as String?) ?? '',
        ratedCount: (j['rated_count'] as num?)?.toInt() ?? 0,
        average: (j['rating_avg'] as num?)?.toDouble(),
        average30d: (j['avg_30d'] as num?)?.toDouble(),
        flaggedPending: (j['flagged_pending'] as num?)?.toInt() ?? 0,
      );
}

/// A review the restaurant asked the admin to look at.
class FlaggedReview {
  const FlaggedReview({
    required this.orderId,
    required this.code,
    required this.restaurantName,
    required this.customerLabel,
    required this.stars,
    required this.ratedAt,
    required this.flaggedAt,
    this.reasons = const [],
    this.comment = '',
    this.reply,
    this.flagReason = '',
    this.flagDecision,
    this.hidden = false,
  });

  final String orderId;
  final String code;
  final String restaurantName;
  final String customerLabel;
  final int stars;
  final List<String> reasons;
  final String comment;
  final DateTime ratedAt;
  final String? reply;
  final DateTime flaggedAt;
  final String flagReason;
  final String? flagDecision;
  final bool hidden;

  factory FlaggedReview.fromJson(Map<String, dynamic> j) => FlaggedReview(
    orderId: j['order_id'] as String,
    code: (j['code'] as String?) ?? '',
    restaurantName: (j['restaurant_name'] as String?) ?? '',
    customerLabel: (j['customer_label'] as String?) ?? '',
    stars: (j['stars'] as num).toInt(),
    reasons: _list(j['reasons']),
    comment: (j['comment'] as String?) ?? '',
    ratedAt: _t(j['rated_at'])!,
    reply: j['reply'] as String?,
    flaggedAt: _t(j['flagged_at'])!,
    flagReason: (j['flag_reason'] as String?) ?? '',
    flagDecision: j['flag_decision'] as String?,
    hidden: (j['hidden'] as bool?) ?? false,
  );
}

/// A private report about a customer (admin).
class CustomerReport {
  const CustomerReport({
    required this.id,
    required this.orderCode,
    required this.reporterRole,
    required this.reason,
    required this.createdAt,
    this.reporterName = '',
    this.restaurantName = '',
    this.customerId,
    this.customerName = '',
    this.customerPhone = '',
    this.note = '',
    this.status = 'open',
    this.adminNote = '',
    this.customerReportsTotal = 0,
    this.customerBlocked = false,
  });

  final int id;
  final String orderCode;

  /// 'restaurant' or 'driver'.
  final String reporterRole;
  final String reporterName;
  final String restaurantName;
  final String? customerId;
  final String customerName;
  final String customerPhone;
  final String reason;
  final String note;
  final DateTime createdAt;

  /// open | warned | blocked | dismissed.
  final String status;
  final String adminNote;
  final int customerReportsTotal;
  final bool customerBlocked;

  factory CustomerReport.fromJson(Map<String, dynamic> j) => CustomerReport(
    id: (j['id'] as num).toInt(),
    orderCode: (j['order_code'] as String?) ?? '',
    reporterRole: j['reporter_role'] as String,
    reporterName: (j['reporter_name'] as String?) ?? '',
    restaurantName: (j['restaurant_name'] as String?) ?? '',
    customerId: j['customer_id'] as String?,
    customerName: (j['customer_name'] as String?) ?? '',
    customerPhone: (j['customer_phone'] as String?) ?? '',
    reason: j['reason'] as String,
    note: (j['note'] as String?) ?? '',
    createdAt: _t(j['created_at'])!,
    status: (j['status'] as String?) ?? 'open',
    adminNote: (j['admin_note'] as String?) ?? '',
    customerReportsTotal: (j['customer_reports_total'] as num?)?.toInt() ?? 0,
    customerBlocked: (j['customer_blocked'] as bool?) ?? false,
  );
}
