import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:food_app/features/admin/data/admin_models.dart';
import 'package:food_app/features/admin/data/periods.dart';
import 'package:food_app/features/admin/statement_pdf.dart';
import 'package:pdf/widgets.dart' as pw;

PdfFonts _fonts() {
  pw.Font f(String n) => pw.Font.ttf(
    File('assets/fonts/$n').readAsBytesSync().buffer.asByteData(),
  );
  return PdfFonts(
    regular: f('Sen-400.ttf'),
    bold: f('Sen-700.ttf'),
    arabic: f('NotoKufiArabic-400.ttf'),
    arabicBold: f('NotoKufiArabic-700.ttf'),
  );
}

StatementDetail sample({int lines = 3, bool paid = false}) => StatementDetail(
  statement: StatementSummary(
    id: 's1',
    number: 'FD-2026-0001',
    restaurantId: 'r1',
    restaurantName: 'Burger House',
    periodStart: DateTime(2026, 10, 1),
    periodEnd: DateTime(2026, 10, 31),
    ordersCount: lines,
    foodTotal: 1000 * lines,
    commissionTotal: 80 * lines,
    status: paid ? 'paid' : 'issued',
    issuedAt: DateTime(2026, 11, 2),
    paidAt: paid ? DateTime(2026, 11, 5) : null,
  ),
  restaurantName: 'Burger House',
  restaurantAddress: 'Rue Ahmed Ouaked, Hydra',
  ownerName: 'Omar',
  business: const AdminConfig(
    deliveryFee: 200,
    defaultCommissionRate: 0.08,
    businessName: 'Food DZ',
    businessTaxId: 'NIF123',
  ),
  lines: [
    for (var i = 0; i < lines; i++)
      StatementLine(
        code: 'ABC${100 + i}',
        deliveredAt: DateTime(2026, 10, 1 + i % 28),
        foodTotal: 1000,
        commissionRate: 0.08,
        commissionAmount: 80,
      ),
  ],
);

void main() {
  test('statement PDF builds in fr, ar and en, paid and unpaid', () async {
    final fonts = _fonts();
    for (final lang in ['fr', 'ar', 'en']) {
      for (final paid in [false, true]) {
        final bytes = await buildStatementPdf(
          sample(paid: paid),
          lang: lang,
          fonts: fonts,
        );
        expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
        expect(bytes.length, greaterThan(5000));
      }
    }
  });

  test('long statements flow onto several pages', () async {
    final small = await buildStatementPdf(
      sample(lines: 3),
      lang: 'fr',
      fonts: _fonts(),
    );
    final big = await buildStatementPdf(
      sample(lines: 150),
      lang: 'fr',
      fonts: _fonts(),
    );
    final pages = RegExp(
      r'/Type\s*/Page[^s]',
    ).allMatches(String.fromCharCodes(big)).length;
    expect(big.length, greaterThan(small.length));
    expect(pages, greaterThan(1));
  });

  group('periods', () {
    test('dashboard ranges', () {
      final now = DateTime(2026, 3, 10, 14);
      expect(statsRange(StatsPeriod.today, now).start, DateTime(2026, 3, 10));
      expect(statsRange(StatsPeriod.last7, now).start, DateTime(2026, 3, 4));
      expect(
        statsRange(StatsPeriod.thisMonth, now).start,
        DateTime(2026, 3, 1),
      );
      final lm = statsRange(StatsPeriod.lastMonth, now);
      expect(lm.start, DateTime(2026, 2, 1));
      expect(lm.end, DateTime(2026, 2, 28));
    });

    test('statement half-months are always finished periods', () {
      final early = statementRange(
        StatementPeriod.previousHalfMonth,
        DateTime(2026, 3, 10),
      );
      expect(early.start, DateTime(2026, 2, 16));
      expect(early.end, DateTime(2026, 2, 28));
      final late = statementRange(
        StatementPeriod.previousHalfMonth,
        DateTime(2026, 3, 20),
      );
      expect(late.start, DateTime(2026, 3, 1));
      expect(late.end, DateTime(2026, 3, 15));
      final jan = statementRange(
        StatementPeriod.lastMonth,
        DateTime(2026, 1, 5),
      );
      expect(jan.start, DateTime(2025, 12, 1));
      expect(jan.end, DateTime(2025, 12, 31));
    });
  });
}
