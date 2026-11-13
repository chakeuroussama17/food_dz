import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../features/admin/data/admin_models.dart' show AdminConfig;
import '../../features/admin/statement_pdf.dart' show PdfFonts;
import '../utils/money.dart';

export '../../features/admin/statement_pdf.dart' show PdfFonts;

/// "1 250 DA" in every language: the pdf package reverses Arabic letters
/// mixed with digits, and the fonts have no narrow no-break space.
String pdfMoney(int v) =>
    formatDzd(v, 'fr').replaceAll(' ', ' ').replaceAll(' ', ' ');

final _arabic = RegExp(r'[؀-ۿ]');

/// The pdf package reverses whole runs in right-to-left mode, digits and
/// Latin text included, so text without Arabic letters is laid out
/// left-to-right even inside an Arabic document.
pw.TextDirection _dirOf(String s) =>
    _arabic.hasMatch(s) ? pw.TextDirection.rtl : pw.TextDirection.ltr;

pw.Widget _t(String s, pw.TextStyle style) =>
    pw.Text(s, style: style, textDirection: _dirOf(s));

class ReceiptTable {
  const ReceiptTable({
    required this.headers,
    required this.rows,
    required this.widths,
    this.numericColumns = const {},
  });

  final List<String> headers;
  final List<List<String>> rows;
  final List<pw.TableColumnWidth> widths;

  /// Right-aligned (left in Arabic) columns.
  final Set<int> numericColumns;
}

/// Everything a receipt shows, already translated.
class ReceiptDoc {
  const ReceiptDoc({
    required this.title,
    required this.business,
    required this.taxIdLabel,
    required this.meta,
    required this.partyTitle,
    required this.partyName,
    required this.table,
    required this.totals,
    required this.highlight,
    required this.footer,
    required this.pageLabel,
    this.partyLines = const [],
    this.note,
  });

  final String title;
  final AdminConfig business;
  final String taxIdLabel;

  /// Label / value pairs under the title (number, date, period…).
  final List<(String, String)> meta;
  final String partyTitle;
  final String partyName;
  final List<String> partyLines;
  final ReceiptTable table;

  /// Label / value lines above the orange box.
  final List<(String, String)> totals;

  /// The orange box: the amount that matters.
  final (String, String) highlight;

  /// Small line under the totals ("Paid in cash on delivery").
  final String? note;
  final String footer;
  final String pageLabel;
}

/// A4 receipt in [lang] ('fr', 'ar', 'en').
Future<Uint8List> buildReceiptPdf(
  ReceiptDoc d, {
  required String lang,
  required PdfFonts fonts,
}) async {
  final rtl = lang == 'ar';
  const orange = PdfColor.fromInt(0xFFFF7622);
  const ink = PdfColor.fromInt(0xFF181C2E);
  const muted = PdfColor.fromInt(0xFF646982);
  const line = PdfColor.fromInt(0xFFE5E7EB);
  const soft = PdfColor.fromInt(0xFFF6F8FA);
  const small = pw.TextStyle(fontSize: 10, color: muted);
  const body = pw.TextStyle(fontSize: 10, color: ink);
  final bodyBold = pw.TextStyle(
    fontSize: 10,
    color: ink,
    fontWeight: pw.FontWeight.bold,
  );

  final theme = pw.ThemeData.withFont(
    base: rtl ? fonts.arabic : fonts.regular,
    bold: rtl ? fonts.arabicBold : fonts.bold,
    fontFallback: rtl ? [fonts.regular] : [fonts.arabic],
  );

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

  // Table: pw.Table ignores right-to-left, so mirror the columns ourselves.
  final tb = d.table;
  List<T> ordered<T>(List<T> xs) => rtl ? xs.reversed.toList() : xs;
  pw.Widget cell(String text, int col, {bool header = false}) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
    child: pw.Align(
      alignment: tb.numericColumns.contains(col)
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
  final table = pw.Table(
    columnWidths: ordered(tb.widths).asMap(),
    children: [
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: ink),
        children: ordered([
          for (var c = 0; c < tb.headers.length; c++)
            cell(tb.headers[c], c, header: true),
        ]),
      ),
      for (var i = 0; i < tb.rows.length; i++)
        pw.TableRow(
          decoration: i.isOdd ? const pw.BoxDecoration(color: soft) : null,
          children: ordered([
            for (var c = 0; c < tb.rows[i].length; c++) cell(tb.rows[i][c], c),
          ]),
        ),
    ],
  );

  final b = d.business;
  final businessLines = [
    b.businessAddress,
    b.businessPhone,
    b.businessEmail,
  ].where((x) => x.isNotEmpty).toList();

  final doc = pw.Document(title: d.title, author: b.businessName);
  doc.addPage(
    pw.MultiPage(
      theme: theme,
      textDirection: rtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
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
                  d.footer,
                  const pw.TextStyle(fontSize: 8, color: muted),
                ),
              ),
              pw.SizedBox(width: 12),
              _t(d.pageLabel, const pw.TextStyle(fontSize: 8, color: muted)),
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
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _t(
                    b.businessName.isEmpty ? 'foodfennec' : b.businessName,
                    pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: orange,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  for (final x in businessLines) _t(x, small),
                  if (b.businessTaxId.isNotEmpty)
                    kv(d.taxIdLabel, b.businessTaxId),
                ],
              ),
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                _t(
                  d.title.toUpperCase(),
                  pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: ink,
                  ),
                ),
                pw.SizedBox(height: 6),
                for (var i = 0; i < d.meta.length; i++)
                  kv(d.meta[i].$1, d.meta[i].$2, strong: i == 0),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 24),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: soft,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _t(d.partyTitle, const pw.TextStyle(fontSize: 9, color: muted)),
              pw.SizedBox(height: 4),
              _t(
                d.partyName,
                pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: ink,
                ),
              ),
              for (final x in d.partyLines.where((x) => x.isNotEmpty))
                _t(x, small),
            ],
          ),
        ),
        pw.SizedBox(height: 20),
        table,
        pw.SizedBox(height: 16),
        pw.Row(
          children: [
            pw.Spacer(),
            pw.SizedBox(
              width: 260,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  for (final (k, v) in d.totals) totalRow(k, v),
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
                            d.highlight.$1,
                            pw.TextStyle(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                            ),
                          ),
                        ),
                        _t(
                          d.highlight.$2,
                          pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (d.note != null) ...[
                    pw.SizedBox(height: 8),
                    _t(d.note!, small),
                  ],
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
