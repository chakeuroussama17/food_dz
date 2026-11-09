import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

/// Where PDFs go: a download (web) / share sheet (mobile), or the printer.
/// Overridden in tests.
abstract interface class PdfOutput {
  Future<void> download(Uint8List bytes, String filename);
  Future<void> print(Uint8List bytes, String name);
}

class PrintingPdfOutput implements PdfOutput {
  @override
  Future<void> download(Uint8List bytes, String filename) =>
      Printing.sharePdf(bytes: bytes, filename: filename);

  @override
  Future<void> print(Uint8List bytes, String name) =>
      Printing.layoutPdf(onLayout: (_) async => bytes, name: name);
}

final pdfOutputProvider = Provider<PdfOutput>((ref) => PrintingPdfOutput());
