import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../core/pdf/business_info.dart';
import '../../../core/pdf/pdf_output.dart';
import '../../../core/pdf/receipt_pdf.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/snack.dart';
import '../driver_statement.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../orders/order_status.dart';
import '../data/driver_repository.dart';
import '../widgets/driver_widgets.dart';

/// My deliveries: finished orders, newest first.
class DriverDeliveriesPage extends ConsumerWidget {
  const DriverDeliveriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final list = ref.watch(driverHistoryProvider);
    final when = DateFormat('dd/MM HH:mm');
    return DriverScaffold(
      tab: DriverTab.deliveries,
      body: Column(
        children: [
          PageHeader(
            title: l.myDeliveries,
            showBack: false,
            trailing: const _StatementButton(),
          ),
          Expanded(
            child: list.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (_, _) => Center(
                child: TextButton(
                  onPressed: () => ref.invalidate(driverHistoryProvider),
                  child: Text(l.retry),
                ),
              ),
              data: (orders) => orders.isEmpty
                  ? Center(
                      child: Text(
                        l.noDeliveries,
                        style: TextStyle(color: AppColors.body),
                      ),
                    )
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () =>
                          ref.refresh(driverHistoryProvider.future),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        itemCount: orders.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final o = orders[i];
                          return DriverCard(
                            onTap: () => context.push('/driver/orders/${o.id}'),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '#${o.code} · ${o.restaurantName}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.ink,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        [
                                          when.format(
                                            o.deliveredAt ?? o.placedAt,
                                          ),
                                          if (o.area.isNotEmpty) o.area,
                                        ].join(' · '),
                                        style: TextStyle(color: AppColors.body),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Pill(
                                      orderStatusLabel(l, o.status),
                                      color: orderStatusColor(o.status),
                                    ),
                                    const SizedBox(height: 6),
                                    if (o.status == 'delivered')
                                      Text(
                                        '+${formatDzd(o.deliveryFee, lang)}',
                                        style: const TextStyle(
                                          color: AppColors.success,
                                          fontWeight: FontWeight.w700,
                                        ),
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
          ),
        ],
      ),
    );
  }
}

/// "Download statement": pick a period, build the PDF, download it.
class _StatementButton extends ConsumerStatefulWidget {
  const _StatementButton();

  @override
  ConsumerState<_StatementButton> createState() => _StatementButtonState();
}

class _StatementButtonState extends ConsumerState<_StatementButton> {
  bool _busy = false;

  Future<void> _pick() async {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final period = await showModalBottomSheet<DriverPeriod>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                l.downloadStatement,
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
            ),
            for (final (p, label) in [
              (DriverPeriod.thisWeek, l.periodThisWeek),
              (DriverPeriod.lastWeek, l.periodLastWeek),
              (DriverPeriod.thisMonth, l.periodThisMonth),
              (DriverPeriod.lastMonth, l.periodLastMonth),
            ])
              ListTile(
                leading: const Icon(Icons.date_range_rounded),
                title: Text(label),
                onTap: () => Navigator.pop(ctx, p),
              ),
          ],
        ),
      ),
    );
    if (period == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final (from, to) = driverPeriodRange(period, DateTime.now());
      final rows = await ref.read(driverRepositoryProvider).statement(from, to);
      if (rows.isEmpty) {
        if (mounted) showAppSnack(context, l.noDeliveriesInPeriod);
        return;
      }
      final me = ref.read(myDriverProvider).value;
      final bytes = await buildDriverStatement(
        deliveries: rows,
        from: from,
        to: to,
        driverName: me?.fullName ?? '',
        driverPhone: me?.phone ?? '',
        business: await ref.read(businessInfoRepositoryProvider).get(),
        l: l,
        lang: lang,
        fonts: await PdfFonts.fromAssets(),
      );
      String d(DateTime x) =>
          '${x.year}${x.month.toString().padLeft(2, '0')}${x.day.toString().padLeft(2, '0')}';
      await ref
          .read(pdfOutputProvider)
          .download(bytes, 'releve-livreur-${d(from)}-${d(to)}.pdf');
    } catch (_) {
      if (mounted) showAppSnack(context, l.errGeneric, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return _busy
        ? const SizedBox.square(
            dimension: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: AppColors.primary,
            ),
          )
        : IconButton(
            tooltip: l.downloadStatement,
            onPressed: _pick,
            icon: const Icon(
              Icons.picture_as_pdf_outlined,
              color: AppColors.primary,
            ),
          );
  }
}
