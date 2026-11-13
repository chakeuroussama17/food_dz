import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/utils/money.dart';
import 'data/admin_models.dart';

/// Labels printed on the statement, per language.
class StatementLabels {
  const StatementLabels({
    required this.title,
    required this.number,
    required this.issued,
    required this.period,
    required this.billedTo,
    required this.order,
    required this.deliveredOn,
    required this.foodTotal,
    required this.rate,
    required this.commission,
    required this.ordersCount,
    required this.totalFood,
    required this.amountDue,
    required this.tax,
    required this.discounts,
    required this.paid,
    required this.unpaid,
    required this.footer,
    required this.taxId,
    required this.page,
  });

  final String title;
  final String number;
  final String issued;
  final String period;
  final String billedTo;
  final String order;
  final String deliveredOn;
  final String foodTotal;
  final String rate;
  final String commission;
  final String ordersCount;
  final String totalFood;
  final String amountDue;
  final String tax;
  final String discounts;
  final String paid;
  final String unpaid;
  final String footer;
  final String taxId;
  final String page;

  static StatementLabels of(String lang) => switch (lang) {
    'ar' => const StatementLabels(
      title: 'كشف العمولة',
      number: 'رقم الكشف',
      issued: 'تاريخ الإصدار',
      period: 'الفترة',
      billedTo: 'إلى',
      order: 'الطلب',
      deliveredOn: 'تاريخ التوصيل',
      foodTotal: 'مبلغ الطعام',
      rate: 'النسبة',
      commission: 'العمولة',
      ordersCount: 'عدد الطلبات المسلّمة',
      totalFood: 'مجموع مبيعات الطعام',
      amountDue: 'المبلغ المستحق',
      tax: 'الضريبة المحصلة',
      discounts: 'خصومات تتحملها المنصة',
      paid: 'مدفوع',
      unpaid: 'غير مدفوع',
      footer:
          'المبالغ بالدينار الجزائري. العمولة محسوبة على مبلغ الطعام فقط، دون رسوم التوصيل.',
      taxId: 'الرقم الجبائي',
      page: 'صفحة',
    ),
    'en' => const StatementLabels(
      title: 'Commission statement',
      number: 'Statement no.',
      issued: 'Issued on',
      period: 'Period',
      billedTo: 'Billed to',
      order: 'Order',
      deliveredOn: 'Delivered on',
      foodTotal: 'Food total',
      rate: 'Rate',
      commission: 'Commission',
      ordersCount: 'Delivered orders',
      totalFood: 'Total food sales',
      amountDue: 'Amount due',
      tax: 'Tax collected',
      discounts: 'Discounts paid by the platform',
      paid: 'PAID',
      unpaid: 'UNPAID',
      footer:
          'Amounts in Algerian dinars (DA). Commission is calculated on the food total only, excluding delivery fees.',
      taxId: 'Tax ID',
      page: 'Page',
    ),
    _ => const StatementLabels(
      title: 'Relevé de commission',
      number: 'Relevé n°',
      issued: 'Émis le',
      period: 'Période',
      billedTo: 'Facturé à',
      order: 'Commande',
      deliveredOn: 'Livrée le',
      foodTotal: 'Montant repas',
      rate: 'Taux',
      commission: 'Commission',
      ordersCount: 'Commandes livrées',
      totalFood: 'Total des ventes (repas)',
      amountDue: 'Montant dû',
      tax: 'Taxe collectée',
      discounts: 'Réductions payées par la plateforme',
      paid: 'PAYÉ',
      unpaid: 'NON PAYÉ',
      footer:
          'Montants en dinars algériens (DA). La commission est calculée uniquement sur le montant des repas, hors frais de livraison.',
      taxId: 'NIF',
      page: 'Page',
    ),
  };
}

/// Fonts embedded in the PDF (Latin + Arabic).
class PdfFonts {
  const PdfFonts({
    required this.regular,
    required this.bold,
    required this.arabic,
    required this.arabicBold,
  });
  final pw.Font regular;
  final pw.Font bold;
  final pw.Font arabic;
  final pw.Font arabicBold;

  static Future<PdfFonts> fromAssets() async {
    Future<pw.Font> f(String name) async =>
        pw.Font.ttf(await rootBundle.load('assets/fonts/$name'));
    return PdfFonts(
      regular: await f('Sen-400.ttf'),
      bold: await f('Sen-700.ttf'),
      arabic: await f('NotoKufiArabic-400.ttf'),
      arabicBold: await f('NotoKufiArabic-700.ttf'),
    );
  }
}

String _pct(double rate) {
  final p = (rate * 1000).round() / 10;
  return '${p == p.roundToDouble() ? p.toStringAsFixed(0) : p.toStringAsFixed(1)} %';
}

final _arabic = RegExp(r'[؀-ۿ]');

/// Direction for one piece of text. The pdf package reverses whole runs in
/// right-to-left mode (digits and Latin included), so anything without
/// Arabic letters (numbers, codes, dates, Latin names) is laid out
/// left-to-right, even inside the Arabic statement.
pw.TextDirection _dirOf(String s) =>
    _arabic.hasMatch(s) ? pw.TextDirection.rtl : pw.TextDirection.ltr;

pw.Widget _t(String s, pw.TextStyle style) =>
    pw.Text(s, style: style, textDirection: _dirOf(s));

/// Builds the commission statement PDF (A4) in [lang] ('fr', 'ar', 'en').
Future<Uint8List> buildStatementPdf(
  StatementDetail d, {
  required String lang,
  required PdfFonts fonts,
}) async {
  final l = StatementLabels.of(lang);
  final rtl = lang == 'ar';
  final dir = rtl ? pw.TextDirection.rtl : pw.TextDirection.ltr;
  // Latin digits, no locale data needed (Algerian documents use them).
  final dateFmt = DateFormat('dd/MM/yyyy');
  // "1 250 DA" in every language: plain spaces (the fonts have no narrow
  // no-break space) and the Latin unit (Arabic letters mixed with digits
  // would be reversed by the pdf package).
  String money(int v) =>
      formatDzd(v, 'fr').replaceAll(' ', ' ').replaceAll(' ', ' ');
  final s = d.statement;

  const orange = PdfColor.fromInt(0xFFFF7622);
  const ink = PdfColor.fromInt(0xFF181C2E);
  const muted = PdfColor.fromInt(0xFF646982);
  const line = PdfColor.fromInt(0xFFE5E7EB);
  const soft = PdfColor.fromInt(0xFFF6F8FA);

  final theme = pw.ThemeData.withFont(
    base: rtl ? fonts.arabic : fonts.regular,
    bold: rtl ? fonts.arabicBold : fonts.bold,
    fontFallback: rtl ? [fonts.regular] : [fonts.arabic],
  );

  const small = pw.TextStyle(fontSize: 10, color: muted);
  const body = pw.TextStyle(fontSize: 10, color: ink);
  final bodyBold = pw.TextStyle(
    fontSize: 10,
    color: ink,
    fontWeight: pw.FontWeight.bold,
  );

  /// "Label : value", each part with its own direction.
  pw.Widget kv(String k, String v, {bool strong = false}) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 2),
    child: pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        _t('$k :', small),
        pw.SizedBox(width: 4),
        _t(v, strong ? bodyBold : body),
      ],
    ),
  );

  pw.Widget totalRow(String k, String v) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 3),
    child: pw.Row(
      children: [
        pw.Expanded(child: _t(k, small)),
        _t(v, body),
      ],
    ),
  );

  final business = d.business;
  final businessLines = [
    business.businessAddress,
    business.businessPhone,
    business.businessEmail,
  ].where((x) => x.isNotEmpty).toList();
  final period =
      '${dateFmt.format(s.periodStart)} - ${dateFmt.format(s.periodEnd)}';

  // Orders table, built cell by cell so each cell gets the right direction.
  final headers = [
    '#',
    l.order,
    l.deliveredOn,
    l.foodTotal,
    l.rate,
    l.commission,
  ];
  const numericCols = {0, 3, 4, 5};
  pw.Widget cell(String text, int col, {bool header = false}) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
    child: pw.Align(
      alignment: numericCols.contains(col)
          ? (rtl ? pw.Alignment.centerLeft : pw.Alignment.centerRight)
          : (rtl ? pw.Alignment.centerRight : pw.Alignment.centerLeft),
      child: _t(
        text,
        header
            ? pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              )
            : const pw.TextStyle(fontSize: 9, color: ink),
      ),
    ),
  );

  // pw.Table ignores right-to-left, so mirror the columns ourselves.
  List<T> ordered<T>(List<T> xs) => rtl ? xs.reversed.toList() : xs;
  const widths = <pw.TableColumnWidth>[
    pw.FixedColumnWidth(24),
    pw.FlexColumnWidth(1.2),
    pw.FlexColumnWidth(1.2),
    pw.FlexColumnWidth(1.2),
    pw.FixedColumnWidth(44),
    pw.FlexColumnWidth(1.1),
  ];
  final table = pw.Table(
    columnWidths: ordered(widths).asMap(),
    children: [
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: ink),
        children: ordered([
          for (var c = 0; c < headers.length; c++)
            cell(headers[c], c, header: true),
        ]),
      ),
      for (var i = 0; i < d.lines.length; i++)
        pw.TableRow(
          decoration: i.isOdd ? const pw.BoxDecoration(color: soft) : null,
          children: ordered([
            cell('${i + 1}', 0),
            cell(d.lines[i].code, 1),
            cell(dateFmt.format(d.lines[i].deliveredAt.toLocal()), 2),
            cell(money(d.lines[i].foodTotal), 3),
            cell(_pct(d.lines[i].commissionRate), 4),
            cell(money(d.lines[i].commissionAmount), 5),
          ]),
        ),
    ],
  );

  final doc = pw.Document(
    title: '${l.title} ${s.number}',
    author: business.businessName,
  );

  doc.addPage(
    pw.MultiPage(
      theme: theme,
      textDirection: dir,
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      footer: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Divider(color: line),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: _t(
                  l.footer,
                  const pw.TextStyle(fontSize: 8, color: muted),
                ),
              ),
              pw.SizedBox(width: 12),
              _t(l.page, const pw.TextStyle(fontSize: 8, color: muted)),
              pw.SizedBox(width: 3),
              _t(
                '${ctx.pageNumber}/${ctx.pagesCount}',
                const pw.TextStyle(fontSize: 8, color: muted),
              ),
            ],
          ),
        ],
      ),
      build: (ctx) => [
        // Header: business on one side, statement info on the other.
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _t(
                    business.businessName.isEmpty
                        ? 'foodfennec'
                        : business.businessName,
                    pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: orange,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  for (final b in businessLines) _t(b, small),
                  if (business.businessTaxId.isNotEmpty)
                    kv(l.taxId, business.businessTaxId),
                ],
              ),
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                _t(
                  l.title.toUpperCase(),
                  pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: ink,
                  ),
                ),
                pw.SizedBox(height: 6),
                kv(l.number, s.number, strong: true),
                kv(l.issued, dateFmt.format(s.issuedAt.toLocal())),
                kv(l.period, period),
                pw.SizedBox(height: 6),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: pw.BoxDecoration(
                    color: s.isPaid
                        ? const PdfColor.fromInt(0xFFDCFCE7)
                        : const PdfColor.fromInt(0xFFFFEDD5),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Row(
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      _t(
                        s.isPaid ? l.paid : l.unpaid,
                        pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: s.isPaid
                              ? const PdfColor.fromInt(0xFF166534)
                              : const PdfColor.fromInt(0xFF9A3412),
                        ),
                      ),
                      if (s.isPaid && s.paidAt != null) ...[
                        pw.SizedBox(width: 4),
                        _t(
                          dateFmt.format(s.paidAt!.toLocal()),
                          const pw.TextStyle(
                            fontSize: 9,
                            color: PdfColor.fromInt(0xFF166534),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 24),

        // Billed to.
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: soft,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _t(l.billedTo, const pw.TextStyle(fontSize: 9, color: muted)),
              pw.SizedBox(height: 4),
              _t(
                d.restaurantName,
                pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: ink,
                ),
              ),
              for (final x in [
                d.ownerName,
                d.restaurantAddress,
                d.restaurantPhone,
                d.ownerEmail,
              ].where((x) => x.isNotEmpty))
                _t(x, small),
            ],
          ),
        ),
        pw.SizedBox(height: 20),
        table,
        pw.SizedBox(height: 16),

        // Totals.
        pw.Row(
          children: [
            pw.Spacer(),
            pw.SizedBox(
              width: 260,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  totalRow(l.ordersCount, '${s.ordersCount}'),
                  totalRow(l.totalFood, money(s.foodTotal)),
                  totalRow(l.commission, money(s.commissionTotal)),
                  if (s.taxTotal > 0) totalRow(l.tax, money(s.taxTotal)),
                  if (s.discountTotal > 0)
                    totalRow(l.discounts, '- ${money(s.discountTotal)}'),
                  pw.SizedBox(height: 6),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: orange,
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Row(
                      children: [
                        pw.Expanded(
                          child: _t(
                            l.amountDue,
                            pw.TextStyle(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                            ),
                          ),
                        ),
                        _t(
                          money(s.amountDue),
                          pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
  return doc.save();
}
