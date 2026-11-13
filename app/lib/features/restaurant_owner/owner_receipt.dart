import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:pdf/widgets.dart' as pw;

import '../../core/pdf/business_info.dart';
import '../../core/pdf/pdf_output.dart';
import '../../core/pdf/receipt_pdf.dart';
import '../../core/widgets/snack.dart';
import '../../core/widgets/widgets.dart';
import '../../l10n/app_localizations.dart';
import 'data/owner_orders_repository.dart';
import 'data/owner_repository.dart';

/// Receipt of one delivered order, as the restaurant keeps it: the same
/// order receipt the customer gets (dishes, delivery fee, cash paid).
Future<Uint8List> buildOwnerOrderReceipt({
  required OwnerOrder order,
  required String restaurantName,
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
      partyName: o.customerName,
      partyLines: [
        [o.addressText, o.area].where((x) => x.isNotEmpty).join(', '),
        if (o.customerPhone.isNotEmpty) o.customerPhone,
        '${l.restaurant} : $restaurantName',
        if ((o.driverName ?? '').isNotEmpty)
          '${l.receiptDeliveredBy} : ${o.driverName}',
      ].where((x) => x.isNotEmpty).toList(),
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
        if (o.discountAmount > 0)
          (l.discount, '- ${pdfMoney(o.discountAmount)}'),
        if (o.taxAmount > 0) (l.taxLabel, pdfMoney(o.taxAmount)),
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

/// "Download receipt" / "Print" for a delivered order of the restaurant.
/// Shows nothing for other orders.
class OwnerReceiptButtons extends ConsumerStatefulWidget {
  const OwnerReceiptButtons({super.key, required this.order});
  final OwnerOrder order;

  @override
  ConsumerState<OwnerReceiptButtons> createState() =>
      _OwnerReceiptButtonsState();
}

class _OwnerReceiptButtonsState extends ConsumerState<OwnerReceiptButtons> {
  bool _busy = false;

  Future<void> _go({required bool print}) async {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    setState(() => _busy = true);
    try {
      final o = widget.order;
      final business = await ref.read(businessInfoRepositoryProvider).get();
      final restaurant = await ref.read(myRestaurantProvider.future);
      final bytes = await buildOwnerOrderReceipt(
        order: o,
        restaurantName: restaurant?.name ?? '',
        business: business,
        l: l,
        lang: lang,
        fonts: await PdfFonts.fromAssets(),
      );
      final out = ref.read(pdfOutputProvider);
      final name = 'recu-${o.code}';
      if (print) {
        await out.print(bytes, name);
      } else {
        await out.download(bytes, '$name.pdf');
      }
    } catch (_) {
      if (mounted) showAppSnack(context, l.errGeneric, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.order.status != 'delivered') return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        AppButton(
          label: l.downloadReceipt,
          icon: Icons.download_rounded,
          variant: AppButtonVariant.small,
          loading: _busy,
          onPressed: _busy ? null : () => _go(print: false),
        ),
        AppButton(
          label: l.printAction,
          icon: Icons.print_outlined,
          variant: AppButtonVariant.outline,
          onPressed: _busy ? null : () => _go(print: true),
        ),
      ],
    );
  }
}
