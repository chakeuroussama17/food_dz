import 'dart:convert';
import 'dart:typed_data';

import 'package:intl/intl.dart' show DateFormat;

import '../../../l10n/app_localizations.dart';
import '../../orders/order_status.dart';
import '../data/owner_orders_repository.dart';

/// The orders table as a CSV file that opens directly in Excel (French /
/// Arabic Windows): ";" separators, UTF-8 with a BOM, plain numbers in DA.
String ordersCsv(List<OwnerOrder> orders, AppLocalizations l) {
  final day = DateFormat('yyyy-MM-dd');
  final time = DateFormat('HH:mm');
  final rows = <List<Object?>>[
    [
      l.csvCode,
      l.csvDate,
      l.csvTime,
      l.csvStatus,
      l.csvCustomer,
      l.csvArea,
      l.csvItems,
      l.csvItemCount,
      l.csvFood,
      l.csvDeliveryFee,
      l.csvTotal,
      l.csvCommission,
      l.csvNet,
      l.csvDriver,
      l.csvPrepMinutes,
      l.csvReason,
    ],
    for (final o in orders)
      [
        o.code,
        day.format(o.placedAt),
        time.format(o.placedAt),
        orderStatusLabel(l, o.status),
        o.customerName,
        o.area,
        o.items.map((i) => '${i.quantity}x ${i.name}').join(' + '),
        o.items.fold<int>(0, (s, i) => s + i.quantity),
        o.foodTotal,
        o.deliveryFee,
        o.total,
        o.status == 'delivered' ? (o.commissionAmount ?? 0) : '',
        o.status == 'delivered' ? o.net : '',
        o.driverName ?? '',
        o.acceptedAt != null && o.readyAt != null
            ? o.readyAt!.difference(o.acceptedAt!).inMinutes
            : '',
        o.rejectReason == null ? '' : rejectReasonText(l, o.rejectReason!),
      ],
  ];
  return rows.map((r) => r.map(_cell).join(';')).join('\r\n');
}

String _cell(Object? v) {
  final s = '${v ?? ''}';
  // Quote when needed; a leading = + - @ would run as a formula in Excel.
  final safe = RegExp(r'^[=+\-@]').hasMatch(s) && v is String ? "'$s" : s;
  return safe.contains(RegExp('[;"\n\r]'))
      ? '"${safe.replaceAll('"', '""')}"'
      : safe;
}

/// UTF-8 bytes with a BOM (so Excel shows Arabic and accents right).
Uint8List csvBytes(String csv) =>
    Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(csv)]);
