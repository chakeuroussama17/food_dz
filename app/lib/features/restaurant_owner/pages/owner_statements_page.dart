import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../core/pdf/pdf_output.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/snack.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../admin/data/admin_models.dart' show StatementSummary;
import '../../admin/statement_pdf.dart';
import '../data/owner_orders_repository.dart';

/// The restaurant's commission statements (issued by the admin), with the
/// same PDF the admin has.
class OwnerStatementsPage extends ConsumerStatefulWidget {
  const OwnerStatementsPage({super.key});

  @override
  ConsumerState<OwnerStatementsPage> createState() =>
      _OwnerStatementsPageState();
}

class _OwnerStatementsPageState extends ConsumerState<OwnerStatementsPage> {
  String? _busy;

  Future<void> _pdf(StatementSummary s, {required bool print}) async {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    setState(() => _busy = s.id);
    try {
      final d = await ref
          .read(ownerOrdersRepositoryProvider)
          .statementDetail(s.id);
      final bytes = await buildStatementPdf(
        d,
        lang: lang,
        fonts: await PdfFonts.fromAssets(),
      );
      final out = ref.read(pdfOutputProvider);
      if (print) {
        await out.print(bytes, s.number);
      } else {
        await out.download(bytes, '${s.number}.pdf');
      }
    } catch (_) {
      if (mounted) showAppSnack(context, l.errGeneric, error: true);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final list = ref.watch(ownerStatementsProvider);
    final day = DateFormat('dd/MM/yyyy');
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              children: [
                PageHeader(title: l.myStatements),
                Expanded(
                  child: list.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                    error: (_, _) => Center(
                      child: TextButton(
                        onPressed: () =>
                            ref.invalidate(ownerStatementsProvider),
                        child: Text(l.retry),
                      ),
                    ),
                    data: (items) => items.isEmpty
                        ? Center(
                            child: Text(
                              l.noReceipts,
                              style: TextStyle(color: AppColors.body),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                            itemCount: items.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (_, i) {
                              final s = items[i];
                              final paid = s.status == 'paid';
                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            s.number,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 16,
                                              color: AppColors.ink,
                                            ),
                                          ),
                                        ),
                                        Pill(
                                          paid ? l.statusPaid : l.statusUnpaid,
                                          color: paid
                                              ? AppColors.success
                                              : AppColors.primary,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${day.format(s.periodStart)} - '
                                      '${day.format(s.periodEnd)} · '
                                      '${l.ordersCount(s.ordersCount)}',
                                      style: TextStyle(color: AppColors.body),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${l.commissionDue} : '
                                      '${formatDzd(s.amountDue, lang)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 12,
                                      runSpacing: 8,
                                      children: [
                                        AppButton(
                                          label: l.downloadPdf,
                                          icon: Icons.download_rounded,
                                          variant: AppButtonVariant.small,
                                          loading: _busy == s.id,
                                          onPressed: _busy == null
                                              ? () => _pdf(s, print: false)
                                              : null,
                                        ),
                                        AppButton(
                                          label: l.printPdf,
                                          icon: Icons.print_outlined,
                                          variant: AppButtonVariant.outline,
                                          onPressed: _busy == null
                                              ? () => _pdf(s, print: true)
                                              : null,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
