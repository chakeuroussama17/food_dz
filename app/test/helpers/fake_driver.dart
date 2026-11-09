import 'dart:async';

import 'package:food_app/features/admin/data/admin_drivers.dart';
import 'package:food_app/core/utils/pick_image.dart';
import 'package:food_app/features/driver/data/driver_repository.dart';

/// In-memory driver backend with the same rules as the SQL functions.
class FakeDriverRepository implements DriverRepository {
  DriverProfile? profile;
  final offers = <AvailableOrder>[];
  final mine = <DriverOrder>[];
  final calls = <String>[];
  final _changes = StreamController<void>.broadcast();

  /// Orders another driver grabs first (claim fails with alreadyTaken).
  final takenByOthers = <String>{};

  void seedDriver({bool approved = true, bool online = false}) {
    profile = DriverProfile(
      id: 'drv1',
      fullName: 'Rachid Benali',
      phone: '0661000001',
      vehicle: Vehicle.moto,
      isApproved: approved,
      isOnline: online,
    );
  }

  /// A restaurant accepted an order: it shows up for drivers.
  AvailableOrder addAvailable({String id = 'av1', bool ready = false}) {
    final o = AvailableOrder(
      id: id,
      code: 'DRV${offers.length + 1}X',
      status: ready ? 'ready' : 'accepted',
      restaurantName: 'Pizzeria El Bahdja',
      restaurantAddress: 'Rue Larbi Ben Mhidi',
      restaurantArea: 'Bab Ezzouar',
      area: 'Alger Centre',
      deliveryFee: 200,
      total: 1600,
      itemCount: 2,
      placedAt: DateTime.now().subtract(const Duration(minutes: 5)),
    );
    offers.add(o);
    return o;
  }

  DriverOrder _toMine(AvailableOrder a) => DriverOrder(
    id: a.id,
    code: a.code,
    status: a.status,
    restaurantName: a.restaurantName,
    restaurantAddress: a.restaurantAddress,
    restaurantArea: a.restaurantArea,
    restaurantPhone: '0550111222',
    customerName: 'Amina',
    customerPhone: '0550123456',
    addressText: 'Rue Didouche 12',
    area: a.area,
    notes: 'Sonner deux fois',
    foodTotal: a.total - a.deliveryFee,
    deliveryFee: a.deliveryFee,
    total: a.total,
    placedAt: a.placedAt,
    items: const [
      OrderLine(
        name: 'Pizza Margherita',
        unitPrice: 700,
        quantity: 2,
        lineTotal: 1400,
      ),
    ],
  );

  void _set(String id, String status) {
    final i = mine.indexWhere((o) => o.id == id);
    final o = mine[i];
    mine[i] = DriverOrder(
      id: o.id,
      code: o.code,
      status: status,
      restaurantName: o.restaurantName,
      restaurantAddress: o.restaurantAddress,
      restaurantArea: o.restaurantArea,
      restaurantPhone: o.restaurantPhone,
      customerName: o.customerName,
      customerPhone: o.customerPhone,
      addressText: o.addressText,
      area: o.area,
      notes: o.notes,
      foodTotal: o.foodTotal,
      deliveryFee: o.deliveryFee,
      total: o.total,
      placedAt: o.placedAt,
      items: o.items,
      deliveredAt: status == 'delivered' ? DateTime.now() : o.deliveredAt,
    );
    _changes.add(null);
  }

  /// The restaurant marks the order ready (arrives live).
  void restaurantMarksReady(String id) => _set(id, 'ready');

  @override
  Future<DriverProfile?> me() async => profile;

  @override
  Future<void> register({
    required String phone,
    required Vehicle vehicle,
  }) async {
    calls.add('register:$phone:${vehicle.name}');
    profile = DriverProfile(
      id: 'drv1',
      fullName: 'New Driver',
      phone: phone,
      vehicle: vehicle,
      isApproved: false,
      isOnline: false,
    );
  }

  @override
  Future<void> setOnline(bool online) async {
    calls.add('online:$online');
    final p = profile!;
    if (online && !p.isApproved) {
      throw const DriverError(DriverFailure.notApproved);
    }
    profile = DriverProfile(
      id: p.id,
      fullName: p.fullName,
      phone: p.phone,
      vehicle: p.vehicle,
      isApproved: p.isApproved,
      isOnline: online,
    );
  }

  @override
  Future<List<AvailableOrder>> available() async =>
      profile?.isOnline == true ? [...offers] : const [];

  @override
  Future<void> claim(String orderId) async {
    calls.add('claim:$orderId');
    if (mine.any((o) => o.isActive)) {
      throw const DriverError(DriverFailure.busy);
    }
    final a = offers.where((o) => o.id == orderId).firstOrNull;
    if (a == null || takenByOthers.contains(orderId)) {
      offers.removeWhere((o) => o.id == orderId);
      throw const DriverError(DriverFailure.alreadyTaken);
    }
    offers.remove(a);
    mine.add(_toMine(a));
  }

  @override
  Future<void> release(String orderId) async {
    calls.add('release:$orderId');
    final o = mine.firstWhere((o) => o.id == orderId);
    if (!o.canRelease) throw const DriverError(DriverFailure.notAllowed);
    mine.remove(o);
    addAvailable(id: o.id, ready: o.status == 'ready');
  }

  /// Food money owed to restaurants (filled when an order is delivered).
  final cash = <CashDue>[];

  /// Photos received with completeDelivery, by order id.
  final photos = <String, PickedImage>{};

  @override
  Future<void> completeDelivery(String orderId, PickedImage photo) async {
    calls.add('$orderId:delivered+photo');
    final o = mine.firstWhere((o) => o.id == orderId);
    if (o.status != 'picked_up') {
      throw const DriverError(DriverFailure.notAllowed);
    }
    photos[orderId] = photo;
    _set(orderId, 'delivered');
    cash.add(
      CashDue(
        orderId: o.id,
        code: o.code,
        restaurantName: o.restaurantName,
        amount: o.foodTotal,
        deliveredAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<List<CashDue>> cashPending() async => [...cash];

  /// Deliveries returned by [statement].
  final statementRows = <StatementDelivery>[];
  (DateTime, DateTime)? lastStatementRange;

  @override
  Future<List<StatementDelivery>> statement(DateTime from, DateTime to) async {
    lastStatementRange = (from, to);
    return [...statementRows];
  }

  @override
  Future<void> markCashHanded(String orderId) async {
    calls.add('cash:$orderId');
    final i = cash.indexWhere((c) => c.orderId == orderId);
    final c = cash[i];
    cash[i] = CashDue(
      orderId: c.orderId,
      code: c.code,
      restaurantName: c.restaurantName,
      amount: c.amount,
      deliveredAt: c.deliveredAt,
      handedAt: DateTime.now(),
      overdue: c.overdue,
    );
  }

  @override
  Future<void> setStatus(String orderId, String status) async {
    calls.add('$orderId:$status');
    final o = mine.firstWhere((o) => o.id == orderId);
    // Delivered only through completeDelivery (photo), like the database.
    final ok = o.status == 'ready' && status == 'picked_up';
    if (!ok) throw const DriverError(DriverFailure.notAllowed);
    _set(orderId, status);
  }

  @override
  Future<List<DriverOrder>> myOrders({required bool active}) async =>
      mine.where((o) => o.isActive == active).toList();

  @override
  Stream<void> myOrderChanges(String driverId) => _changes.stream;
}

class FakeAdminDriversRepository implements AdminDriversRepository {
  final list = <AdminDriver>[];
  final calls = <String>[];

  @override
  Future<List<AdminDriver>> drivers() async => [...list];

  @override
  Future<AdminOrderDelivery> orderDelivery(String orderId) async =>
      const AdminOrderDelivery(
        driverName: 'Rachid',
        driverPhone: '0661000001',
        cashHandedAt: null,
      );

  @override
  Future<void> setApproved(String id, bool approved) async {
    calls.add('$id:$approved');
    final i = list.indexWhere((d) => d.id == id);
    final d = list[i];
    list[i] = AdminDriver(
      id: d.id,
      fullName: d.fullName,
      email: d.email,
      phone: d.phone,
      vehicle: d.vehicle,
      isApproved: approved,
      isOnline: approved && d.isOnline,
      createdAt: d.createdAt,
      deliveredCount: d.deliveredCount,
    );
  }
}
