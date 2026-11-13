import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../core/pdf/pdf_output.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/money.dart';
import '../../core/widgets/snack.dart';
import '../../core/widgets/widgets.dart';
import '../../features/admin/data/admin_models.dart' show StatementSummary;
import '../../features/admin/statement_pdf.dart';
import '../../features/restaurant_owner/data/owner_orders_repository.dart';
import '../../l10n/app_localizations.dart';
import '../portal_state.dart';
import '../widgets/portal_widgets.dart';

/// Commission statements of the selected outlets, grouped by month, with
/// the PDF to download or print.
class PortalInvoicesPage extends ConsumerStatefulWidget {
  const PortalInvoicesPage({super.key});

  @override
  ConsumerState<PortalInvoicesPage> createState() => _PortalInvoicesPageState();
}

class _PortalInvoicesPageState extends ConsumerState<PortalInvoicesPage> {
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
    final list = ref.watch(portalStatementsProvider);
    final month = DateFormat.yMMMM(lang);
    final day = DateFormat('dd/MM/yyyy');

    return PortalPage(
      title: l.navInvoices,
      subtitle: l.invoicesSubtitle,
      actions: const [OutletSelector()],
      children: [
        list.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(64),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
          error: (_, _) => Center(
            child: TextButton(
              onPressed: () => ref.invalidate(portalStatementsProvider),
              child: Text(l.retry),
            ),
          ),
          data: (items) {
            if (items.isEmpty) {
              return PCard(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.request_quote_outlined,
                        size: 48,
                        color: AppColors.muted,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l.noInvoices,
                        style: TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              );
            }
            final groups = <String, List<StatementSummary>>{};
            for (final s in items) {
              groups.putIfAbsent(month.format(s.issuedAt), () => []).add(s);
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final g in groups.entries) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
                    child: Text(
                      g.key,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                  PCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (var i = 0; i < g.value.length; i++) ...[
                          if (i > 0)
                            Divider(height: 1, color: AppColors.border),
                          _Row(
                            s: g.value[i],
                            busy: _busy == g.value[i].id,
                            enabled: _busy == null,
                            day: day,
                            lang: lang,
                            onPdf: (print) => _pdf(g.value[i], print: print),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.s,
    required this.busy,
    required this.enabled,
    required this.day,
    required this.lang,
    required this.onPdf,
  });

  final StatementSummary s;
  final bool busy;
  final bool enabled;
  final DateFormat day;
  final String lang;
  final ValueChanged<bool> onPdf;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final paid = s.status == 'paid';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Wrap(
        spacing: 20,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 280, maxWidth: 520),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.receipt_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${s.number}'
                        '${s.restaurantName.isEmpty ? '' : '  ·  ${s.restaurantName}'}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        '${day.format(s.periodStart)} – ${day.format(s.periodEnd)}'
                        '  ·  ${l.ordersCount(s.ordersCount)}',
                        style: TextStyle(fontSize: 13, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                formatDzd(s.amountDue, lang),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(width: 12),
              Pill(
                paid ? l.statusPaid : l.statusUnpaid,
                color: paid ? AppColors.success : AppColors.primary,
              ),
              const SizedBox(width: 12),
              AppButton(
                label: l.downloadPdf,
                icon: Icons.download_rounded,
                variant: AppButtonVariant.small,
                loading: busy,
                onPressed: enabled ? () => onPdf(false) : null,
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: l.printPdf,
                onPressed: enabled ? () => onPdf(true) : null,
                icon: Icon(Icons.print_outlined, color: AppColors.inkSoft),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
