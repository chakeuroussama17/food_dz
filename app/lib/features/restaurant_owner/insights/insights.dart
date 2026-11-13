import '../data/owner_orders_repository.dart';

/// One day of the sales chart.
class DayPoint {
  const DayPoint(this.day, this.sales, this.orders);
  final DateTime day;
  final int sales;
  final int orders;
}

/// A dish in the ranking (delivered orders only).
class DishStat {
  const DishStat(this.name, this.quantity, this.sales);
  final String name;
  final int quantity;
  final int sales;
}

/// Numbers of a period, computed from the report rows. Money is the food
/// total (what the restaurant earns before commission); the delivery fee
/// belongs to the driver.
class Insights {
  const Insights({
    required this.from,
    required this.to,
    required this.orders,
    required this.delivered,
    required this.rejected,
    required this.cancelled,
    required this.inProgress,
    required this.accepted,
    required this.sales,
    required this.commission,
    required this.lostSales,
    required this.days,
    required this.byHour,
    required this.byWeekday,
    required this.topDishes,
    this.avgPrepMinutes,
    this.avgResponseMinutes,
  });

  final DateTime from;
  final DateTime to;

  /// Every order placed in the period.
  final int orders;
  final int delivered;

  /// Refused by the restaurant (or not answered in time).
  final int rejected;
  final int cancelled;
  final int inProgress;

  /// Orders the restaurant accepted (whatever happened after).
  final int accepted;

  /// Food money of delivered orders.
  final int sales;
  final int commission;

  /// Food money of refused orders.
  final int lostSales;

  /// From accepted to ready.
  final int? avgPrepMinutes;

  /// From placed to accepted.
  final double? avgResponseMinutes;

  final List<DayPoint> days;

  /// Orders per hour of the day, 0..23.
  final List<int> byHour;

  /// Orders per day of the week, index 0 = Saturday (the Algerian week).
  final List<int> byWeekday;

  /// Best sellers, most sold first.
  final List<DishStat> topDishes;

  int get net => sales - commission;
  int get avgBasket => delivered == 0 ? 0 : (sales / delivered).round();

  /// Accepted out of answered orders; null when none was answered.
  double? get acceptanceRate {
    final answered = accepted + rejected;
    return answered == 0 ? null : accepted / answered;
  }

  /// Busiest hour, or null without orders.
  int? get peakHour {
    var best = -1, at = 0;
    for (var h = 0; h < 24; h++) {
      if (byHour[h] > best) (best, at) = (byHour[h], h);
    }
    return best <= 0 ? null : at;
  }

  /// Weekday index (0 = Saturday) with the fewest orders.
  int get quietestWeekday {
    var low = 1 << 30, at = 0;
    for (var d = 0; d < 7; d++) {
      if (byWeekday[d] < low) (low, at) = (byWeekday[d], d);
    }
    return at;
  }

  static DateTime _day(DateTime t) => DateTime(t.year, t.month, t.day);

  /// Index 0 = Saturday … 6 = Friday.
  static int weekdayIndex(DateTime t) => (t.weekday + 1) % 7;

  factory Insights.compute(
    Iterable<OwnerOrder> all,
    DateTime from,
    DateTime to,
  ) {
    final list = all
        .where((o) => !o.placedAt.isBefore(from) && o.placedAt.isBefore(to))
        .toList();
    var delivered = 0, rejected = 0, cancelled = 0, inProgress = 0;
    var accepted = 0, sales = 0, commission = 0, lost = 0;
    var prepSum = 0, prepN = 0;
    var respSum = 0, respN = 0;
    final byHour = List.filled(24, 0);
    final byWeekday = List.filled(7, 0);
    final daySales = <DateTime, int>{};
    final dayOrders = <DateTime, int>{};
    final dishes = <String, (int, int)>{};

    for (final o in list) {
      byHour[o.placedAt.hour]++;
      byWeekday[weekdayIndex(o.placedAt)]++;
      final d = _day(o.placedAt);
      dayOrders[d] = (dayOrders[d] ?? 0) + 1;
      if (o.acceptedAt != null) {
        accepted++;
        respSum += o.acceptedAt!.difference(o.placedAt).inSeconds;
        respN++;
        if (o.readyAt != null) {
          prepSum += o.readyAt!.difference(o.acceptedAt!).inSeconds;
          prepN++;
        }
      }
      switch (o.status) {
        case 'delivered':
          delivered++;
          sales += o.foodTotal;
          commission += o.commissionAmount ?? 0;
          daySales[d] = (daySales[d] ?? 0) + o.foodTotal;
          for (final i in o.items) {
            final (q, s) = dishes[i.name] ?? (0, 0);
            dishes[i.name] = (q + i.quantity, s + i.lineTotal);
          }
        case 'rejected':
          rejected++;
          lost += o.foodTotal;
        case 'cancelled':
          cancelled++;
        default:
          inProgress++;
      }
    }

    final days = <DayPoint>[];
    for (
      var d = _day(from);
      d.isBefore(to);
      d = DateTime(d.year, d.month, d.day + 1)
    ) {
      days.add(DayPoint(d, daySales[d] ?? 0, dayOrders[d] ?? 0));
    }
    final top =
        [
          for (final e in dishes.entries)
            DishStat(e.key, e.value.$1, e.value.$2),
        ]..sort((a, b) {
          final c = b.quantity.compareTo(a.quantity);
          return c != 0 ? c : b.sales.compareTo(a.sales);
        });

    return Insights(
      from: from,
      to: to,
      orders: list.length,
      delivered: delivered,
      rejected: rejected,
      cancelled: cancelled,
      inProgress: inProgress,
      accepted: accepted,
      sales: sales,
      commission: commission,
      lostSales: lost,
      days: days,
      byHour: byHour,
      byWeekday: byWeekday,
      topDishes: top,
      avgPrepMinutes: prepN == 0 ? null : (prepSum / prepN / 60).round(),
      avgResponseMinutes: respN == 0 ? null : respSum / respN / 60,
    );
  }
}

/// Change from [before] to [now] in percent; null when there was nothing
/// before (no meaningful percentage).
double? percentChange(num now, num before) =>
    before == 0 ? null : (now - before) * 100 / before;

/// Advice cards on the trends page, most useful first.
enum TipKind {
  salesUp,
  salesDown,
  peakHour,
  topDish,
  refusals,
  slowResponse,
  slowPrep,
  quietDay,
  noOrders,
}

class Tip {
  const Tip(this.kind, {this.number = 0, this.text = '', this.amount = 0});
  final TipKind kind;

  /// Percent, hour, minutes or weekday index depending on [kind].
  final num number;

  /// A dish name.
  final String text;

  /// Money (DA).
  final int amount;
}

/// Business advice from the period [now] compared with [before].
/// [announcedPrep] is the preparation time shown to customers.
List<Tip> tipsFor(Insights now, Insights before, {int announcedPrep = 20}) {
  if (now.orders == 0) return const [Tip(TipKind.noOrders)];
  final tips = <Tip>[];

  final change = percentChange(now.sales, before.sales);
  if (change != null && change >= 10) {
    tips.add(Tip(TipKind.salesUp, number: change.round()));
  } else if (change != null && change <= -10) {
    tips.add(Tip(TipKind.salesDown, number: -change.round()));
  }

  final rate = now.acceptanceRate;
  if (now.rejected > 0 && rate != null && rate < 0.9) {
    tips.add(
      Tip(TipKind.refusals, number: now.rejected, amount: now.lostSales),
    );
  }

  final resp = now.avgResponseMinutes;
  if (resp != null && resp > 4) {
    tips.add(Tip(TipKind.slowResponse, number: resp.round()));
  }

  final prep = now.avgPrepMinutes;
  if (prep != null && prep > announcedPrep + 5) {
    tips.add(Tip(TipKind.slowPrep, number: prep, amount: announcedPrep));
  }

  final peak = now.peakHour;
  if (peak != null && now.orders >= 5) {
    final share = now.byHour[peak] * 100 / now.orders;
    tips.add(Tip(TipKind.peakHour, number: peak, amount: share.round()));
  }

  if (now.topDishes.isNotEmpty && now.sales > 0) {
    final best = now.topDishes.reduce((a, b) => b.sales > a.sales ? b : a);
    final share = best.sales * 100 / now.sales;
    if (share >= 25 && now.topDishes.length > 1) {
      tips.add(Tip(TipKind.topDish, text: best.name, number: share.round()));
    }
  }

  if (now.orders >= 14 && now.to.difference(now.from).inDays >= 7) {
    tips.add(Tip(TipKind.quietDay, number: now.quietestWeekday));
  }
  return tips;
}
