import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/pdf/pdf_output.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/snack.dart';
import '../../../l10n/app_localizations.dart';
import '../../catalog/widgets/browse_widgets.dart';
import '../data/admin_models.dart';
import '../data/admin_repository.dart';
import '../data/periods.dart';
import '../statement_pdf.dart';
import '../widgets/admin_widgets.dart';

export '../../../core/pdf/pdf_output.dart';

/// Pick a restaurant + period, preview the commission, generate.
class AdminNewReceiptPage extends ConsumerStatefulWidget {
  const AdminNewReceiptPage({super.key, this.restaurantId});
  final String? restaurantId;

  @override
  ConsumerState<AdminNewReceiptPage> createState() =>
      _AdminNewReceiptPageState();
}

class _AdminNewReceiptPageState extends ConsumerState<AdminNewReceiptPage> {
  late String? _restaurantId = widget.restaurantId;
  late DateRange _range = statementRange(
    StatementPeriod.previousHalfMonth,
    DateTime.now(),
  );
  Future<StatementPreview>? _preview;
  bool _generating = false;

  void _refreshPreview() {
    final rid = _restaurantId;
    setState(() {
      _preview = rid == null
          ? null
          : ref.read(adminRepositoryProvider).previewStatement(rid, _range);
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshPreview());
  }

  Future<void> _generate() async {
    final l = AppLocalizations.of(context);
    setState(() => _generating = true);
    try {
      final id = await ref
          .read(adminRepositoryProvider)
          .generateStatement(_restaurantId!, _range);
      ref.invalidate(adminStatementsProvider);
      ref.invalidate(adminRestaurantsProvider);
      if (mounted) context.pushReplacement('/admin/receipts/$id');
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      showAppSnack(
        context,
        msg.contains('no orders to bill')
            ? l.noOrdersToBill
            : msg.contains('period not finished')
            ? l.periodNotFinished
            : l.errGeneric,
        error: true,
      );
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final restaurants = ref.watch(adminRestaurantsProvider).value ?? const [];
    final now = DateTime.now();
    final fmt = DateFormat('dd/MM/yyyy');
    final presets = {
      StatementPeriod.previousHalfMonth: l.previousHalfMonth,
      StatementPeriod.lastMonth: l.periodLastMonth,
    };
    final today = DateTime(now.year, now.month, now.day);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              children: [
                PageHeader(title: l.newReceipt),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l.restaurantFilter.toUpperCase(),
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 8),
                      AdminCard(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: DropdownButton<String>(
                          isExpanded: true,
                          underline: const SizedBox.shrink(),
                          value: _restaurantId,
                          hint: Text(l.restaurantFilter),
                          items: [
                            for (final r in restaurants)
                              DropdownMenuItem(
                                value: r.id,
                                child: Text(
                                  r.unbilledCommission > 0
                                      ? '${r.name} · ${l.toBill(formatDzd(r.unbilledCommission, lang))}'
                                      : r.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged: (v) {
                            _restaurantId = v;
                            _refreshPreview();
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        l.receiptPeriod.toUpperCase(),
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final e in presets.entries)
                            ChoiceChip(
                              label: Text(e.value),
                              selected: statementRange(e.key, now) == _range,
                              selectedColor: AppColors.accent,
                              labelStyle: TextStyle(
                                color: statementRange(e.key, now) == _range
                                    ? Colors.white
                                    : AppColors.ink,
                              ),
                              onSelected: (_) {
                                _range = statementRange(e.key, now);
                                _refreshPreview();
                              },
                            ),
                          ActionChip(
                            avatar: const Icon(
                              Icons.date_range_rounded,
                              size: 18,
                            ),
                            label: Text(
                              '${fmt.format(_range.start)} – ${fmt.format(_range.end)}',
                            ),
                            onPressed: () async {
                              final picked = await showDateRangePicker(
                                context: context,
                                firstDate: DateTime(2025),
                                // Only finished days can be billed.
                                lastDate: today.subtract(
                                  const Duration(days: 1),
                                ),
                                initialDateRange: DateTimeRange(
                                  start: _range.start,
                                  end: _range.end,
                                ),
                              );
                              if (picked != null) {
                                _range = DateRange(picked.start, picked.end);
                                _refreshPreview();
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (_preview != null)
                        FutureBuilder<StatementPreview>(
                          future: _preview,
                          builder: (context, snap) {
                            if (snap.connectionState != ConnectionState.done) {
                              return const Padding(
                                padding: EdgeInsets.all(24),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.primary,
                                  ),
                                ),
                              );
                            }
                            if (snap.hasError) {
                              return AsyncBody<void>(
                                value: AsyncError(
                                  snap.error!,
                                  StackTrace.empty,
                                ),
                                builder: (_) => const SizedBox.shrink(),
                                onRetry: _refreshPreview,
                              );
                            }
                            final p = snap.data!;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                AdminCard(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l.receiptPreview(
                                          p.ordersCount,
                                          formatDzd(p.foodTotal, lang),
                                        ),
                                        style: const TextStyle(
                                          color: AppColors.body,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        l.commissionDue,
                                        style: const TextStyle(
                                          color: AppColors.muted,
                                        ),
                                      ),
                                      Text(
                                        formatDzd(p.commissionTotal, lang),
                                        style: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.ink,
                                        ),
                                      ),
                                      if (p.ordersCount == 0) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          l.noOrdersToBill,
                                          style: const TextStyle(
                                            color: AppColors.danger,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),
                                AppButton(
                                  label: l.generateReceipt,
                                  loading: _generating,
                                  onPressed: p.ordersCount == 0
                                      ? null
                                      : _generate,
                                ),
                              ],
                            );
                          },
                        ),
                      const SizedBox(height: 32),
                    ],
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

/// One receipt: summary, orders, Download PDF / Print / Mark paid / Cancel.
class AdminReceiptPage extends ConsumerStatefulWidget {
  const AdminReceiptPage({super.key, required this.id});
  final String id;

  @override
  ConsumerState<AdminReceiptPage> createState() => _AdminReceiptPageState();
}

class _AdminReceiptPageState extends ConsumerState<AdminReceiptPage> {
  String? _busy; // 'pdf' | 'print' | 'paid' | 'cancel'

  Future<Uint8List> _pdf(StatementDetail d) async {
    final lang = Localizations.localeOf(context).languageCode;
    return buildStatementPdf(d, lang: lang, fonts: await PdfFonts.fromAssets());
  }

  Future<void> _do(String what, Future<void> Function() action) async {
    final l = AppLocalizations.of(context);
    setState(() => _busy = what);
    try {
      await action();
    } catch (_) {
      if (mounted) showAppSnack(context, l.errGeneric, error: true);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _cancel() async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(l.cancelReceiptConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l.cancelReceipt,
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _do('cancel', () async {
      await ref.read(adminRepositoryProvider).cancelStatement(widget.id);
      ref.invalidate(adminStatementsProvider);
      ref.invalidate(adminRestaurantsProvider);
      if (mounted) {
        context.canPop() ? context.pop() : context.go('/admin/receipts');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final detail = ref.watch(adminStatementDetailProvider(widget.id));
    final fmt = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: AsyncBody(
              value: detail,
              onRetry: () =>
                  ref.invalidate(adminStatementDetailProvider(widget.id)),
              builder: (d) {
                final s = d.statement;
                return ListView(
                  children: [
                    PageHeader(title: s.number),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AdminCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        d.restaurantName,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    Pill(
                                      s.isPaid ? l.statusPaid : l.statusUnpaid,
                                      color: s.isPaid
                                          ? AppColors.success
                                          : AppColors.primary,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${fmt.format(s.periodStart)} – ${fmt.format(s.periodEnd)} · ${l.issuedOn(fmt.format(s.issuedAt.toLocal()))}',
                                  style: const TextStyle(color: AppColors.body),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  l.receiptPreview(
                                    s.ordersCount,
                                    formatDzd(s.foodTotal, lang),
                                  ),
                                  style: const TextStyle(color: AppColors.body),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  l.commissionDue,
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                  ),
                                ),
                                Text(
                                  formatDzd(s.commissionTotal, lang),
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              AppButton(
                                label: l.downloadPdf,
                                variant: AppButtonVariant.small,
                                icon: Icons.download_rounded,
                                loading: _busy == 'pdf',
                                onPressed: () => _do('pdf', () async {
                                  final bytes = await _pdf(d);
                                  await ref
                                      .read(pdfOutputProvider)
                                      .download(bytes, '${s.number}.pdf');
                                }),
                              ),
                              AppButton(
                                label: l.printPdf,
                                variant: AppButtonVariant.outline,
                                icon: Icons.print_outlined,
                                loading: _busy == 'print',
                                onPressed: () => _do('print', () async {
                                  final bytes = await _pdf(d);
                                  await ref
                                      .read(pdfOutputProvider)
                                      .print(bytes, s.number);
                                }),
                              ),
                              AppButton(
                                label: s.isPaid ? l.markUnpaid : l.markPaid,
                                variant: AppButtonVariant.outline,
                                icon: s.isPaid
                                    ? Icons.undo_rounded
                                    : Icons.check_rounded,
                                loading: _busy == 'paid',
                                onPressed: () => _do('paid', () async {
                                  await ref
                                      .read(adminRepositoryProvider)
                                      .setStatementPaid(s.id, !s.isPaid);
                                  ref.invalidate(
                                    adminStatementDetailProvider(widget.id),
                                  );
                                  ref.invalidate(adminStatementsProvider);
                                }),
                              ),
                              if (!s.isPaid)
                                AppButton(
                                  label: l.cancelReceipt,
                                  variant: AppButtonVariant.dangerOutline,
                                  loading: _busy == 'cancel',
                                  onPressed: _cancel,
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          AdminCard(
                            padding: EdgeInsets.zero,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                columns: [
                                  DataColumn(label: Text(l.orders)),
                                  DataColumn(label: Text(l.statusDelivered)),
                                  DataColumn(
                                    label: Text(l.statSales),
                                    numeric: true,
                                  ),
                                  DataColumn(
                                    label: Text(l.commissionRate),
                                    numeric: true,
                                  ),
                                  DataColumn(
                                    label: Text(l.statCommission),
                                    numeric: true,
                                  ),
                                ],
                                rows: [
                                  for (final o in d.lines)
                                    DataRow(
                                      cells: [
                                        DataCell(Text(o.code)),
                                        DataCell(
                                          Text(
                                            fmt.format(o.deliveredAt.toLocal()),
                                          ),
                                        ),
                                        DataCell(
                                          Text(formatDzd(o.foodTotal, lang)),
                                        ),
                                        DataCell(
                                          Text(percent(o.commissionRate)),
                                        ),
                                        DataCell(
                                          Text(
                                            formatDzd(o.commissionAmount, lang),
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
