import 'dart:typed_data';

import 'package:intl/intl.dart' show DateFormat;
import 'package:pdf/widgets.dart' as pw;

import '../../core/pdf/receipt_pdf.dart';
import '../../l10n/app_localizations.dart';
import '../admin/data/admin_models.dart' show AdminConfig;
import 'data/orders_repository.dart';

/// The customer's receipt for a delivered order.
Future<Uint8List> buildOrderReceipt({
  required CustomerOrder order,
  required String customerName,
  required AdminConfig business,
  required AppLocalizations l,
  required String lang,
  required PdfFonts fonts,
}) {
  final o = order;
  final when = DateFormat('dd/MM/yyyy HH:mm');
  return buildReceiptPdf(
    ReceiptDoc(
      title: l.receiptOrderTitle,
      business: business,
      taxIdLabel: l.taxIdShort,
      meta: [
        (l.receiptOrderNo, '#${o.code}'),
        (l.receiptDate, when.format(o.placedAt)),
        if (o.deliveredAt != null)
          (l.receiptDeliveredOn, when.format(o.deliveredAt!)),
      ],
      partyTitle: l.receiptCustomer,
      partyName: customerName,
      partyLines: [
        [o.addressText, o.area].where((x) => x.isNotEmpty).join(', '),
        o.customerPhone,
        '${l.restaurant} : ${o.restaurantName}',
        if (o.driverName != null) '${l.receiptDeliveredBy} : ${o.driverName}',
      ],
      table: ReceiptTable(
        headers: [l.receiptItem, l.receiptQty, l.receiptUnit, l.receiptAmount],
        rows: [
          for (final i in o.items)
            [
              i.name,
              '${i.quantity}',
              pdfMoney(i.unitPrice),
              pdfMoney(i.lineTotal),
            ],
        ],
        widths: const [
          pw.FlexColumnWidth(3),
          pw.FixedColumnWidth(40),
          pw.FlexColumnWidth(1.3),
          pw.FlexColumnWidth(1.3),
        ],
        numericColumns: const {1, 2, 3},
      ),
      totals: [
        (l.subtotal, pdfMoney(o.foodTotal)),
        (l.deliveryFee, pdfMoney(o.deliveryFee)),
      ],
      highlight: (l.receiptTotalPaid, pdfMoney(o.total)),
      note: l.receiptPaidCash,
      footer: l.receiptFooter,
      pageLabel: l.receiptPage,
    ),
    lang: lang,
    fonts: fonts,
  );
}
