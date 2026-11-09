import 'dart:typed_data';

import 'package:intl/intl.dart' show DateFormat;
import 'package:pdf/widgets.dart' as pw;

import '../../core/pdf/receipt_pdf.dart';
import '../../l10n/app_localizations.dart';
import '../admin/data/admin_models.dart' show AdminConfig;
import 'data/driver_repository.dart';

enum DriverPeriod { thisWeek, lastWeek, thisMonth, lastMonth }

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

/// Inclusive date range for [p] (weeks start on Saturday, as in Algeria).
(DateTime, DateTime) driverPeriodRange(DriverPeriod p, DateTime now) {
  final today = _day(now);
  // DateTime.saturday == 6: days since the last Saturday.
  final sinceSat = (today.weekday - DateTime.saturday) % 7;
  final weekStart = today.subtract(Duration(days: sinceSat));
  return switch (p) {
    DriverPeriod.thisWeek => (weekStart, today),
    DriverPeriod.lastWeek => (
      weekStart.subtract(const Duration(days: 7)),
      weekStart.subtract(const Duration(days: 1)),
    ),
    DriverPeriod.thisMonth => (DateTime(today.year, today.month), today),
    DriverPeriod.lastMonth => (
      DateTime(today.year, today.month - 1),
      DateTime(today.year, today.month, 0),
    ),
  };
}

/// Totals of a driver statement.
class DriverTotals {
  DriverTotals(List<StatementDelivery> d)
    : count = d.length,
      collected = d.fold(0, (s, x) => s + x.total),
      toRestaurants = d.fold(0, (s, x) => s + x.foodTotal),
      earned = d.fold(0, (s, x) => s + x.deliveryFee),
      stillToGive = d
          .where((x) => !x.cashConfirmed)
          .fold(0, (s, x) => s + x.foodTotal);

  final int count;
  final int collected;
  final int toRestaurants;
  final int earned;
  final int stillToGive;
}

Future<Uint8List> buildDriverStatement({
  required List<StatementDelivery> deliveries,
  required DateTime from,
  required DateTime to,
  required String driverName,
  required String driverPhone,
  required AdminConfig business,
  required AppLocalizations l,
  required String lang,
  required PdfFonts fonts,
}) {
  final day = DateFormat('dd/MM/yyyy');
  final when = DateFormat('dd/MM HH:mm');
  final t = DriverTotals(deliveries);
  return buildReceiptPdf(
    ReceiptDoc(
      title: l.driverStatementTitle,
      business: business,
      taxIdLabel: l.taxIdShort,
      meta: [
        (l.receiptPeriod, '${day.format(from)} - ${day.format(to)}'),
        (l.receiptDate, day.format(DateTime.now())),
      ],
      partyTitle: l.stDriver,
      partyName: driverName,
      partyLines: [driverPhone],
      table: ReceiptTable(
        headers: [
          l.receiptOrderNo,
          l.receiptDate,
          l.restaurant,
          l.stCollected,
          l.stToRestaurant,
          l.stFee,
          l.stMoney,
        ],
        rows: [
          for (final x in deliveries)
            [
              x.code,
              when.format(x.deliveredAt),
              x.restaurantName,
              pdfMoney(x.total),
              pdfMoney(x.foodTotal),
              pdfMoney(x.deliveryFee),
              x.cashConfirmed ? l.stConfirmed : l.stOpen,
            ],
        ],
        widths: const [
          pw.FlexColumnWidth(1.1),
          pw.FlexColumnWidth(1.1),
          pw.FlexColumnWidth(1.6),
          pw.FlexColumnWidth(1.1),
          pw.FlexColumnWidth(1.1),
          pw.FlexColumnWidth(0.9),
          pw.FlexColumnWidth(0.9),
        ],
        numericColumns: const {3, 4, 5},
      ),
      totals: [
        (l.stDeliveries, '${t.count}'),
        (l.stTotalCollected, pdfMoney(t.collected)),
        (l.stTotalToRestaurants, pdfMoney(t.toRestaurants)),
        (l.stStillToGive, pdfMoney(t.stillToGive)),
      ],
      highlight: (l.stEarned, pdfMoney(t.earned)),
      footer: l.receiptFooter,
      pageLabel: l.receiptPage,
    ),
    lang: lang,
    fonts: fonts,
  );
}
