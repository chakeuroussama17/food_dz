import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../core/files/file_output.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/snack.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../orders/order_status.dart';
import '../data/owner_orders_repository.dart';
import '../insights/orders_csv.dart';
import '../owner_receipt.dart';
import '../widgets/period_chips.dart';

/// Status filter of the table.
enum StatusFilter { all, inProgress, delivered, rejected, cancelled }

bool _matches(StatusFilter f, String status) => switch (f) {
  StatusFilter.all => true,
  StatusFilter.inProgress => activeOrderStatuses.contains(status),
  StatusFilter.delivered => status == 'delivered',
  StatusFilter.rejected => status == 'rejected',
  StatusFilter.cancelled => status == 'cancelled',
};

/// Every order of a period in a sortable table: period, status and text
/// filters, totals of the selection, row details and CSV export.
class OwnerOrdersTablePage extends ConsumerStatefulWidget {
  const OwnerOrdersTablePage({super.key});

  @override
  ConsumerState<OwnerOrdersTablePage> createState() =>
      _OwnerOrdersTablePageState();
}

class _OwnerOrdersTablePageState extends ConsumerState<OwnerOrdersTablePage> {
  Period _period = Period.d7;
  DateTimeRange? _custom;
  StatusFilter _status = StatusFilter.all;
  String _query = '';
  int _sortColumn = 1; // date
  bool _ascending = false;
  int _shown = 50;
  bool _exporting = false;

  ReportRange get _range => _period.range(DateTime.now(), custom: _custom);

  Future<void> _pickPeriod(Period p) async {
    if (p != Period.custom) {
      setState(() {
        _period = p;
        _shown = 50;
      });
      return;
    }
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1, now.month, now.day),
      lastDate: now,
      initialDateRange: _custom,
    );
    if (picked == null) return;
    setState(() {
      _custom = picked;
      _period = Period.custom;
      _shown = 50;
    });
  }

  List<OwnerOrder> _filter(List<OwnerOrder> all) {
    final q = _query.trim().toLowerCase();
    final list = all.where((o) {
      if (!_matches(_status, o.status)) return false;
      if (q.isEmpty) return true;
      return o.code.toLowerCase().contains(q) ||
          o.customerName.toLowerCase().contains(q) ||
          o.area.toLowerCase().contains(q) ||
          o.items.any((i) => i.name.toLowerCase().contains(q));
    }).toList();
    int net(OwnerOrder o) => o.status == 'delivered' ? o.net : 0;
    Comparable key(OwnerOrder o) => switch (_sortColumn) {
      0 => o.code,
      2 => o.status,
      3 => o.customerName.toLowerCase(),
      4 => o.items.fold<int>(0, (s, i) => s + i.quantity),
      5 => o.foodTotal,
      6 => net(o),
      _ => o.placedAt,
    };
    list.sort((a, b) {
      final c = key(a).compareTo(key(b));
      return _ascending ? c : -c;
    });
    return list;
  }

  Future<void> _export(List<OwnerOrder> rows) async {
    final l = AppLocalizations.of(context);
    setState(() => _exporting = true);
    try {
      final r = _range;
      final day = DateFormat('yyyy-MM-dd');
      final last = r.to.subtract(const Duration(days: 1));
      final name = r.from == last || day.format(r.from) == day.format(last)
          ? 'orders_${day.format(r.from)}.csv'
          : 'orders_${day.format(r.from)}_${day.format(last)}.csv';
      await ref
          .read(fileOutputProvider)
          .save(csvBytes(ordersCsv(rows, l)), name, 'text/csv');
      if (mounted) showAppSnack(context, l.csvReady);
    } catch (_) {
      if (mounted) showAppSnack(context, l.errGeneric, error: true);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final data = ref.watch(ownerReportProvider(_range));
    final rows = data.whenData(_filter);
    final list = rows.value;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PageHeader(
                  title: l.ordersTable,
                  trailing: _ExportButton(
                    busy: _exporting,
                    onPressed: list == null || list.isEmpty || _exporting
                        ? null
                        : () => _export(list),
                  ),
                ),
                PeriodChips(
                  periods: const [
                    Period.today,
                    Period.yesterday,
                    Period.d7,
                    Period.d30,
                    Period.month,
                    Period.custom,
                  ],
                  selected: _period,
                  custom: _custom,
                  onSelected: _pickPeriod,
                ),
                const SizedBox(height: 10),
                SmallChips<StatusFilter>(
                  items: StatusFilter.values,
                  selected: _status,
                  labelOf: (f) => switch (f) {
                    StatusFilter.all => l.filterAll,
                    StatusFilter.inProgress => l.filterInProgress,
                    StatusFilter.delivered => l.statusDelivered,
                    StatusFilter.rejected => orderStatusLabel(l, 'rejected'),
                    StatusFilter.cancelled => orderStatusLabel(l, 'cancelled'),
                  },
                  onSelected: (f) => setState(() {
                    _status = f;
                    _shown = 50;
                  }),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    onChanged: (v) => setState(() {
                      _query = v;
                      _shown = 50;
                    }),
                    decoration: InputDecoration(
                      hintText: l.searchOrdersHint,
                      prefixIcon: const Icon(Icons.search_rounded),
                      isDense: true,
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: rows.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                    error: (_, _) => Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l.loadError,
                            style: TextStyle(color: AppColors.body),
                          ),
                          TextButton(
                            onPressed: () =>
                                ref.invalidate(ownerReportProvider(_range)),
                            child: Text(l.retry),
                          ),
                        ],
                      ),
                    ),
                    data: (list) => list.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.table_chart_outlined,
                                  size: 52,
                                  color: AppColors.muted,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  l.noOrdersPeriod,
                                  style: TextStyle(color: AppColors.body),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            color: AppColors.primary,
                            onRefresh: () =>
                                ref.refresh(ownerReportProvider(_range).future),
                            child: ListView(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                              children: [
                                _Totals(rows: list),
                                const SizedBox(height: 12),
                                _Table(
                                  rows: list.take(_shown).toList(),
                                  lang: lang,
                                  sortColumn: _sortColumn,
                                  ascending: _ascending,
                                  onSort: (c, asc) => setState(() {
                                    _sortColumn = c;
                                    _ascending = asc;
                                  }),
                                  onTap: (o) => showOrderDetails(context, o),
                                ),
                                if (list.length > _shown)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: Center(
                                      child: AppButton(
                                        label:
                                            '${l.seeAll} (${list.length - _shown})',
                                        variant: AppButtonVariant.outline,
                                        onPressed: () =>
                                            setState(() => _shown += 100),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
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

class _ExportButton extends StatelessWidget {
  const _ExportButton({required this.busy, required this.onPressed});
  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Tooltip(
      message: l.exportCsv,
      child: FilledButton.icon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          visualDensity: VisualDensity.compact,
        ),
        icon: busy
            ? const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.download_rounded, size: 18),
        label: const Text('CSV'),
      ),
    );
  }
}

/// Count, sales, commission and net of the filtered rows.
class _Totals extends StatelessWidget {
  const _Totals({required this.rows});
  final List<OwnerOrder> rows;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final delivered = rows.where((o) => o.status == 'delivered');
    final sales = delivered.fold<int>(0, (s, o) => s + o.foodTotal);
    final commission = delivered.fold<int>(
      0,
      (s, o) => s + (o.commissionAmount ?? 0),
    );
    Widget cell(String label, String value, {Color? color}) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color ?? AppColors.ink,
              ),
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: AppColors.muted),
          ),
        ],
      ),
    );
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          cell(l.kpiOrders, '${rows.length}'),
          cell(l.kpiSales, formatDzd(sales, lang)),
          cell(l.csvCommission, formatDzd(commission, lang)),
          cell(
            l.kpiNet,
            formatDzd(sales - commission, lang),
            color: AppColors.success,
          ),
        ],
      ),
    );
  }
}

class _Table extends StatelessWidget {
  const _Table({
    required this.rows,
    required this.lang,
    required this.sortColumn,
    required this.ascending,
    required this.onSort,
    required this.onTap,
  });

  final List<OwnerOrder> rows;
  final String lang;
  final int sortColumn;
  final bool ascending;
  final void Function(int column, bool ascending) onSort;
  final ValueChanged<OwnerOrder> onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final when = DateFormat('dd/MM HH:mm');
    final head = TextStyle(
      fontSize: 12.5,
      fontWeight: FontWeight.w800,
      color: AppColors.body,
    );
    final cell = TextStyle(fontSize: 13.5, color: AppColors.ink);
    DataColumn col(String label, {bool numeric = false}) => DataColumn(
      numeric: numeric,
      label: Text(label, style: head),
      onSort: onSort,
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          sortColumnIndex: sortColumn,
          sortAscending: ascending,
          showCheckboxColumn: false,
          headingRowHeight: 44,
          dataRowMinHeight: 46,
          dataRowMaxHeight: 52,
          columnSpacing: 22,
          horizontalMargin: 14,
          headingRowColor: WidgetStatePropertyAll(AppColors.field),
          dividerThickness: .6,
          columns: [
            col(l.csvCode),
            col(l.csvDate),
            col(l.csvStatus),
            col(l.csvCustomer),
            col(l.csvItemCount, numeric: true),
            col(l.csvFood, numeric: true),
            col(l.csvNet, numeric: true),
          ],
          rows: [
            for (final o in rows)
              DataRow(
                onSelectChanged: (_) => onTap(o),
                cells: [
                  DataCell(
                    Text(
                      '#${o.code}',
                      style: cell.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  DataCell(
                    Text(
                      when.format(o.placedAt),
                      textDirection: TextDirection.ltr,
                      style: cell,
                    ),
                  ),
                  DataCell(StatusDot(status: o.status)),
                  DataCell(
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 140),
                      child: Text(
                        o.customerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: cell,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      '${o.items.fold<int>(0, (s, i) => s + i.quantity)}',
                      style: cell,
                    ),
                  ),
                  DataCell(Text(formatDzd(o.foodTotal, lang), style: cell)),
                  DataCell(
                    Text(
                      o.status == 'delivered' ? formatDzd(o.net, lang) : '—',
                      style: cell.copyWith(
                        fontWeight: FontWeight.w700,
                        color: o.status == 'delivered'
                            ? AppColors.success
                            : AppColors.muted,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Coloured dot + status name.
class StatusDot extends StatelessWidget {
  const StatusDot({super.key, required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final color = orderStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: AppColors.isDark ? .22 : .12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        orderStatusLabel(l, status),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

/// Bottom sheet with everything about one order of the table.
Future<void> showOrderDetails(BuildContext context, OwnerOrder o) {
  final l = AppLocalizations.of(context);
  final lang = Localizations.localeOf(context).languageCode;
  final when = DateFormat('dd/MM/yyyy HH:mm');
  final time = DateFormat('HH:mm');
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      Widget line(String a, String b, {bool bold = false, Color? color}) =>
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(a, style: TextStyle(color: AppColors.body)),
                ),
                Text(
                  b,
                  style: TextStyle(
                    fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                    color: color ?? AppColors.ink,
                  ),
                ),
              ],
            ),
          );
      final steps = [
        (orderStatusLabel(l, 'placed'), o.placedAt),
        (orderStatusLabel(l, 'accepted'), o.acceptedAt),
        (orderStatusLabel(l, 'ready'), o.readyAt),
        (orderStatusLabel(l, 'picked_up'), o.pickedUpAt),
        (orderStatusLabel(l, 'delivered'), o.deliveredAt),
        (orderStatusLabel(l, o.status), o.cancelledAt),
      ].where((s) => s.$2 != null);
      final delivered = o.status == 'delivered';
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(ctx).height * .85,
          ),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '#${o.code}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  StatusDot(status: o.status),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${when.format(o.placedAt)} · ${o.customerName}'
                '${o.area.isEmpty ? '' : ' · ${o.area}'}',
                style: TextStyle(color: AppColors.body),
              ),
              Divider(height: 28, color: AppColors.border),
              for (final i in o.items)
                line('${i.quantity}× ${i.name}', formatDzd(i.lineTotal, lang)),
              Divider(height: 24, color: AppColors.border),
              line(l.csvFood, formatDzd(o.foodTotal, lang)),
              line(l.csvDeliveryFee, formatDzd(o.deliveryFee, lang)),
              if (delivered) ...[
                line(
                  l.csvCommission,
                  '- ${formatDzd(o.commissionAmount ?? 0, lang)}',
                  color: AppColors.danger,
                ),
                line(
                  l.kpiNet,
                  formatDzd(o.net, lang),
                  bold: true,
                  color: AppColors.success,
                ),
              ],
              if (o.rejectReason != null)
                line(l.csvReason, rejectReasonText(l, o.rejectReason!)),
              if ((o.driverName ?? '').isNotEmpty)
                line(l.csvDriver, o.driverName!),
              Divider(height: 24, color: AppColors.border),
              for (final (label, at) in steps) line(label, time.format(at!)),
              if (delivered) ...[
                const SizedBox(height: 16),
                OwnerReceiptButtons(order: o),
              ],
            ],
          ),
        ),
      );
    },
  );
}
