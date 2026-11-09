/// Data classes for the admin area (mirror the admin_* SQL functions).
library;

int _i(Object? v) => (v as num?)?.toInt() ?? 0;
double _d(Object? v) => v == null ? 0 : double.parse(v.toString());
DateTime? _t(Object? v) => v == null ? null : DateTime.parse(v as String);

class AdminRestaurant {
  const AdminRestaurant({
    required this.id,
    required this.slug,
    required this.name,
    this.area = '',
    this.address = '',
    this.phone = '',
    this.ownerName = '',
    this.ownerEmail = '',
    this.isActive = false,
    this.isOpen = false,
    this.commissionRate,
    this.effectiveRate = 0.08,
    this.createdAt,
    this.deliveredCount = 0,
    this.unbilledCount = 0,
    this.unbilledCommission = 0,
  });

  final String id;
  final String slug;
  final String name;
  final String area;
  final String address;
  final String phone;
  final String ownerName;
  final String ownerEmail;
  final bool isActive;
  final bool isOpen;

  /// Null = uses the default rate.
  final double? commissionRate;
  final double effectiveRate;
  final DateTime? createdAt;
  final int deliveredCount;
  final int unbilledCount;
  final int unbilledCommission;

  /// Registered by an owner and waiting for approval.
  bool get isPending => !isActive && ownerEmail.isNotEmpty;

  factory AdminRestaurant.fromJson(Map<String, dynamic> j) => AdminRestaurant(
    id: j['id'] as String,
    slug: j['slug'] as String,
    name: j['name'] as String,
    area: (j['area'] as String?) ?? '',
    address: (j['address'] as String?) ?? '',
    phone: (j['phone'] as String?) ?? '',
    ownerName: (j['owner_name'] as String?) ?? '',
    ownerEmail: (j['owner_email'] as String?) ?? '',
    isActive: (j['is_active'] as bool?) ?? false,
    isOpen: (j['is_open'] as bool?) ?? false,
    commissionRate: j['commission_rate'] == null
        ? null
        : _d(j['commission_rate']),
    effectiveRate: _d(j['effective_rate']),
    createdAt: _t(j['created_at']),
    deliveredCount: _i(j['delivered_count']),
    unbilledCount: _i(j['unbilled_count']),
    unbilledCommission: _i(j['unbilled_commission']),
  );
}

class AdminConfig {
  const AdminConfig({
    required this.deliveryFee,
    required this.defaultCommissionRate,
    this.businessName = '',
    this.businessPhone = '',
    this.businessEmail = '',
    this.businessAddress = '',
    this.businessTaxId = '',
    this.cashHandoverHours = 24,
    this.autoRejectMinutes = 10,
  });

  /// Orders not answered by the restaurant within this delay are rejected.
  final int autoRejectMinutes;

  /// Hours before a driver with unconfirmed cash can't take new orders.
  final int cashHandoverHours;
  final int deliveryFee;
  final double defaultCommissionRate;
  final String businessName;
  final String businessPhone;
  final String businessEmail;
  final String businessAddress;
  final String businessTaxId;

  factory AdminConfig.fromJson(Map<String, dynamic> j) => AdminConfig(
    deliveryFee: _i(j['delivery_fee']),
    defaultCommissionRate: _d(j['default_commission_rate']),
    businessName: (j['business_name'] as String?) ?? '',
    businessPhone: (j['business_phone'] as String?) ?? '',
    businessEmail: (j['business_email'] as String?) ?? '',
    businessAddress: (j['business_address'] as String?) ?? '',
    businessTaxId: (j['business_tax_id'] as String?) ?? '',
    cashHandoverHours: (j['cash_handover_hours'] as num?)?.toInt() ?? 24,
    autoRejectMinutes: (j['auto_reject_minutes'] as num?)?.toInt() ?? 10,
  );
}

class AdminStats {
  const AdminStats({
    this.deliveredOrders = 0,
    this.foodTotal = 0,
    this.deliveryFees = 0,
    this.commission = 0,
    this.cancelledOrders = 0,
    this.activeOrders = 0,
    this.pendingRestaurants = 0,
    this.activeRestaurants = 0,
    this.customers = 0,
    this.unbilledCommission = 0,
  });

  final int deliveredOrders;
  final int foodTotal;
  final int deliveryFees;
  final int commission;
  final int cancelledOrders;
  final int activeOrders;
  final int pendingRestaurants;
  final int activeRestaurants;
  final int customers;
  final int unbilledCommission;

  factory AdminStats.fromJson(Map<String, dynamic> j) => AdminStats(
    deliveredOrders: _i(j['delivered_orders']),
    foodTotal: _i(j['food_total']),
    deliveryFees: _i(j['delivery_fees']),
    commission: _i(j['commission']),
    cancelledOrders: _i(j['cancelled_orders']),
    activeOrders: _i(j['active_orders']),
    pendingRestaurants: _i(j['pending_restaurants']),
    activeRestaurants: _i(j['active_restaurants']),
    customers: _i(j['customers']),
    unbilledCommission: _i(j['unbilled_commission']),
  );
}

class RestaurantStat {
  const RestaurantStat({
    required this.restaurantId,
    required this.name,
    this.deliveredOrders = 0,
    this.foodTotal = 0,
    this.commission = 0,
  });

  final String restaurantId;
  final String name;
  final int deliveredOrders;
  final int foodTotal;
  final int commission;

  factory RestaurantStat.fromJson(Map<String, dynamic> j) => RestaurantStat(
    restaurantId: j['restaurant_id'] as String,
    name: j['name'] as String,
    deliveredOrders: _i(j['delivered_orders']),
    foodTotal: _i(j['food_total']),
    commission: _i(j['commission']),
  );
}

const orderStatuses = [
  'placed',
  'accepted',
  'rejected',
  'ready',
  'picked_up',
  'delivered',
  'cancelled',
];

class AdminOrder {
  const AdminOrder({
    required this.id,
    required this.code,
    required this.restaurantName,
    required this.status,
    required this.total,
    required this.placedAt,
    this.restaurantId = '',
    this.customerName = '',
    this.customerPhone = '',
    this.area = '',
    this.foodTotal = 0,
    this.deliveryFee = 0,
    this.commissionAmount,
    this.deliveredAt,
    this.statementNumber,
  });

  final String id;
  final String code;
  final String restaurantId;
  final String restaurantName;
  final String customerName;
  final String customerPhone;
  final String area;
  final String status;
  final int foodTotal;
  final int deliveryFee;
  final int total;
  final int? commissionAmount;
  final DateTime placedAt;
  final DateTime? deliveredAt;
  final String? statementNumber;

  factory AdminOrder.fromJson(Map<String, dynamic> j) => AdminOrder(
    id: j['id'] as String,
    code: j['code'] as String,
    restaurantId: j['restaurant_id'] as String,
    restaurantName: j['restaurant_name'] as String,
    customerName: (j['customer_name'] as String?) ?? '',
    customerPhone: (j['customer_phone'] as String?) ?? '',
    area: (j['area'] as String?) ?? '',
    status: j['status'] as String,
    foodTotal: _i(j['food_total']),
    deliveryFee: _i(j['delivery_fee']),
    total: _i(j['total']),
    commissionAmount: (j['commission_amount'] as num?)?.toInt(),
    placedAt: _t(j['placed_at'])!,
    deliveredAt: _t(j['delivered_at']),
    statementNumber: j['statement_number'] as String?,
  );
}

class AdminOrderItem {
  const AdminOrderItem(
    this.name,
    this.unitPrice,
    this.quantity,
    this.lineTotal,
  );
  final String name;
  final int unitPrice;
  final int quantity;
  final int lineTotal;

  factory AdminOrderItem.fromJson(Map<String, dynamic> j) => AdminOrderItem(
    j['name'] as String,
    _i(j['unit_price']),
    _i(j['quantity']),
    _i(j['line_total']),
  );
}

class AdminCustomer {
  const AdminCustomer({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.createdAt,
    this.ordersCount = 0,
    this.spent = 0,
  });

  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final DateTime? createdAt;
  final int ordersCount;
  final int spent;

  factory AdminCustomer.fromJson(Map<String, dynamic> j) => AdminCustomer(
    id: j['id'] as String,
    fullName: (j['full_name'] as String?) ?? '',
    email: (j['email'] as String?) ?? '',
    phone: j['phone'] as String?,
    createdAt: _t(j['created_at']),
    ordersCount: _i(j['orders_count']),
    spent: _i(j['spent']),
  );
}

class StatementPreview {
  const StatementPreview(
    this.ordersCount,
    this.foodTotal,
    this.commissionTotal,
  );
  final int ordersCount;
  final int foodTotal;
  final int commissionTotal;

  factory StatementPreview.fromJson(Map<String, dynamic> j) => StatementPreview(
    _i(j['orders_count']),
    _i(j['food_total']),
    _i(j['commission_total']),
  );
}

class StatementSummary {
  const StatementSummary({
    required this.id,
    required this.number,
    required this.restaurantId,
    required this.restaurantName,
    required this.periodStart,
    required this.periodEnd,
    required this.ordersCount,
    required this.foodTotal,
    required this.commissionTotal,
    required this.status,
    required this.issuedAt,
    this.paidAt,
  });

  final String id;
  final String number;
  final String restaurantId;
  final String restaurantName;
  final DateTime periodStart;
  final DateTime periodEnd;
  final int ordersCount;
  final int foodTotal;
  final int commissionTotal;

  /// 'issued' or 'paid'.
  final String status;
  final DateTime issuedAt;
  final DateTime? paidAt;

  bool get isPaid => status == 'paid';

  factory StatementSummary.fromJson(Map<String, dynamic> j) => StatementSummary(
    id: j['id'] as String,
    number: j['number'] as String,
    restaurantId: j['restaurant_id'] as String,
    restaurantName: (j['restaurant_name'] as String?) ?? '',
    periodStart: DateTime.parse(j['period_start'] as String),
    periodEnd: DateTime.parse(j['period_end'] as String),
    ordersCount: _i(j['orders_count']),
    foodTotal: _i(j['food_total']),
    commissionTotal: _i(j['commission_total']),
    status: j['status'] as String,
    issuedAt: _t(j['issued_at'])!,
    paidAt: _t(j['paid_at']),
  );
}

class StatementLine {
  const StatementLine({
    required this.code,
    required this.deliveredAt,
    required this.foodTotal,
    required this.commissionRate,
    required this.commissionAmount,
  });

  final String code;
  final DateTime deliveredAt;
  final int foodTotal;
  final double commissionRate;
  final int commissionAmount;

  factory StatementLine.fromJson(Map<String, dynamic> j) => StatementLine(
    code: j['code'] as String,
    deliveredAt: DateTime.parse(j['delivered_at'] as String),
    foodTotal: _i(j['food_total']),
    commissionRate: _d(j['commission_rate']),
    commissionAmount: _i(j['commission_amount']),
  );
}

/// Everything printed on a commission statement.
class StatementDetail {
  const StatementDetail({
    required this.statement,
    required this.restaurantName,
    required this.lines,
    this.restaurantAddress = '',
    this.restaurantPhone = '',
    this.ownerName = '',
    this.ownerEmail = '',
    this.business = const AdminConfig(deliveryFee: 0, defaultCommissionRate: 0),
  });

  final StatementSummary statement;
  final String restaurantName;
  final String restaurantAddress;
  final String restaurantPhone;
  final String ownerName;
  final String ownerEmail;
  final AdminConfig business;
  final List<StatementLine> lines;

  factory StatementDetail.fromJson(Map<String, dynamic> j) {
    final s = Map<String, dynamic>.from(j['statement'] as Map);
    final r = Map<String, dynamic>.from(j['restaurant'] as Map);
    s['restaurant_name'] = r['name'];
    final addr = [
      r['address'],
      r['area'],
    ].whereType<String>().where((x) => x.isNotEmpty).join(', ');
    return StatementDetail(
      statement: StatementSummary.fromJson(s),
      restaurantName: r['name'] as String,
      restaurantAddress: addr,
      restaurantPhone: (r['phone'] as String?) ?? '',
      ownerName: (r['owner_name'] as String?) ?? '',
      ownerEmail: (r['owner_email'] as String?) ?? '',
      business: AdminConfig.fromJson(
        Map<String, dynamic>.from(j['business'] as Map),
      ),
      lines: ((j['orders'] as List?) ?? const [])
          .map(
            (e) => StatementLine.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
    );
  }
}
