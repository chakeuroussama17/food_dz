import 'admin_repository.dart';

enum StatsPeriod { today, last7, thisMonth, lastMonth }

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

/// Date range for the dashboard period chips. [now] is local time.
DateRange statsRange(StatsPeriod p, DateTime now) {
  final today = _day(now);
  return switch (p) {
    StatsPeriod.today => DateRange(today, today),
    StatsPeriod.last7 => DateRange(
      today.subtract(const Duration(days: 6)),
      today,
    ),
    StatsPeriod.thisMonth => DateRange(DateTime(now.year, now.month), today),
    StatsPeriod.lastMonth => DateRange(
      DateTime(now.year, now.month - 1),
      DateTime(now.year, now.month, 0), // day 0 = last day of previous month
    ),
  };
}

enum StatementPeriod { previousHalfMonth, lastMonth }

/// Billing periods for commission statements. Only finished periods:
/// * previous half-month: 1st–15th, or 16th–end of month
/// * last month: the whole previous calendar month
DateRange statementRange(StatementPeriod p, DateTime now) {
  switch (p) {
    case StatementPeriod.lastMonth:
      return statsRange(StatsPeriod.lastMonth, now);
    case StatementPeriod.previousHalfMonth:
      if (now.day > 15) {
        return DateRange(
          DateTime(now.year, now.month, 1),
          DateTime(now.year, now.month, 15),
        );
      }
      return DateRange(
        DateTime(now.year, now.month - 1, 16),
        DateTime(now.year, now.month, 0),
      );
  }
}
