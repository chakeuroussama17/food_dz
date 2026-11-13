import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../admin/statement_pdf.dart' show PdfFonts;

final _arabic = RegExp(r'[؀-ۿ]');

/// A4 poster to stick on the shop window, the counter or the tables:
/// the foodfennec header, the QR code with the fennec in the middle, the
/// restaurant's name below it, "scan to order" in the three languages, and the
/// link for people who prefer to type it.
Future<Uint8List> buildQrPosterPdf({
  required String name,
  required String link,
  required PdfFonts fonts,
}) async {
  final mark = pw.MemoryImage(
    (await rootBundle.load('assets/brand/mark.png')).buffer.asUint8List(),
  );
  final fox = pw.MemoryImage(
    (await rootBundle.load('assets/brand/fox_white.png')).buffer.asUint8List(),
  );
  final word = pw.MemoryImage(
    (await rootBundle.load(
      'assets/brand/wordmark_white.png',
    )).buffer.asUint8List(),
  );

  const orange = PdfColor.fromInt(0xFFFF7622);
  const ink = PdfColor.fromInt(0xFF121223);
  const muted = PdfColor.fromInt(0xFF7A7A8C);

  pw.Widget text(
    String s,
    double size, {
    bool bold = false,
    PdfColor color = ink,
  }) {
    final ar = _arabic.hasMatch(s);
    return pw.Text(
      s,
      textAlign: pw.TextAlign.center,
      textDirection: ar ? pw.TextDirection.rtl : pw.TextDirection.ltr,
      style: pw.TextStyle(
        font: ar
            ? (bold ? fonts.arabicBold : fonts.arabic)
            : (bold ? fonts.bold : fonts.regular),
        fontFallback: [bold ? fonts.arabicBold : fonts.arabic],
        fontSize: size,
        color: color,
      ),
    );
  }

  const qrSize = 300.0;
  final doc = pw.Document(title: name, author: 'foodfennec');
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (_) => pw.Column(
        children: [
          // Orange header with the white fox and name.
          pw.Container(
            width: double.infinity,
            color: orange,
            padding: const pw.EdgeInsets.symmetric(vertical: 34),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Image(fox, height: 54),
                pw.SizedBox(width: 16),
                pw.Image(word, height: 36),
              ],
            ),
          ),
          pw.SizedBox(height: 56),
          pw.Container(
            padding: const pw.EdgeInsets.all(22),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: orange, width: 3),
              borderRadius: pw.BorderRadius.circular(24),
            ),
            child: pw.Stack(
              alignment: pw.Alignment.center,
              children: [
                pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(
                    errorCorrectLevel: pw.BarcodeQRCorrectionLevel.high,
                  ),
                  data: link,
                  width: qrSize,
                  height: qrSize,
                  color: ink,
                  drawText: false,
                ),
                pw.Container(
                  width: qrSize * 0.26,
                  height: qrSize * 0.26,
                  padding: const pw.EdgeInsets.all(5),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: pw.BorderRadius.circular(16),
                  ),
                  child: pw.Image(mark),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 26),
          // The restaurant's name, below the code.
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 48),
            child: text(name, 34, bold: true),
          ),
          pw.SizedBox(height: 18),
          text('Scannez pour commander', 22, bold: true, color: orange),
          pw.SizedBox(height: 6),
          text('امسح الرمز للطلب', 20, bold: true, color: orange),
          pw.SizedBox(height: 6),
          text('Scan to order', 16, color: ink),
          pw.Spacer(),
          text(link.replaceFirst(RegExp(r'\?.*$'), ''), 12, color: muted),
          pw.SizedBox(height: 28),
        ],
      ),
    ),
  );
  return doc.save();
}
