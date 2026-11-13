import '../features/restaurant_owner/data/owner_orders_repository.dart';
import '../features/restaurant_owner/insights/insights.dart';

bool _inside(OwnerOrder o, DateTime from, DateTime to) =>
    !o.placedAt.isBefore(from) && o.placedAt.isBefore(to);

/// Sales (delivered food money) by hour (rows 0..23) and weekday
/// (columns, 0 = Saturday), averaged over the weeks of the period.
List<List<double>> salesByHourAndDay(
  Iterable<OwnerOrder> all,
  DateTime from,
  DateTime to,
) {
  final grid = List.generate(24, (_) => List<double>.filled(7, 0));
  for (final o in all) {
    if (o.status != 'delivered' || !_inside(o, from, to)) continue;
    grid[o.placedAt.hour][Insights.weekdayIndex(o.placedAt)] += o.foodTotal;
  }
  // Number of each weekday in the period, to average.
  final weekdays = List.filled(7, 0);
  for (
    var d = DateTime(from.year, from.month, from.day);
    d.isBefore(to);
    d = DateTime(d.year, d.month, d.day + 1)
  ) {
    weekdays[Insights.weekdayIndex(d)]++;
  }
  for (final row in grid) {
    for (var c = 0; c < 7; c++) {
      if (weekdays[c] > 0) row[c] = row[c] / weekdays[c];
    }
  }
  return grid;
}

/// Refused and cancelled orders by reason, most frequent first.
List<(String, int)> reasons(
  Iterable<OwnerOrder> all,
  DateTime from,
  DateTime to,
  String Function(String reason) label,
) {
  final count = <String, int>{};
  for (final o in all) {
    if (!_inside(o, from, to)) continue;
    if (o.status != 'rejected' && o.status != 'cancelled') continue;
    final r = label((o.rejectReason ?? '').trim());
    count[r] = (count[r] ?? 0) + 1;
  }
  return count.entries.map((e) => (e.key, e.value)).toList()
    ..sort((a, b) => b.$2.compareTo(a.$2));
}

/// Average preparation minutes per day (null when no order was ready).
List<double?> prepByDay(Iterable<OwnerOrder> all, DateTime from, DateTime to) {
  final sum = <DateTime, int>{};
  final n = <DateTime, int>{};
  for (final o in all) {
    if (!_inside(o, from, to) || o.acceptedAt == null || o.readyAt == null) {
      continue;
    }
    final d = DateTime(o.placedAt.year, o.placedAt.month, o.placedAt.day);
    sum[d] = (sum[d] ?? 0) + o.readyAt!.difference(o.acceptedAt!).inSeconds;
    n[d] = (n[d] ?? 0) + 1;
  }
  return [
    for (
      var d = DateTime(from.year, from.month, from.day);
      d.isBefore(to);
      d = DateTime(d.year, d.month, d.day + 1)
    )
      n[d] == null ? null : sum[d]! / n[d]! / 60,
  ];
}

/// New vs returning customers over the period.
class CustomerSplit {
  const CustomerSplit({
    required this.newOrders,
    required this.returningOrders,
    required this.customers,
  });

  /// Orders whose customer had never ordered before (in [all]).
  final int newOrders;

  /// Orders from customers who had ordered before.
  final int returningOrders;

  /// Different customers in the period.
  final int customers;
}

/// [all] must reach back before [from] (the look-back decides whether a
/// customer is new). Cancelled-by-nobody orders count too: any order.
CustomerSplit customerSplit(
  Iterable<OwnerOrder> all,
  DateTime from,
  DateTime to,
) {
  final sorted = all.where((o) => o.placedAt.isBefore(to)).toList()
    ..sort((a, b) => a.placedAt.compareTo(b.placedAt));
  final seen = <String>{};
  final inPeriod = <String>{};
  var fresh = 0, back = 0;
  for (final o in sorted) {
    final key = o.customerKey ?? o.customerPhone;
    if (key.isEmpty) continue;
    if (_inside(o, from, to)) {
      seen.contains(key) ? back++ : fresh++;
      inPeriod.add(key);
    }
    seen.add(key);
  }
  return CustomerSplit(
    newOrders: fresh,
    returningOrders: back,
    customers: inPeriod.length,
  );
}

/// Orders per neighbourhood, most first.
List<(String, int)> topAreas(
  Iterable<OwnerOrder> all,
  DateTime from,
  DateTime to, {
  int limit = 6,
}) {
  final count = <String, int>{};
  for (final o in all) {
    if (!_inside(o, from, to) || o.area.trim().isEmpty) continue;
    final a = o.area.trim();
    count[a] = (count[a] ?? 0) + 1;
  }
  final list = count.entries.map((e) => (e.key, e.value)).toList()
    ..sort((a, b) => b.$2.compareTo(a.$2));
  return list.take(limit).toList();
}

/// "Previous month" for reports: the whole calendar month before [now].
(DateTime, DateTime) previousMonth(DateTime now) =>
    (DateTime(now.year, now.month - 1), DateTime(now.year, now.month));

/// Daily CSV of the period: date, orders, delivered, sales, commission, net.
String dailyCsv(Insights i, List<OwnerOrder> rows, List<String> header) {
  final b = StringBuffer(header.join(';'));
  for (final d in i.days) {
    final next = DateTime(d.day.year, d.day.month, d.day.day + 1);
    final day = rows.where((o) => _inside(o, d.day, next));
    final done = day.where((o) => o.status == 'delivered');
    final sales = done.fold<int>(0, (s, o) => s + o.foodTotal);
    final com = done.fold<int>(0, (s, o) => s + (o.commissionAmount ?? 0));
    final date =
        '${d.day.year}-${'${d.day.month}'.padLeft(2, '0')}-'
        '${'${d.day.day}'.padLeft(2, '0')}';
    b.write(
      '\r\n$date;${day.length};${done.length};$sales;$com;${sales - com}',
    );
  }
  return b.toString();
}
