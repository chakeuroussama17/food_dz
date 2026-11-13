import 'dart:typed_data';

import 'package:food_app/core/files/file_output.dart';

import 'package:food_app/features/admin/data/admin_models.dart';
import 'package:food_app/features/admin/data/admin_repository.dart';
import 'package:food_app/features/admin/pages/admin_receipt_pages.dart';

/// Captures PDFs instead of downloading / printing them.
class FakePdfOutput implements PdfOutput {
  final downloads = <String, Uint8List>{};
  final printed = <String>[];

  @override
  Future<void> download(Uint8List bytes, String filename) async =>
      downloads[filename] = bytes;

  @override
  Future<void> print(Uint8List bytes, String name) async => printed.add(name);
}

/// Keeps exported files instead of downloading / sharing them.
class FakeFileOutput implements FileOutput {
  final saved = <String, Uint8List>{};

  @override
  Future<void> save(Uint8List bytes, String filename, String mimeType) async =>
      saved[filename] = bytes;
}

/// Delivered order used by the fake statements logic.
class FakeDelivered {
  FakeDelivered(
    this.restaurantId,
    this.code,
    this.food,
    this.day, {
    this.rate = 0.08,
  });
  final String restaurantId;
  final String code;
  final int food;
  final DateTime day;
  final double rate;
  String? statementId;
  int get commission => (food * rate).round();
}

class FakeAdminRepository implements AdminRepository {
  final restaurantsList = <AdminRestaurant>[
    const AdminRestaurant(
      id: 'r1',
      slug: 'burger-house',
      name: 'Burger House',
      isActive: true,
      isOpen: true,
      effectiveRate: 0.08,
    ),
    const AdminRestaurant(
      id: 'r2',
      slug: 'chez-omar',
      name: 'Chez Omar',
      ownerName: 'Omar',
      ownerEmail: 'o@mail.dz',
      effectiveRate: 0.08,
    ),
  ];
  final delivered = <FakeDelivered>[];
  final statementsList = <StatementSummary>[];
  AdminConfig cfg = const AdminConfig(
    deliveryFee: 200,
    defaultCommissionRate: 0.08,
    businessName: 'Food',
  );
  var _n = 0;

  void _replace(String id, AdminRestaurant Function(AdminRestaurant) f) {
    final i = restaurantsList.indexWhere((r) => r.id == id);
    restaurantsList[i] = f(restaurantsList[i]);
  }

  AdminRestaurant _copy(
    AdminRestaurant r, {
    bool? isActive,
    double? rate,
    bool clearRate = false,
  }) => AdminRestaurant(
    id: r.id,
    slug: r.slug,
    name: r.name,
    ownerName: r.ownerName,
    ownerEmail: r.ownerEmail,
    isActive: isActive ?? r.isActive,
    isOpen: r.isOpen,
    commissionRate: clearRate ? null : (rate ?? r.commissionRate),
    effectiveRate: clearRate
        ? cfg.defaultCommissionRate
        : (rate ?? r.effectiveRate),
    unbilledCommission: delivered
        .where((d) => d.restaurantId == r.id && d.statementId == null)
        .fold(0, (t, d) => t + d.commission),
  );

  @override
  Future<List<AdminRestaurant>> restaurants() async => [
    for (final r in restaurantsList) _copy(r),
  ];

  @override
  Future<void> setActive(String id, bool active) async =>
      _replace(id, (r) => _copy(r, isActive: active));

  @override
  Future<void> setCommission(String id, double? rate) async => _replace(
    id,
    (r) => rate == null ? _copy(r, clearRate: true) : _copy(r, rate: rate),
  );

  @override
  Future<AdminConfig> config() async => cfg;

  @override
  Future<void> updateConfig(AdminConfig c) async => cfg = c;

  bool _in(DateTime d, DateRange r) =>
      !d.isBefore(r.start) && !d.isAfter(r.end);

  @override
  Future<AdminStats> stats(DateRange r) async {
    final ds = delivered.where((d) => _in(d.day, r));
    return AdminStats(
      deliveredOrders: ds.length,
      foodTotal: ds.fold(0, (t, d) => t + d.food),
      deliveryFees: ds.length * 200,
      commission: ds.fold(0, (t, d) => t + d.commission),
      pendingRestaurants: restaurantsList.where((x) => x.isPending).length,
      unbilledCommission: delivered
          .where((d) => d.statementId == null)
          .fold(0, (t, d) => t + d.commission),
    );
  }

  @override
  Future<List<RestaurantStat>> statsByRestaurant(DateRange r) async => [
    for (final x in restaurantsList)
      RestaurantStat(
        restaurantId: x.id,
        name: x.name,
        deliveredOrders: delivered
            .where((d) => d.restaurantId == x.id && _in(d.day, r))
            .length,
        commission: delivered
            .where((d) => d.restaurantId == x.id && _in(d.day, r))
            .fold(0, (t, d) => t + d.commission),
      ),
  ];

  @override
  Future<List<AdminOrder>> orders(
    DateRange r, {
    String? restaurantId,
    String? status,
    int limit = 50,
    int offset = 0,
  }) async => [
    for (final d in delivered.where(
      (d) =>
          _in(d.day, r) &&
          (restaurantId == null || d.restaurantId == restaurantId),
    ))
      AdminOrder(
        id: d.code,
        code: d.code,
        restaurantId: d.restaurantId,
        restaurantName: restaurantsList
            .firstWhere((x) => x.id == d.restaurantId)
            .name,
        status: 'delivered',
        foodTotal: d.food,
        deliveryFee: 200,
        total: d.food + 200,
        placedAt: d.day,
        deliveredAt: d.day,
      ),
  ].skip(offset).take(limit).toList();

  @override
  Future<List<AdminOrderItem>> orderItems(String orderId) async => const [
    AdminOrderItem('Smash Burger', 850, 1, 850),
  ];

  CustomerInsights insights = const CustomerInsights();

  @override
  Future<CustomerInsights> customerInsights() async => insights;

  /// Replaces the default single customer when not empty.
  List<AdminCustomer> customerList = const [];

  @override
  Future<List<AdminCustomer>> customers({
    String search = '',
    int limit = 50,
  }) async => customerList.isNotEmpty
      ? customerList
            .where(
              (c) =>
                  search.isEmpty ||
                  '${c.fullName} ${c.email}'.toLowerCase().contains(
                    search.toLowerCase(),
                  ),
            )
            .toList()
      : const [AdminCustomer(id: 'c1', fullName: 'Karim', email: 'k@mail.dz')];

  Iterable<FakeDelivered> _billable(String rid, DateRange r) => delivered.where(
    (d) => d.restaurantId == rid && d.statementId == null && _in(d.day, r),
  );

  @override
  Future<StatementPreview> previewStatement(String rid, DateRange r) async {
    final ds = _billable(rid, r);
    return StatementPreview(
      ds.length,
      ds.fold(0, (t, d) => t + d.food),
      ds.fold(0, (t, d) => t + d.commission),
    );
  }

  @override
  Future<String> generateStatement(String rid, DateRange r) async {
    final ds = _billable(rid, r).toList();
    if (ds.isEmpty) throw Exception('no orders to bill');
    final id = 's${++_n}';
    for (final d in ds) {
      d.statementId = id;
    }
    statementsList.insert(
      0,
      StatementSummary(
        id: id,
        number: 'FD-2026-${_n.toString().padLeft(4, '0')}',
        restaurantId: rid,
        restaurantName: restaurantsList.firstWhere((x) => x.id == rid).name,
        periodStart: r.start,
        periodEnd: r.end,
        ordersCount: ds.length,
        foodTotal: ds.fold(0, (t, d) => t + d.food),
        commissionTotal: ds.fold(0, (t, d) => t + d.commission),
        status: 'issued',
        issuedAt: DateTime.now(),
      ),
    );
    return id;
  }

  @override
  Future<List<StatementSummary>> statements({String? restaurantId}) async => [
    ...statementsList,
  ];

  @override
  Future<StatementDetail> statementDetail(String id) async {
    final s = statementsList.firstWhere((x) => x.id == id);
    return StatementDetail(
      statement: s,
      restaurantName: s.restaurantName,
      business: cfg,
      lines: [
        for (final d in delivered.where((d) => d.statementId == id))
          StatementLine(
            code: d.code,
            deliveredAt: d.day,
            foodTotal: d.food,
            commissionRate: d.rate,
            commissionAmount: d.commission,
          ),
      ],
    );
  }

  @override
  Future<void> setStatementPaid(String id, bool paid) async {
    final i = statementsList.indexWhere((x) => x.id == id);
    final s = statementsList[i];
    statementsList[i] = StatementSummary(
      id: s.id,
      number: s.number,
      restaurantId: s.restaurantId,
      restaurantName: s.restaurantName,
      periodStart: s.periodStart,
      periodEnd: s.periodEnd,
      ordersCount: s.ordersCount,
      foodTotal: s.foodTotal,
      commissionTotal: s.commissionTotal,
      status: paid ? 'paid' : 'issued',
      issuedAt: s.issuedAt,
      paidAt: paid ? DateTime.now() : null,
    );
  }

  @override
  Future<void> cancelStatement(String id) async {
    for (final d in delivered.where((d) => d.statementId == id)) {
      d.statementId = null;
    }
    statementsList.removeWhere((x) => x.id == id);
  }
}
